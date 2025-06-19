// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import "../src/GeneralMembershipNFT.sol";

contract GeneralMembershipNFTTest is Test {
    GeneralMembershipNFT public membershipNFT;
    address public owner;
    address public minter;
    address public recipient;
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    function setUp() public {
        owner = makeAddr("owner");
        minter = makeAddr("minter");
        recipient = makeAddr("recipient");
        
        vm.startPrank(owner);
        membershipNFT = new GeneralMembershipNFT(owner);
        membershipNFT.grantRole(MINTER_ROLE, minter);
        vm.stopPrank();
    }

    function testMintGeneralMembershipNFTActiveMember() public {
        vm.prank(minter);
        membershipNFT.mintGeneralMembershipNFT(recipient, true);
        
        assertEq(membershipNFT.ownerOf(1), recipient);
        assertTrue(membershipNFT.isActiveMember(1));
        assertEq(membershipNFT.getAccessLevel(1), 1);
        assertTrue(membershipNFT.hasMembershipNFT(recipient));
    }

    function testMintGeneralMembershipNFTInactiveMember() public {
        vm.prank(minter);
        membershipNFT.mintGeneralMembershipNFT(recipient, false);
        
        assertEq(membershipNFT.ownerOf(1), recipient);
        assertFalse(membershipNFT.isActiveMember(1));
        assertEq(membershipNFT.getAccessLevel(1), 0);
        assertTrue(membershipNFT.hasMembershipNFT(recipient));
    }

    function testUpdateMembership() public {
        vm.prank(minter);
        membershipNFT.mintGeneralMembershipNFT(recipient, false);
        
        vm.prank(owner);
        membershipNFT.updateMembership(1, true, 2);
        
        assertTrue(membershipNFT.isActiveMember(1));
        assertEq(membershipNFT.getAccessLevel(1), 2);
    }

    function testBurnGeneralMembershipNFTByOwner() public {
        vm.prank(minter);
        membershipNFT.mintGeneralMembershipNFT(recipient, true);
        
        vm.prank(recipient);
        membershipNFT.burnGeneralMembershipNFT(1);
        
        vm.expectRevert();
        membershipNFT.ownerOf(1);
        assertFalse(membershipNFT.hasMembershipNFT(recipient));
    }

    function testBurnGeneralMembershipNFTByAdmin() public {
        vm.prank(minter);
        membershipNFT.mintGeneralMembershipNFT(recipient, true);
        
        vm.prank(owner);
        membershipNFT.burnGeneralMembershipNFT(1);
        
        vm.expectRevert();
        membershipNFT.ownerOf(1);
        assertFalse(membershipNFT.hasMembershipNFT(recipient));
    }


    function testSupportsInterface() public {
        assertTrue(membershipNFT.supportsInterface(type(IERC165).interfaceId));
    }
}