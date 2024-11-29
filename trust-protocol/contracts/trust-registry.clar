;; Community Trust Score System
;; Tracks and manages reputation for community members based on verified contributions

(define-constant ERR-UNAUTHORIZED u100)
(define-constant ERR-INVALID-ACTION u101)
(define-constant ERR-INSUFFICIENT-STAKE u102)
(define-constant ERR-COOLING-PERIOD u103)
(define-constant ERR-ALREADY-VERIFIED u104)

;; Data Variables
(define-data-var minimum-stake uint u100) ;; Minimum STX required for staking
(define-data-var cooling-period uint u86400) ;; 24 hours in seconds
(define-data-var admin principal tx-sender)

;; Maps
(define-map user-scores
    { user: principal }
    { 
        total-score: uint,
        active-score: uint,
        last-action: uint,
        total-actions: uint,
        staked-amount: uint
    }
)

(define-map action-types
    { action-id: uint }
    {
        name: (string-utf8 50),
        base-points: uint,
        requires-validation: bool,
        min-stake: uint,
        cooldown: uint
    }
)

(define-map pending-actions
    { action-id: uint, user: principal }
    {
        timestamp: uint,
        proof: (optional (buff 64)),
        validators: (list 10 principal),
        is-validated: bool
    }
)

(define-map validators
    principal 
    {
        is-active: bool,
        total-validations: uint
    }
)

;; Private Functions
(define-private (calculate-time-decay (last-action uint))
    (let (
        (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
        (time-diff (- current-time last-action))
    )
    (if (< time-diff u604800) ;; 1 week
        u100
        (- u100 (/ time-diff u604800)))
))

(define-private (update-score (user principal) (points uint))
    (let (
        (user-data (unwrap-panic (map-get? user-scores {user: user})))
        (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
        (decayed-score (* (get active-score user-data) (calculate-time-decay (get last-action user-data))))
        (new-score (+ decayed-score points))
    )
    (map-set user-scores
        {user: user}
        {
            total-score: (+ (get total-score user-data) points),
            active-score: new-score,
            last-action: current-time,
            total-actions: (+ (get total-actions user-data) u1),
            staked-amount: (get staked-amount user-data)
        }
    )
    (ok new-score)
))

;; Public Functions
(define-public (register-user)
    (let ((sender tx-sender))
        (asserts! (is-none (map-get? user-scores {user: sender})) (err ERR-ALREADY-VERIFIED))
        (ok (map-set user-scores
            {user: sender}
            {
                total-score: u0,
                active-score: u0,
                last-action: (unwrap-panic (get-block-info? time (- block-height u1))),
                total-actions: u0,
                staked-amount: u0
            }
        ))
    )
)

(define-public (submit-action (action-id uint) (proof (optional (buff 64))))
    (let (
        (sender tx-sender)
        (action (unwrap-panic (map-get? action-types {action-id: action-id})))
        (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
        (user-data (unwrap-panic (map-get? user-scores {user: sender})))
    )
        (asserts! (>= (get staked-amount user-data) (get min-stake action)) (err ERR-INSUFFICIENT-STAKE))
        (asserts! (>= (- current-time (get last-action user-data)) (get cooldown action)) (err ERR-COOLING-PERIOD))
        
        (if (get requires-validation action)
            (begin 
                (map-set pending-actions
                    {action-id: action-id, user: sender}
                    {
                        timestamp: current-time,
                        proof: proof,
                        validators: (list),
                        is-validated: false
                    }
                )
                (ok u0) ;; Return 0 points for pending validation
            )
            (update-score sender (get base-points action))
        )
    )
)

(define-public (stake-tokens (amount uint))
    (let (
        (sender tx-sender)
        (user-data (unwrap-panic (map-get? user-scores {user: sender})))
    )
        (try! (stx-transfer? amount sender (as-contract tx-sender)))
        (ok (map-set user-scores
            {user: sender}
            {
                total-score: (get total-score user-data),
                active-score: (get active-score user-data),
                last-action: (get last-action user-data),
                total-actions: (get total-actions user-data),
                staked-amount: (+ (get staked-amount user-data) amount)
            }
        ))
    )
)

(define-public (validate-action (action-id uint) (user principal))
    (let (
        (sender tx-sender)
        (pending-action (unwrap-panic (map-get? pending-actions {action-id: action-id, user: user})))
        (action (unwrap-panic (map-get? action-types {action-id: action-id})))
        (validator-data (unwrap-panic (map-get? validators sender)))
        (updated-validators (unwrap-panic (as-max-len? (append (get validators pending-action) sender) u10)))
    )
        (asserts! (get is-active validator-data) (err ERR-UNAUTHORIZED))
        (asserts! (not (get is-validated pending-action)) (err ERR-ALREADY-VERIFIED))
        
        (if (>= (len (get validators pending-action)) u3)
            (begin
                (unwrap-panic (update-score user (get base-points action)))
                (ok (map-set pending-actions
                    {action-id: action-id, user: user}
                    {
                        timestamp: (get timestamp pending-action),
                        proof: (get proof pending-action),
                        validators: updated-validators,
                        is-validated: true
                    }
                ))
            )
            (ok (map-set pending-actions
                {action-id: action-id, user: user}
                {
                    timestamp: (get timestamp pending-action),
                    proof: (get proof pending-action),
                    validators: updated-validators,
                    is-validated: false
                }
            ))
        )
    )
)

;; Read-only Functions
(define-read-only (get-user-score (user principal))
    (map-get? user-scores {user: user})
)

(define-read-only (get-action-details (action-id uint))
    (map-get? action-types {action-id: action-id})
)

(define-read-only (get-pending-action (action-id uint) (user principal))
    (map-get? pending-actions {action-id: action-id, user: user})
)

;; Admin Functions
(define-public (add-action-type (action-id uint) (name (string-utf8 50)) (base-points uint) (requires-validation bool) (min-stake uint) (cooldown uint))
    (let ((sender tx-sender))
        (asserts! (is-eq sender (var-get admin)) (err ERR-UNAUTHORIZED))
        (ok (map-set action-types
            {action-id: action-id}
            {
                name: name,
                base-points: base-points,
                requires-validation: requires-validation,
                min-stake: min-stake,
                cooldown: cooldown
            }
        ))
    )
)

(define-public (set-validator (validator principal) (is-active bool))
    (let ((sender tx-sender))
        (asserts! (is-eq sender (var-get admin)) (err ERR-UNAUTHORIZED))
        (ok (map-set validators
            validator
            {
                is-active: is-active,
                total-validations: (default-to u0 (get total-validations (map-get? validators validator)))
            }
        ))
    )
)