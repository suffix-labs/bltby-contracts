// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import "../src/MigrationUpgradeProxy.sol";
import "../src/BLTBYToken.sol";

contract MigrationUpgradeProxyTest is Test {
    MigrationAndUpgradeProxy public migrationProxy;
    address public owner;
    BLTBYToken public logicContract;
    address public adminAddr;

    function setUp() public {
        owner = makeAddr("owner");
        logicContract = new BLTBYToken();
        adminAddr = makeAddr("adminAddress");

        vm.prank(owner);
        migrationProxy = new MigrationAndUpgradeProxy(owner);
    }

    function testDeployProxy() public {
        bytes memory initData = abi.encodeWithSignature("initialize(address)", owner);

        vm.prank(owner);
        migrationProxy.deployProxy(address(logicContract), initData, "TestContract");

        address proxyAddress = migrationProxy.getProxyAddress("TestContract");
        address adminAddress = migrationProxy.getProxyAdmin("TestContract");

        assertTrue(proxyAddress != address(0));
        assertTrue(adminAddress != address(0));
    }

    function testGetProxyAddress() public {
        bytes memory initData = abi.encodeWithSignature("initialize(address)", owner);

        vm.prank(owner);
        migrationProxy.deployProxy(address(logicContract), initData, "TestContract");

        address proxyAddress = migrationProxy.getProxyAddress("TestContract");
        address storedAddress = migrationProxy.proxies("TestContract");

        assertEq(proxyAddress, storedAddress);
    }

    function testGetNonExistentProxy() public view {
        address proxyAddress = migrationProxy.getProxyAddress("NonExistent");
        assertEq(proxyAddress, address(0));
    }

    function testOnlyOwnerCanDeployProxy() public {
        bytes memory initData = abi.encodeWithSignature("initialize(address)", owner);
        address nonOwner = makeAddr("nonOwner");

        vm.prank(nonOwner);
        vm.expectRevert();
        migrationProxy.deployProxy(address(logicContract), initData, "TestContract");
    }

    function testUpgradeProxy() public {
        // Deploy initial proxy
        bytes memory initData = abi.encodeWithSignature("initialize(address)", owner);

        vm.prank(owner);
        migrationProxy.deployProxy(address(logicContract), initData, "TestContract");

        address proxyAddress = migrationProxy.getProxyAddress("TestContract");
        BLTBYToken newLogicContract = new BLTBYToken();

        // Upgrade proxy
        vm.prank(owner);
        migrationProxy.upgradeProxy("TestContract", address(newLogicContract));

        // Verify proxy address hasn't changed
        assertEq(migrationProxy.getProxyAddress("TestContract"), proxyAddress);
    }

    function testUpgradeProxyAndCall() public {
        // Deploy initial proxy
        bytes memory initData = abi.encodeWithSignature("initialize(address)", owner);

        vm.prank(owner);
        migrationProxy.deployProxy(address(logicContract), initData, "TestContract");

        BLTBYToken newLogicContract = new BLTBYToken();
        bytes memory upgradeData = "";

        // Upgrade proxy with call
        vm.prank(owner);
        migrationProxy.upgradeProxyAndCall("TestContract", address(newLogicContract), upgradeData);
    }

    function testCannotUpgradeNonExistentProxy() public {
        BLTBYToken newLogicContract = new BLTBYToken();

        vm.prank(owner);
        vm.expectRevert("Proxy not found");
        migrationProxy.upgradeProxy("NonExistent", address(newLogicContract));
    }

    function testOnlyOwnerCanUpgrade() public {
        // Deploy initial proxy
        bytes memory initData = abi.encodeWithSignature("initialize(address)", owner);

        vm.prank(owner);
        migrationProxy.deployProxy(address(logicContract), initData, "TestContract");

        address nonOwner = makeAddr("nonOwner");
        BLTBYToken newLogicContract = new BLTBYToken();

        vm.prank(nonOwner);
        vm.expectRevert();
        migrationProxy.upgradeProxy("TestContract", address(newLogicContract));
    }
}
