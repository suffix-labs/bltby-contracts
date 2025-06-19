// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import "../src/LeadershipCouncilNFT.sol";

contract LeadershipCouncilNFTTest is Test {
    LeadershipCouncilNFT public leadershipNFT;
    address public owner;
    address public minter;
    address public recipient;
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    function setUp() public {
        owner = makeAddr("owner");
        minter = makeAddr("minter");
        recipient = makeAddr("recipient");
        
        vm.startPrank(owner);
        leadershipNFT = new LeadershipCouncilNFT(owner);
        leadershipNFT.grantRole(MINTER_ROLE, minter);
        vm.stopPrank();
    }

    function testMintLeadershipNFTFounderDirector() public {
        vm.prank(minter);
        leadershipNFT.mintLeadershipNFT(recipient, true);
        
        assertEq(leadershipNFT.ownerOf(1), recipient);
        assertTrue(leadershipNFT.isFounderDirector(1));
        assertEq(leadershipNFT.getExtraVotes(1), 3);
        assertTrue(leadershipNFT.hasVetoPower(1));
    }

    function testMintLeadershipNFTNonFounderDirector() public {
        vm.prank(minter);
        leadershipNFT.mintLeadershipNFT(recipient, false);
        
        assertEq(leadershipNFT.ownerOf(1), recipient);
        assertFalse(leadershipNFT.isFounderDirector(1));
        assertEq(leadershipNFT.getExtraVotes(1), 0);
        assertFalse(leadershipNFT.hasVetoPower(1));
    }

    function testBurnLeadershipNFTByOwner() public {
        vm.prank(minter);
        leadershipNFT.mintLeadershipNFT(recipient, true);
        
        vm.prank(recipient);
        leadershipNFT.burnLeadershipNFT(1);
        
        vm.expectRevert();
        leadershipNFT.ownerOf(1);
    }

    function testBurnLeadershipNFTByAdmin() public {
        vm.prank(minter);
        leadershipNFT.mintLeadershipNFT(recipient, true);
        
        vm.prank(owner);
        leadershipNFT.burnLeadershipNFT(1);
        
        vm.expectRevert();
        leadershipNFT.ownerOf(1);
    }


    function testSupportsInterface() public {
        assertTrue(leadershipNFT.supportsInterface(type(IERC165).interfaceId));
    }
}