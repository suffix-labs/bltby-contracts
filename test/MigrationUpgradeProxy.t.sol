// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import "../src/MigrationUpgradeProxy.sol";

contract MigrationUpgradeProxyTest is Test {
    MigrationAndUpgradeProxy public migrationProxy;
    address public owner;
    address public logicContract;
    address public adminAddress;
    
    function setUp() public {
        owner = makeAddr("owner");
        logicContract = makeAddr("logicContract");
        adminAddress = makeAddr("adminAddress");
        
        vm.prank(owner);
        migrationProxy = new MigrationAndUpgradeProxy(owner);
    }

    function testDeployProxy() public {
        bytes memory initData = abi.encodeWithSignature("initialize()");
        
        vm.prank(owner);
        migrationProxy.deployProxy(
            logicContract,
            adminAddress,
            initData,
            "TestContract"
        );
        
        address proxyAddress = migrationProxy.getProxyAddress("TestContract");
        assertTrue(proxyAddress != address(0));
    }

    function testGetProxyAddress() public {
        bytes memory initData = abi.encodeWithSignature("initialize()");
        
        vm.prank(owner);
        migrationProxy.deployProxy(
            logicContract,
            adminAddress,
            initData,
            "TestContract"
        );
        
        address proxyAddress = migrationProxy.getProxyAddress("TestContract");
        address storedAddress = migrationProxy.proxies("TestContract");
        
        assertEq(proxyAddress, storedAddress);
    }

    function testGetNonExistentProxy() public {
        address proxyAddress = migrationProxy.getProxyAddress("NonExistent");
        assertEq(proxyAddress, address(0));
    }

    function testOnlyOwnerCanDeployProxy() public {
        bytes memory initData = abi.encodeWithSignature("initialize()");
        address nonOwner = makeAddr("nonOwner");
        
        vm.prank(nonOwner);
        vm.expectRevert();
        migrationProxy.deployProxy(
            logicContract,
            adminAddress,
            initData,
            "TestContract"
        );
    }
}