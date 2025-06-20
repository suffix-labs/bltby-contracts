# BLTBY DAO Contracts

A comprehensive smart contract ecosystem for the Built By DAO, featuring upgradeable governance, token economics, and membership management with a complete proxy upgrade system.

## 🏗️ Architecture Overview

The BLTBY ecosystem consists of several interconnected contracts designed for upgradeability, governance, and membership management:

```
┌─────────────────────────────────────────────────────────────┐
│                    BLTBY DAO Ecosystem                      │
├─────────────────────────────────────────────────────────────┤
│  📊 Core Governance Layer                                   │
│  ├── Governance (Upgradeable) ← Controls proposal system   │
│  ├── BLTBYToken (Upgradeable) ← Voting power & utility     │
│  └── TreasuryAndReserve ← Treasury management              │
├─────────────────────────────────────────────────────────────┤
│  🎫 Membership & Access Layer                               │
│  ├── GeneralMembershipNFT ← Basic membership              │
│  ├── LeadershipCouncilNFT ← Leadership roles              │
│  ├── AngelNFT ← Early investor access                     │
│  ├── VentureOneNFT ← Round 1 investors                    │
│  ├── TrustNFT ← Institutional access                      │
│  ├── FramerNFT ← Early contributor rewards                │
│  └── UmbrellaAccessToken ← Sub-contract management        │
├─────────────────────────────────────────────────────────────┤
│  ⚙️ Infrastructure Layer                                    │
│  ├── MigrationUpgradeProxy ← Upgrade management           │
│  └── CustomTransparentProxy ← Proxy implementation        │
└─────────────────────────────────────────────────────────────┘
```

## 🔄 Upgradeable Proxy System

### Core Upgrade Infrastructure

The system uses OpenZeppelin's transparent proxy pattern with a custom management layer:

#### **MigrationUpgradeProxy**
Central contract for managing all upgradeable contracts:
- Deploys and manages multiple proxy contracts
- Handles upgrades through ProxyAdmin pattern
- Provides centralized upgrade control
- Maintains proxy and admin mappings

#### **CustomTransparentProxy**
Custom proxy implementation that:
- Accepts admin address directly (avoiding double ProxyAdmin creation)
- Implements transparent proxy pattern correctly
- Ensures proper upgrade mechanism functionality

### How Upgradeability Works

```solidity
// 1. Deploy the upgrade management system
MigrationAndUpgradeProxy migrationProxy = new MigrationAndUpgradeProxy(owner);

// 2. Deploy implementation contracts
BLTBYToken implementation = new BLTBYToken();

// 3. Deploy via proxy with initialization
migrationProxy.deployProxy(
    address(implementation),
    abi.encodeWithSignature("initialize(address)", owner),
    "BLTBYToken"
);

// 4. Get proxy address and interact with contract
address proxyAddress = migrationProxy.getProxyAddress("BLTBYToken");
BLTBYToken token = BLTBYToken(proxyAddress);

// 5. Later: Upgrade to new implementation
BLTBYTokenV2 newImplementation = new BLTBYTokenV2();
migrationProxy.upgradeProxy("BLTBYToken", address(newImplementation));
```

## 📋 Contract Specifications

### **BLTBYToken** (Upgradeable)
**Purpose**: Core utility and governance token
- **Supply**: 2.5B total, 100M initial circulation
- **Features**: Mintable (yearly cap), burnable, pausable, role-based access
- **Governance**: Used for proposal staking and voting weight
- **Upgradeability**: Full proxy support with state preservation

### **Governance** (Upgradeable)
**Purpose**: Decentralized proposal and voting system
- **Proposal Types**: 3 categories with different approval thresholds (50%, 60%, 65%)
- **Voting Power**: Based on NFT ownership (membership + investor NFTs)
- **Staking Requirement**: 2 BLTBY tokens to create proposals
- **Leadership Control**: Founder directors can veto proposals
- **Upgradeability**: Maintains proposal history across upgrades

### **TreasuryAndReserve**
**Purpose**: Treasury management and token buybacks
- **Supported Stablecoins**: USDC, USDT, PYUSD
- **Functions**: Buyback execution, treasury transfers, emergency minting
- **Access Control**: Owner-only operations

## 🎫 Membership System

### **Hierarchical Access Control**

```
┌── GeneralMembershipNFT (Base tier)
├── LeadershipCouncilNFT (Leadership roles)
├── AngelNFT (Early investors)
├── VentureOneNFT (Round 1 investors)
├── TrustNFT (Institutional access)
└── FramerNFT (Early contributors)
```

### **NFT Contract Features**
- **Uniform Interface**: All NFTs inherit similar burning/admin patterns
- **Role-Based Minting**: Specific roles can mint each NFT type
- **Governance Integration**: NFTs provide voting rights in governance
- **Metadata Support**: URI-based metadata for each NFT type

