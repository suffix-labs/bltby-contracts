// Governance Contract : Built By DAO V 0.01.0
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Governance is Initializable, AccessControlUpgradeable {
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
    bytes32 public constant LEADERSHIP_ROLE = keccak256("LEADERSHIP_ROLE");
    bytes32 public constant FOUNDER_DIRECTOR_ROLE = keccak256("FOUNDER_DIRECTOR_ROLE");

    IERC20 public bltbyToken;
    IERC721 public membershipNFT;
    IERC721 public investorNFT;

    uint256 public proposalCounter;
    uint256 public constant STAKE_AMOUNT = 2 * 10 ** 18;

    // Simplified struct without internal mapping
    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 creationTime;
        uint256 endTime;
        uint8 category;
        bool resolved;
        bool vetoed;
        uint256 totalVotes;
        uint256 leadershipVotes;
    }

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(uint256 => uint8)) public votes; // proposalId => nftId => vote
    mapping(address => uint256) public stakedBLTBY;

    event ProposalCreated(uint256 proposalId, address proposer, string description, uint256 endTime);
    event Voted(uint256 proposalId, address voter, uint256 nftId, uint8 vote);
    event ProposalResolved(uint256 proposalId, bool approved);
    event ProposalVetoed(uint256 proposalId);

    error Unauthorized();
    error InvalidCategory(uint8 category);
    error VotingPeriodOver(uint256 proposalId);
    error InsufficientStake();
    error ProposalAlreadyResolved(uint256 proposalId);
    error LeadershipQuorumNotMet(uint256 proposalId);

    function initialize(address _bltbyToken, address _membershipNFT, address _investorNFT, address _admin)
        public
        initializer
    {
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(FOUNDER_DIRECTOR_ROLE, _admin);
        bltbyToken = IERC20(_bltbyToken);
        membershipNFT = IERC721(_membershipNFT);
        investorNFT = IERC721(_investorNFT);
        proposalCounter = 1;
    }

    function createProposal(string memory description, uint256 duration, uint8 category) external {
        _validateProposalCreation(category);
        _stakeTokens();

        uint256 proposalId = proposalCounter++;
        _createNewProposal(proposalId, description, duration, category);

        emit ProposalCreated(proposalId, msg.sender, description, block.timestamp + duration);
    }

    function _validateProposalCreation(uint8 category) private view {
        if (!hasRole(PROPOSER_ROLE, msg.sender)) revert Unauthorized();
        if (category > 2) revert InvalidCategory(category);
        if (bltbyToken.balanceOf(msg.sender) < STAKE_AMOUNT) {
            revert InsufficientStake();
        }
    }

    function _stakeTokens() private {
        bool success = bltbyToken.transferFrom(msg.sender, address(this), STAKE_AMOUNT);
        require(success, "Transfer failed");
        stakedBLTBY[msg.sender] += STAKE_AMOUNT;
    }

    function _createNewProposal(uint256 proposalId, string memory description, uint256 duration, uint8 category)
        private
    {
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            description: description,
            creationTime: block.timestamp,
            endTime: block.timestamp + duration,
            category: category,
            resolved: false,
            vetoed: false,
            totalVotes: 0,
            leadershipVotes: 0
        });
    }

    function vote(uint256 proposalId, uint256 nftId, uint8 _vote) external {
        _validateVote(proposalId, nftId);

        votes[proposalId][nftId] = _vote;
        proposals[proposalId].totalVotes++;

        if (hasRole(LEADERSHIP_ROLE, msg.sender)) {
            proposals[proposalId].leadershipVotes++;
        }

        emit Voted(proposalId, msg.sender, nftId, _vote);
    }

    function _validateVote(uint256 proposalId, uint256 nftId) private view {
        Proposal storage proposal = proposals[proposalId];
        if (block.timestamp > proposal.endTime) {
            revert VotingPeriodOver(proposalId);
        }
        if (proposal.resolved) revert ProposalAlreadyResolved(proposalId);
        if (!_canVote(msg.sender, nftId)) revert Unauthorized();
    }

    function resolveProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.resolved) revert ProposalAlreadyResolved(proposalId);
        if (proposal.leadershipVotes < _requiredLeadershipQuorum()) {
            revert LeadershipQuorumNotMet(proposalId);
        }

        bool approved = proposal.totalVotes >= _getApprovalThreshold(proposal.category);
        proposal.resolved = true;

        if (approved) {
            _returnStake(proposal.proposer);
        }

        emit ProposalResolved(proposalId, approved);
    }

    function _returnStake(address proposer) private {
        stakedBLTBY[proposer] -= STAKE_AMOUNT;
        bool success = bltbyToken.transfer(proposer, STAKE_AMOUNT);
        require(success, "Transfer failed");
    }

    function vetoProposal(uint256 proposalId) external onlyRole(FOUNDER_DIRECTOR_ROLE) {
        if (!hasRole(LEADERSHIP_ROLE, msg.sender)) revert Unauthorized();

        Proposal storage proposal = proposals[proposalId];
        proposal.vetoed = true;
        proposal.resolved = true;
        emit ProposalVetoed(proposalId);
    }

    function _canVote(address voter, uint256 nftId) internal view returns (bool) {
        try membershipNFT.ownerOf(nftId) returns (address owner) {
            if (owner == voter) return true;
        } catch {}

        try investorNFT.ownerOf(nftId) returns (address owner) {
            if (owner == voter) return true;
        } catch {}

        return false;
    }

    function _requiredLeadershipQuorum() internal pure returns (uint256) {
        return 2;
    }

    function _getApprovalThreshold(uint8 category) internal pure returns (uint256) {
        if (category == 0) return 50;
        if (category == 1) return 60;
        if (category == 2) return 65;
        return 100;
    }

    function getVote(uint256 proposalId, uint256 nftId) external view returns (uint8) {
        return votes[proposalId][nftId];
    }

    /**
     * @dev Storage gap for future upgrades
     */
    uint256[50] private __gap;
}
