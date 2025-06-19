// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import "../src/BLTBYToken.sol";

contract BLTBYTokenTest is Test {
    BLTBYToken public bltbyToken;
    address public owner;
    address public minter;
    address public recipient;
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant MULTISIG_ROLE = keccak256("MULTISIG_ROLE");

    function setUp() public {
        owner = makeAddr("owner");
        minter = makeAddr("minter");
        recipient = makeAddr("recipient");
        
        vm.startPrank(owner);
        bltbyToken = new BLTBYToken(owner);
        bltbyToken.grantRole(MINTER_ROLE, minter);
        bltbyToken.grantRole(MULTISIG_ROLE, minter);
        vm.stopPrank();
    }

    function testInitialState() public {
        assertEq(bltbyToken.name(), "BLTBY Token Contract");
        assertEq(bltbyToken.symbol(), "BLTBY");
        assertEq(bltbyToken.decimals(), 18);
        assertEq(bltbyToken.totalSupply(), 100_000_000 * 10 ** 18);
        assertEq(bltbyToken.MAX_SUPPLY(), 2_500_000_000 * 10 ** 18);
    }

    function testTransfer() public {
        uint256 amount = 1000 * 10 ** 18;
        
        vm.prank(owner);
        bltbyToken.transfer(recipient, amount);
        
        assertEq(bltbyToken.balanceOf(recipient), amount);
    }

    function testPauseAndUnpause() public {
        vm.prank(owner);
        bltbyToken.pause();
        
        uint256 amount = 1000 * 10 ** 18;
        vm.prank(owner);
        vm.expectRevert();
        bltbyToken.transfer(recipient, amount);
        
        vm.prank(owner);
        bltbyToken.unpause();
        
        vm.prank(owner);
        bltbyToken.transfer(recipient, amount);
        assertEq(bltbyToken.balanceOf(recipient), amount);
    }

    function testBurn() public {
        uint256 burnAmount = 1000 * 10 ** 18;
        uint256 initialBalance = bltbyToken.balanceOf(owner);
        
        vm.prank(owner);
        bltbyToken.burn(owner, burnAmount);
        
        assertEq(bltbyToken.balanceOf(owner), initialBalance - burnAmount);
    }

    function testRedeem() public {
        uint256 redeemAmount = 1000 * 10 ** 18;
        
        vm.prank(owner);
        bltbyToken.transfer(recipient, redeemAmount);
        
        uint256 initialBalance = bltbyToken.balanceOf(recipient);
        
        vm.prank(recipient);
        bltbyToken.redeem(redeemAmount);
        
        assertEq(bltbyToken.balanceOf(recipient), initialBalance - redeemAmount);
    }

    function testMintWithValidRole() public {
        uint256 mintAmount = 1000 * 10 ** 18;
        
        vm.warp(block.timestamp + 366 days);
        
        vm.prank(minter);
        bltbyToken.mint(recipient, mintAmount);
        
        assertEq(bltbyToken.balanceOf(recipient), mintAmount);
    }
}