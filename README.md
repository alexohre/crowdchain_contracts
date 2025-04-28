# Crowdchain Smart Contract 📜🔗

## Overview

The Crowdchain Smart Contract is the core technological infrastructure enabling transparent, secure, and efficient decentralized crowdfunding on the blockchain.  
**Note:** This contract is built for **Starknet**, utilizing Cairo for smart contract development.

## 🌟 Contract Features

### Funding Mechanisms

- Project creation and registration
- Donation tracking
- Transparent fund allocation
- Milestone-based fund release

### Security Attributes

- Immutable transaction records
- Decentralized governance
- Automated contribution verification
- Donor protection mechanisms

## 🔧 Technical Details

### Blockchain Compatibility

- **Starknet** smart contract
- Written in **Cairo**
- Utilizes **Starknet's account abstraction model**
- Security best practices in **OpenZeppelin Cairo contracts**

### Contract Parameters

- Minimum project funding threshold
- Maximum project duration
- Contribution limits
- Milestone verification requirements

### Core Data Structures

#### User

- `address`: ContractAddress - User's wallet address
- `name`: felt252 - Display name
- `role`: felt252 - User role ('admin', 'creator', 'donor')
- `is_creator`: bool - Creator status flag
- `total_contributed`: u128 - Total contributions made
- `campaigns_created`: u32 - Number of campaigns created
- `nfts_owned`: u32 - Number of NFTs owned

#### Campaign

- `id`: u32 - Unique campaign ID
- `creator`: ContractAddress - Creator's address
- `title`: felt252 - Campaign title
- `description`: felt252 - Campaign description
- `target_amount`: u128 - Funding target
- `amount_raised`: u128 - Current funds raised
- `start/end_timestamp`: u64 - Campaign duration
- `is_active`: bool - Active status
- `contributors_count`: u32 - Number of contributors
- `rewards_issued`: bool - NFT rewards status

#### Contribution

- `campaign_id`: u32 - Associated campaign ID
- `contributor`: ContractAddress - Contributor's address
- `amount`: u128 - Contribution amount
- `timestamp`: u64 - Contribution time
- `reward_tier`: u8 - NFT reward tier (0-3)

#### NFTReward

- `campaign_id`: u32 - Associated campaign ID
- `recipient`: ContractAddress - Recipient address
- `token_id`: u128 - NFT token ID
- `tier`: u8 - Reward tier (1-3)
- `claimed`: bool - Claim status
- `metadata_uri`: felt252 - NFT metadata URI

## 📁 Project Structure

```
src/
├── contracts/
│   └── Implementation of core contract logic
├── events/
│   └── Event definitions and handlers
├── structs/
│ └──  Structs definitions
├── interfaces/
│   └── Contract interfaces implementation
└── lib.cairo     # Library entry point

tests/           # Test directory
```

## 🛡️ Security Considerations

- Comprehensive access control
- Pausable contract functionality
- Reentrancy protection
- Extensive error handling

## 📝 Development Environment

### Prerequisites

- **Cairo** (latest stable version)
- **Scarb** (version 2.3.1 or higher)
- **Starknet-Foundry** or **Protostar** for development
- OpenZeppelin Cairo library
- Starknet development wallet

### Deployment Steps

1. Compile the smart contract using **Cairo compiler**
2. Run unit and integration tests
3. Deploy to **Starknet testnet/mainnet**
4. Verify contract on **Starkscan**

## 🧪 Testing

### Test Coverage

- Unit tests for each contract function
- Integration tests for complex interactions
- Edge case scenario testing
- Security vulnerability scanning

### Test Scenarios

- Successful project creation
- Contribution mechanisms
- Milestone fund release
- Refund scenarios
- NFT reward generation

## 🤝 Contributing

### Smart Contract Development

- Follow **Cairo** best practices
- Maintain high test coverage
- Conduct thorough code reviews
- Submit detailed pull requests

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
