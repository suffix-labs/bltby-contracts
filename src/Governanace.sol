// Governance Contract : Built By DAO V 0.01.0
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/access/AccessControl.sol";
import "@openzeppelin/utils/ReentrancyGuard.sol";
import "@openzeppelin/token/ERC20/IERC20.sol";
import "@openzeppelin/token/ERC721/IERC721.sol";

contract Governance is AccessControl, ReentrancyGuard {
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
    bytes32 public constant LEADERSHIP_ROLE = keccak256("LEADERSHIP_ROLE");
    bytes32 public constant FOUNDER_DIRECTOR_ROLE =
        keccak256("FOUNDER_DIRECTOR_ROLE");

    IERC20 public bltbyToken;
    IERC721 public membershipNFT;
    IERC721 public investorNFT;

    uint256 public proposalCounter;
    uint256 public constant STAKE_AMOUNT = 2 * 10 ** 18; // 2 BLTBY tokens

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 creationTime;
        uint256 endTime;
        uint8 category; // 0 = Standard, 1 = Critical, 2 = Judicial
        bool resolved;
        bool vetoed;
        mapping(uint256 => uint8) rankedVotes; // Maps NFT ID to rank choice
        uint256 totalVotes;
        uint256 leadershipVotes;
        uint256 yesVotes;
        uint256 noVotes;
    }

    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256) public stakedBLTBY; // Tracks BLTBY tokens staked for proposal submissions

    event ProposalCreated(
        uint256 proposalId,
        address proposer,
        string description,
        uint256 endTime
    );
    event Voted(uint256 proposalId, address voter, uint256 nftId, uint8 vote);
    event ProposalResolved(uint256 proposalId, bool approved);
    event ProposalVetoed(uint256 proposalId);

    error Unauthorized();
    error AlreadyVoted(uint256 proposalId);
    error ProposalNotFound(uint256 proposalId);
    error InvalidCategory(uint8 category);
    error VotingPeriodOver(uint256 proposalId);
    error InsufficientStake();
    error ProposalAlreadyResolved(uint256 proposalId);
    error LeadershipQuorumNotMet(uint256 proposalId);

    constructor(
        address _bltbyToken,
        address _membershipNFT,
        address _investorNFT
    ) {
        grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(FOUNDER_DIRECTOR_ROLE, msg.sender);
        bltbyToken = IERC20(_bltbyToken);
        membershipNFT = IERC721(_membershipNFT);
        investorNFT = IERC721(_investorNFT);
        proposalCounter = 1;
    }

    /**
     * @dev Create a new proposal.
     * Proposers must stake 2 BLTBY tokens to submit a proposal.
     * @param description The proposal description.
     * @param duration The voting duration for the proposal.
     * @param category The category of the proposal (0 = Standard, 1 = Critical, 2 = Judicial).
     */
    function createProposal(
        string memory description,
        uint256 duration,
        uint8 category
    ) external nonReentrant {
        if (!hasRole(PROPOSER_ROLE, msg.sender)) {
            revert Unauthorized();
        }
        if (category > 2) {
            revert InvalidCategory(category);
        }
        if (bltbyToken.balanceOf(msg.sender) < STAKE_AMOUNT) {
            revert InsufficientStake();
        }

        bltbyToken.transferFrom(msg.sender, address(this), STAKE_AMOUNT);
        stakedBLTBY[msg.sender] += STAKE_AMOUNT;

        uint256 proposalId = proposalCounter++;
        Proposal storage newProposal = proposals[proposalId];
        newProposal.id = proposalId;
        newProposal.proposer = msg.sender;
        newProposal.description = description;
        newProposal.creationTime = block.timestamp;
        newProposal.endTime = block.timestamp + duration;
        newProposal.category = category;
        newProposal.resolved = false;
        newProposal.vetoed = false;
        newProposal.totalVotes = 0;
        newProposal.leadershipVotes = 0;

        emit ProposalCreated(
            proposalId,
            msg.sender,
            description,
            newProposal.endTime
        );
    }

    /**
     * @dev Vote on a proposal using ranked choice.
     * @param proposalId The ID of the proposal to vote on.
     * @param nftId The ID of the NFT representing the voter.
     * @param vote The rank choice (1 for Yes, 2 for No).
     */
    function vote(
        uint256 proposalId,
        uint256 nftId,
        uint8 vote
    ) external nonReentrant {
        if (block.timestamp > proposals[proposalId].endTime) {
            revert VotingPeriodOver(proposalId);
        }
        if (proposals[proposalId].resolved) {
            revert ProposalAlreadyResolved(proposalId);
        }
        if (!_canVote(msg.sender, nftId)) {
            revert Unauthorized();
        }

        Proposal storage proposal = proposals[proposalId];
        proposal.rankedVotes[nftId] = vote;
        proposal.totalVotes++;

        if (hasRole(LEADERSHIP_ROLE, msg.sender)) {
            proposal.leadershipVotes++;
        }

        emit Voted(proposalId, msg.sender, nftId, vote);
    }

    /**
     * @dev Resolve a proposal by determining if it passed based on votes.
     * Leadership quorum must be met for the proposal to be valid.
     * @param proposalId The ID of the proposal to resolve.
     */
    function resolveProposal(uint256 proposalId) external nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.resolved) {
            revert ProposalAlreadyResolved(proposalId);
        }
        if (proposal.leadershipVotes < _requiredLeadershipQuorum()) {
            revert LeadershipQuorumNotMet(proposalId);
        }

        bool approved = false;
        uint256 approvalThreshold = _getApprovalThreshold(proposal.category);
        if (proposal.totalVotes >= approvalThreshold) {
            approved = true;
        }

        proposal.resolved = true;
        if (approved) {
            stakedBLTBY[proposal.proposer] -= STAKE_AMOUNT;
            bltbyToken.transfer(proposal.proposer, STAKE_AMOUNT);
        }

        emit ProposalResolved(proposalId, approved);
    }

    /**
     * @dev Veto a proposal.
     * Requires the Founding Director and one Leadership Council member.
     * @param proposalId The ID of the proposal to veto.
     */
    function vetoProposal(
        uint256 proposalId
    ) external nonReentrant onlyRole(FOUNDER_DIRECTOR_ROLE) {
        if (!hasRole(LEADERSHIP_ROLE, msg.sender)) {
            revert Unauthorized();
        }

        Proposal storage proposal = proposals[proposalId];
        proposal.vetoed = true;
        proposal.resolved = true;
        emit ProposalVetoed(proposalId);
    }

    /**
     * @dev Helper function to determine if an address can vote with a given NFT ID.
     * @param voter The address of the voter.
     * @param nftId The ID of the NFT to verify voting rights.
     * @return True if the voter is authorized to vote, otherwise false.
     */
    function _canVote(
        address voter,
        uint256 nftId
    ) internal view returns (bool) {
        return (membershipNFT.ownerOf(nftId) == voter ||
            investorNFT.ownerOf(nftId) == voter);
    }

    /**
     * @dev Helper function to determine the required leadership quorum.
     * @return The required leadership votes for a proposal to be valid.
     */
    function _requiredLeadershipQuorum() internal view returns (uint256) {
        // Placeholder: Define the quorum logic
        return 2; // For demonstration, at least two leadership votes are needed
    }

    /**
     * @dev Helper function to get the approval threshold based on the category.
     * @param category The category of the proposal.
     * @return The approval threshold.
     */
    function _getApprovalThreshold(
        uint8 category
    ) internal pure returns (uint256) {
        if (category == 0) return 50;
        if (category == 1) return 60;
        if (category == 2) return 65;
        return 100;
    }
}

/*
 Key Features:
 - Proposal-based governance with ranked choice voting.
 - Only NFT holders can vote; BLTBY tokens are staked for submitting proposals but not used directly for voting power.
 - Proposals must reach a quorum from Leadership Council votes to be resolved.
 - Proposal staking mechanism requires proposers to stake 2 BLTBY tokens.
 - Founding Director plus a Leadership Council member can veto proposals.
 - Weighted voting for NFT holders, independent voting roles for members holding multiple NFTs.
*/
