// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import "../src/TreasuryAndReserve.sol";
import "../src/BLTBYToken.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1000000 * 10 ** 18);
    }
}

contract TreasuryAndReserveTest is Test {
    TreasuryAndReserve public treasury;
    BLTBYToken public bltbyToken;
    BLTBYToken public tokenImplementation;
    TransparentUpgradeableProxy public tokenProxy;
    ProxyAdmin public tokenProxyAdmin;

    MockERC20 public usdc;
    MockERC20 public usdt;
    MockERC20 public pyusd;

    address public owner;
    address public recipient;

    function setUp() public {
        owner = makeAddr("owner");
        recipient = makeAddr("recipient");

        vm.startPrank(owner);

        // Deploy BLTBYToken via proxy
        tokenImplementation = new BLTBYToken();
        tokenProxyAdmin = new ProxyAdmin(owner);
        bytes memory tokenInitData = abi.encodeWithSignature("initialize(address)", owner);
        tokenProxy =
            new TransparentUpgradeableProxy(address(tokenImplementation), address(tokenProxyAdmin), tokenInitData);
        bltbyToken = BLTBYToken(address(tokenProxy));
        usdc = new MockERC20("USD Coin", "USDC");
        usdt = new MockERC20("Tether USD", "USDT");
        pyusd = new MockERC20("PayPal USD", "PYUSD");

        treasury = new TreasuryAndReserve(owner, address(bltbyToken), address(usdc), address(usdt), address(pyusd));

        bltbyToken.transfer(address(treasury), 50000 * 10 ** 18);

        // Transfer mock tokens to owner for testing
        usdc.transfer(owner, 10000 * 10 ** 18);
        usdt.transfer(owner, 10000 * 10 ** 18);
        pyusd.transfer(owner, 10000 * 10 ** 18);

        vm.stopPrank();
    }

    function testMintBLTBY() public {
        uint256 mintAmount = 1000 * 10 ** 18;
        uint256 initialBalance = bltbyToken.balanceOf(recipient);

        vm.prank(owner);
        treasury.mintBLTBY(recipient, mintAmount);

        assertEq(bltbyToken.balanceOf(recipient), initialBalance + mintAmount);
    }

    function testExecuteBuybackWithUSDC() public {
        uint256 buybackAmount = 1000 * 10 ** 18;

        vm.prank(owner);
        usdc.approve(address(treasury), buybackAmount);

        vm.prank(owner);
        treasury.executeBuyback(address(usdc), buybackAmount);

        assertEq(usdc.balanceOf(address(treasury)), buybackAmount);
    }

    function testExecuteBuybackWithUSDT() public {
        uint256 buybackAmount = 1000 * 10 ** 18;

        vm.prank(owner);
        usdt.approve(address(treasury), buybackAmount);

        vm.prank(owner);
        treasury.executeBuyback(address(usdt), buybackAmount);

        assertEq(usdt.balanceOf(address(treasury)), buybackAmount);
    }

    function testExecuteBuybackWithPYUSD() public {
        uint256 buybackAmount = 1000 * 10 ** 18;

        vm.prank(owner);
        pyusd.approve(address(treasury), buybackAmount);

        vm.prank(owner);
        treasury.executeBuyback(address(pyusd), buybackAmount);

        assertEq(pyusd.balanceOf(address(treasury)), buybackAmount);
    }

    function testTransferToDAO() public {
        address newAdmin = makeAddr("newAdmin");

        vm.prank(owner);
        treasury.transferToDAO(newAdmin);

        assertEq(treasury.owner(), newAdmin);
    }

    function testOnlyOwnerCanMint() public {
        address nonOwner = makeAddr("nonOwner");

        vm.prank(nonOwner);
        vm.expectRevert();
        treasury.mintBLTBY(recipient, 1000 * 10 ** 18);
    }

    function testOnlyOwnerCanExecuteBuyback() public {
        address nonOwner = makeAddr("nonOwner");

        vm.prank(nonOwner);
        vm.expectRevert();
        treasury.executeBuyback(address(usdc), 1000 * 10 ** 18);
    }
}
