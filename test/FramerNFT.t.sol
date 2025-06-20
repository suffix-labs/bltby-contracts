// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import "../src/FramerNFT.sol";

contract FramerNFTTest is Test {
    FramerNFT public framerNFT;
    address public owner;
    address public minter;
    address public recipient;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    function setUp() public {
        owner = makeAddr("owner");
        minter = makeAddr("minter");
        recipient = makeAddr("recipient");

        vm.startPrank(owner);
        framerNFT = new FramerNFT(owner);
        framerNFT.grantRole(MINTER_ROLE, minter);
        vm.stopPrank();
    }

    function testMintFramerNFTEarlyContributor() public {
        vm.prank(minter);
        framerNFT.mintFramerNFT(recipient, true);

        assertEq(framerNFT.ownerOf(1), recipient);
        assertTrue(framerNFT.isEarlyContributor(1));
        assertEq(framerNFT.getGovernanceWeight(1), 2);
        assertTrue(framerNFT.hasLifetimeBenefits(1));
    }

    function testMintFramerNFTNonEarlyContributor() public {
        vm.prank(minter);
        framerNFT.mintFramerNFT(recipient, false);

        assertEq(framerNFT.ownerOf(1), recipient);
        assertFalse(framerNFT.isEarlyContributor(1));
        assertEq(framerNFT.getGovernanceWeight(1), 1);
        assertFalse(framerNFT.hasLifetimeBenefits(1));
    }

    function testBurnFramerNFTByOwner() public {
        vm.prank(minter);
        framerNFT.mintFramerNFT(recipient, true);

        vm.prank(recipient);
        framerNFT.burnFramerNFT(1);

        vm.expectRevert();
        framerNFT.ownerOf(1);
    }

    function testBurnFramerNFTByAdmin() public {
        vm.prank(minter);
        framerNFT.mintFramerNFT(recipient, true);

        vm.prank(owner);
        framerNFT.burnFramerNFT(1);

        vm.expectRevert();
        framerNFT.ownerOf(1);
    }

    function testSupportsInterface() public {
        assertTrue(framerNFT.supportsInterface(type(IERC165).interfaceId));
    }
}