### **UmbrellaAccessToken**
**Purpose**: Factory for creating sub-contract access tokens
- **Clone Pattern**: Uses OpenZeppelin Clones for gas efficiency
- **Approval System**: Two-step creation and approval process
- **Sub-Contract Types**: Gym, Event, Seminar access tokens
- **Verification**: Built-in validation for sub-contract legitimacy

## 🚀 Deployment Guide

### Prerequisites
```bash
# Install dependencies
forge install

# Verify compilation
forge build

# Run tests
forge test
```

### Deployment Steps

1. **Deploy Infrastructure**
```solidity
// Deploy upgrade management
MigrationAndUpgradeProxy migrationProxy = new MigrationAndUpgradeProxy(deployer);
```

2. **Deploy Core Contracts**
```solidity
// Deploy token
BLTBYToken tokenImpl = new BLTBYToken();
migrationProxy.deployProxy(
    address(tokenImpl),
    abi.encodeWithSignature("initialize(address)", owner),
    "BLTBYToken"
);

// Deploy governance
Governance govImpl = new Governance();
migrationProxy.deployProxy(
    address(govImpl),
    abi.encodeWithSignature("initialize(address,address,address,address)", 
        tokenAddress, membershipNFT, investorNFT, owner),
    "Governance"
);
```

3. **Deploy Supporting Contracts**
```solidity
// Deploy NFT contracts
GeneralMembershipNFT membership = new GeneralMembershipNFT(owner);
// ... other NFTs

// Deploy treasury
TreasuryAndReserve treasury = new TreasuryAndReserve(
    owner, tokenAddress, usdcAddress, usdtAddress, pyusdAddress
);
```

## 🔧 Upgrade Process

### Standard Upgrade
```solidity
// 1. Deploy new implementation
BLTBYTokenV2 newImplementation = new BLTBYTokenV2();

// 2. Upgrade via migration proxy
migrationProxy.upgradeProxy("BLTBYToken", address(newImplementation));

// 3. State is automatically preserved
```

### Upgrade with Initialization
```solidity
// For upgrades requiring additional setup
bytes memory upgradeData = abi.encodeWithSignature("reinitialize(uint256)", newVersion);
migrationProxy.upgradeProxyAndCall("BLTBYToken", address(newImplementation), upgradeData);
```

## 🎯 Governance Workflow

### Creating Proposals
```solidity
// 1. Stake required BLTBY tokens (2 BLTBY)
token.approve(governance, 2 * 10**18);

// 2. Create proposal (requires PROPOSER_ROLE)
governance.createProposal("Proposal description", 7 days, categoryType);
```

### Voting Process
```solidity
// Vote using NFT ownership (1 = support, 0 = oppose)
governance.vote(proposalId, nftId, voteChoice);
```

### Resolution
```solidity
// After voting period + leadership quorum met
governance.resolveProposal(proposalId);
```

## 🧪 Testing

The project includes comprehensive test coverage:

- **Unit Tests**: Individual contract functionality
- **Integration Tests**: Cross-contract interactions
- **Upgrade Tests**: Proxy upgrade mechanisms
- **Access Control Tests**: Permission validation

```bash
# Run all tests
forge test

# Run with gas reporting
forge test --gas-report

# Run specific test suite
forge test --match-contract BLTBYTokenTest
```

## 🔒 Security Features

### Access Control
- **Role-based permissions** using OpenZeppelin AccessControl
- **Multi-signature requirements** for critical operations
- **Emergency pause functionality** for token operations

### Upgrade Safety
- **Initializer protection** prevents double initialization
- **Storage gaps** reserved for future variables
- **State preservation** across all upgrades
- **Admin controls** for upgrade authorization

### Economic Security
- **Proposal staking** prevents spam proposals
- **Leadership quorum** ensures informed decisions
- **Veto powers** for founder oversight
- **Mint caps** prevent inflation attacks

## 📊 Gas Optimization

- **Clone pattern** for sub-contract creation (UmbrellaAccessToken)
- **Efficient storage layout** in upgradeable contracts
- **Minimal proxy overhead** with custom implementation
- **Batch operations** where applicable

## 🛠️ Foundry Commands

### Build
```shell
$ forge build
```

### Test
```shell
$ forge test
```

### Format
```shell
$ forge fmt
```

### Gas Snapshots
```shell
$ forge snapshot
```

### Local Development
```shell
$ anvil
```

### Deploy
```shell
$ forge script script/Deploy.s.sol --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Contract Interaction
```shell
$ cast <subcommand>
```

### Help
```shell
$ forge --help
$ anvil --help
$ cast --help
```

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Write tests for new functionality
4. Ensure all tests pass (`forge test`)
5. Submit pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Built by the BLTBY DAO Community** 🏗️