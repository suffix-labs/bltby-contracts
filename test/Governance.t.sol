// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import "../src/Governance.sol";
import "../src/BLTBYToken.sol";
import "../src/GeneralMembershipNFT.sol";
import "../src/AngelNFT.sol";

contract GovernanceTest is Test {
    Governance public governance;
    BLTBYToken public bltbyToken;
    GeneralMembershipNFT public membershipNFT;
    AngelNFTContract public investorNFT;

    address public owner;
    address public proposer;
    address public voter;

    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
    bytes32 public constant LEADERSHIP_ROLE = keccak256("LEADERSHIP_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    function setUp() public {
        owner = makeAddr("owner");
        proposer = makeAddr("proposer");
        voter = makeAddr("voter");

        vm.startPrank(owner);

        bltbyToken = new BLTBYToken(owner);
        membershipNFT = new GeneralMembershipNFT(owner);
        investorNFT = new AngelNFTContract(owner);

        governance = new Governance(
            address(bltbyToken),
            address(membershipNFT),
            address(investorNFT)
        );

        governance.grantRole(PROPOSER_ROLE, proposer);
        governance.grantRole(LEADERSHIP_ROLE, voter);

        membershipNFT.grantRole(MINTER_ROLE, owner);
        membershipNFT.mintGeneralMembershipNFT(voter, true);

        bltbyToken.transfer(proposer, 10 * 10 ** 18);
        vm.stopPrank();

        vm.prank(proposer);
        bltbyToken.approve(address(governance), 10 * 10 ** 18);
    }

    function testCreateProposal() public {
        vm.prank(proposer);
        governance.createProposal("Test proposal", 7 days, 0);

        (
            uint256 id,
            address creator,
            string memory description,
            uint256 creationTime,
            uint256 endTime,
            uint8 category,
            bool resolved,
            bool vetoed,
            uint256 totalVotes,
            uint256 leadershipVotes
        ) = governance.proposals(1);

        assertEq(id, 1);
        assertEq(creator, proposer);
        assertEq(description, "Test proposal");
        assertEq(category, 0);
        assertFalse(resolved);
        assertFalse(vetoed);
        assertEq(leadershipVotes, 0);
        assertEq(governance.stakedBLTBY(proposer), 2 * 10 ** 18);
    }

    function testVoteOnProposal() public {
        vm.prank(proposer);
        governance.createProposal("Test proposal", 7 days, 0);

        vm.prank(voter);
        governance.vote(1, 1, 1);

        (
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            uint256 totalVotes,
            uint256 leadershipVotes
        ) = governance.proposals(1);

        assertEq(totalVotes, 1);
        assertEq(leadershipVotes, 1);
    }

    function testResolveProposal() public {
        vm.prank(proposer);
        governance.createProposal("Test proposal", 7 days, 0);

        vm.prank(voter);
        governance.vote(1, 1, 1);

        address voter2 = makeAddr("voter2");
        vm.prank(owner);
        governance.grantRole(LEADERSHIP_ROLE, voter2);

        vm.prank(owner);
        membershipNFT.mintGeneralMembershipNFT(voter2, true);

        vm.prank(voter2);
        governance.vote(1, 2, 1);

        vm.warp(block.timestamp + 8 days);

        governance.resolveProposal(1);

        (, , , , , , bool resolved, , , ) = governance.proposals(1);

        assertTrue(resolved);
    }

    function testVetoProposal() public {
        vm.prank(proposer);
        governance.createProposal("Test proposal", 7 days, 0);

        vm.prank(owner);
        governance.grantRole(LEADERSHIP_ROLE, owner);

        vm.prank(owner);
        governance.vetoProposal(1);

        (, , , , , , bool resolved, bool vetoed, , ) = governance.proposals(1);

        assertTrue(resolved);
        assertTrue(vetoed);
    }
}
