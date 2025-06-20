// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import "../src/VentureOneNFT.sol";

contract VentureOneNFTTest is Test {
    VentureOneNFTContract public ventureOneNFT;
    address public owner;
    address public minter;
    address public recipient;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    function setUp() public {
        owner = makeAddr("owner");
        minter = makeAddr("minter");
        recipient = makeAddr("recipient");

        vm.startPrank(owner);
        ventureOneNFT = new VentureOneNFTContract(owner);
        ventureOneNFT.grantRole(MINTER_ROLE, minter);
        vm.stopPrank();
    }

    function testMintVentureOneNFTRoundOne() public {
        vm.prank(minter);
        ventureOneNFT.mintVentureOneNFT(recipient, true);

        assertEq(ventureOneNFT.ownerOf(1), recipient);
        assertTrue(ventureOneNFT.isVentureRoundOne(1));
        assertEq(ventureOneNFT.getGovernanceWeight(1), 4);
        assertEq(ventureOneNFT.getDiscountRate(1), 20);
    }

    function testMintVentureOneNFTNonRoundOne() public {
        vm.prank(minter);
        ventureOneNFT.mintVentureOneNFT(recipient, false);

        assertEq(ventureOneNFT.ownerOf(1), recipient);
        assertFalse(ventureOneNFT.isVentureRoundOne(1));
        assertEq(ventureOneNFT.getGovernanceWeight(1), 2);
        assertEq(ventureOneNFT.getDiscountRate(1), 10);
    }

    function testBurnVentureOneNFTByOwner() public {
        vm.prank(minter);
        ventureOneNFT.mintVentureOneNFT(recipient, true);

        vm.prank(recipient);
        ventureOneNFT.burnVentureOneNFT(1);

        vm.expectRevert();
        ventureOneNFT.ownerOf(1);
    }

    function testBurnVentureOneNFTByAdmin() public {
        vm.prank(minter);
        ventureOneNFT.mintVentureOneNFT(recipient, true);

        vm.prank(owner);
        ventureOneNFT.burnVentureOneNFT(1);

        vm.expectRevert();
        ventureOneNFT.ownerOf(1);
    }

    function testSupportsInterface() public {
        assertTrue(ventureOneNFT.supportsInterface(type(IERC165).interfaceId));
    }
}
