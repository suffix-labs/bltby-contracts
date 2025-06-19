// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import "../src/AngelNFT.sol";

contract AngelNFTTest is Test {
    AngelNFTContract public angelNFT;
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
        angelNFT = new AngelNFTContract(owner);
        angelNFT.grantRole(MINTER_ROLE, minter);
        vm.stopPrank();
    }

    function testMintAngelNFT() public {
        vm.prank(minter);
        angelNFT.mintAngelNFT(recipient, true);
        
        assertEq(angelNFT.ownerOf(1), recipient);
        assertTrue(angelNFT.hasEarlyInvestorPrivileges(1));
        assertEq(angelNFT.getGovernanceWeight(1), 3);
        assertEq(angelNFT.getDiscountRate(1), 15);
    }
    
    function testMintAngelNFTNonEarlyInvestor() public {
        vm.prank(minter);
        angelNFT.mintAngelNFT(recipient, false);
        
        assertEq(angelNFT.ownerOf(1), recipient);
        assertFalse(angelNFT.hasEarlyInvestorPrivileges(1));
        assertEq(angelNFT.getGovernanceWeight(1), 1);
        assertEq(angelNFT.getDiscountRate(1), 10);
    }

    function testBurnAngelNFTByOwner() public {
        vm.prank(minter);
        angelNFT.mintAngelNFT(recipient, true);
        
        vm.prank(recipient);
        angelNFT.burnAngelNFT(1);
        
        vm.expectRevert();
        angelNFT.ownerOf(1);
    }

    function testBurnAngelNFTByAdmin() public {
        vm.prank(minter);
        angelNFT.mintAngelNFT(recipient, true);
        
        vm.prank(owner);
        angelNFT.burnAngelNFT(1);
        
        vm.expectRevert();
        angelNFT.ownerOf(1);
    }


    function testSupportsInterface() public {
        assertTrue(angelNFT.supportsInterface(type(IERC165).interfaceId));
    }
}