# Community Trust Score System - README

The **Community Trust Score System** is a decentralized reputation management platform built on the Clarity language. It tracks and manages the reputation of community members based on their verified contributions. This system allows users to perform actions, stake tokens, and earn scores that reflect their trustworthiness and participation within the community. Additionally, it introduces the concept of action validation by other community members, ensuring that only meaningful contributions are rewarded.

## Features

- **User Registration**: Users can register on the platform, ensuring they are tracked for their contributions.
- **Staking System**: Users can stake tokens to engage with the system. A minimum stake is required for submitting actions and earning reputation.
- **Action Submission**: Users can submit actions, which can either be automatically scored or pending validation by other users.
- **Action Validation**: Some actions require validation by other users before they contribute to a user's score.
- **Reputation Scoring**: Users earn reputation points based on the actions they submit. These points decay over time, promoting ongoing activity.
- **Cooling Period**: Users must wait a specific time period between submitting actions to prevent abuse.
- **Validator System**: Users can be designated as validators who help verify actions submitted by others.
- **Admin Control**: The admin can add new action types and manage validators.

---

## Contract Components

### Constants

- **ERR-UNAUTHORIZED**: Error code for unauthorized actions.
- **ERR-INVALID-ACTION**: Error code for invalid actions.
- **ERR-INSUFFICIENT-STAKE**: Error code for insufficient stake during action submission.
- **ERR-COOLING-PERIOD**: Error code for trying to submit an action before the cooling period expires.
- **ERR-ALREADY-VERIFIED**: Error code for already verified users.

### Data Variables

- **minimum-stake**: Minimum stake (in STX) required for users to participate in actions.
- **cooling-period**: Duration (in seconds) that users must wait before submitting another action.
- **admin**: The principal address of the contract admin.

### Maps

- **user-scores**: Stores user information such as total score, active score, last action timestamp, total actions, and staked amount.
- **action-types**: Stores the details of different actions that users can perform, including points, validation requirements, and cooldown times.
- **pending-actions**: Stores actions submitted by users that are pending validation, including associated proof and validator data.
- **validators**: Stores information about validators, including whether they are active and their total number of validations.

---

## Functions

### Private Functions

- **calculate-time-decay**: Calculates the decay in a user's score based on the time passed since their last action. Scores decay after 1 week.
- **update-score**: Updates a user's score based on submitted actions and decays the active score over time.

### Public Functions

- **register-user**: Allows a user to register on the platform, initializing their scores and staking data.
- **submit-action**: Allows a user to submit an action, either automatically adding points to their score or submitting it for validation.
- **stake-tokens**: Allows a user to stake tokens, increasing their staked amount and enabling further interactions.
- **validate-action**: Allows a validator to verify a pending action. If enough validators approve the action, it contributes points to the user's score.

### Read-only Functions

- **get-user-score**: Retrieves the current score information for a given user.
- **get-action-details**: Retrieves the details of a specific action by ID.
- **get-pending-action**: Retrieves the details of a pending action submitted by a user.

### Admin Functions

- **add-action-type**: Allows the admin to define new types of actions, including points, staking requirements, and cooldown times.
- **set-validator**: Allows the admin to activate or deactivate validators in the system.

---

## Example Usage

### Registering a User

To register a user on the platform, call the `register-user` function:

```clarity
(register-user)
```

### Staking Tokens

To stake tokens, the user must call the `stake-tokens` function, specifying the amount of STX they wish to stake:

```clarity
(stake-tokens 100)
```

### Submitting an Action

To submit an action, the user calls the `submit-action` function with the `action-id` of the action type and any optional proof (if the action requires validation):

```clarity
(submit-action 1 (optional-proof))
```

### Validating an Action

If the user is a validator, they can validate an action submitted by another user:

```clarity
(validate-action 1 sender-address)
```

### Adding a New Action Type (Admin Only)

The admin can add a new action type with specific properties (name, points, validation requirement, etc.):

```clarity
(add-action-type 3 "Contribute to Documentation" 10 true 50 3600)
```

---

## Security Considerations

- **Stake Requirement**: Users must stake a minimum amount of tokens to participate in the system, ensuring they have a financial commitment to the platform.
- **Action Validation**: The requirement for actions to be validated by multiple validators ensures that only meaningful contributions are rewarded.
- **Cooling Period**: A cooling period between actions prevents abuse by limiting the number of actions a user can submit within a short time.

---

The **Community Trust Score System** provides a decentralized and transparent way of tracking and validating user contributions in a community. It promotes meaningful participation, incentivizes honest actions, and enhances the overall quality of the community through a well-defined reputation mechanism. The use of staking, validation, and time-decayed scores ensures that users remain engaged and incentivized to contribute in a way that benefits the community as a whole.