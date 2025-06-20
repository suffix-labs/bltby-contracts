// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import "../src/BLTBYToken.sol";
import "../src/Governance.sol";
import "../src/MigrationUpgradeProxy.sol";

contract UpgradeIntegrationTest is Test {
    MigrationAndUpgradeProxy public migrationProxy;
    BLTBYToken public tokenImplementation;
    Governance public governanceImplementation;
    
    BLTBYToken public token;
    Governance public governance;
    
    address public owner;
    address public user1;
    address public user2;

    function setUp() public {
        owner = makeAddr("owner");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        vm.startPrank(owner);
        
        // Deploy migration proxy
        migrationProxy = new MigrationAndUpgradeProxy(owner);
        
        // Deploy implementations
        tokenImplementation = new BLTBYToken();
        governanceImplementation = new Governance();
        
        // Deploy BLTBYToken via proxy
        bytes memory tokenInitData = abi.encodeWithSignature("initialize(address)", owner);
        migrationProxy.deployProxy(
            address(tokenImplementation),
            tokenInitData,
            "BLTBYToken"
        );
        
        token = BLTBYToken(migrationProxy.getProxyAddress("BLTBYToken"));
        
        vm.stopPrank();
    }

    function testTokenUpgradePreservesState() public {
        // Setup initial state
        vm.startPrank(owner);
        token.transfer(user1, 1000 * 10**18);
        vm.stopPrank();
        
        uint256 user1BalanceBefore = token.balanceOf(user1);
        uint256 totalSupplyBefore = token.totalSupply();
        string memory nameBefore = token.name();
        
        // Deploy new implementation
        BLTBYToken newImplementation = new BLTBYToken();
        
        // Upgrade
        vm.prank(owner);
        migrationProxy.upgradeProxy("BLTBYToken", address(newImplementation));
        
        // Verify state preserved
        assertEq(token.balanceOf(user1), user1BalanceBefore);
        assertEq(token.totalSupply(), totalSupplyBefore);
        assertEq(token.name(), nameBefore);
        assertEq(token.MAX_SUPPLY(), 2_500_000_000 * 10**18);
    }

    function testUpgradeWithNewFunctionality() public {
        // This test demonstrates how you would test a real upgrade
        // with new functionality added to the implementation
        
        // For this example, we'll just verify the upgrade mechanism works
        // In a real scenario, you'd deploy BLTBYTokenV2 with new functions
        
        address implementationBefore = migrationProxy.getProxyAddress("BLTBYToken");
        
        // Deploy new implementation (same contract for demo)
        BLTBYToken newImplementation = new BLTBYToken();
        
        vm.prank(owner);
        migrationProxy.upgradeProxy("BLTBYToken", address(newImplementation));
        
        // Proxy address should remain the same
        assertEq(migrationProxy.getProxyAddress("BLTBYToken"), implementationBefore);
        
        // Token should still work
        vm.prank(owner);
        token.transfer(user1, 100 * 10**18);
        assertEq(token.balanceOf(user1), 100 * 10**18);
    }

    function testMultipleContractUpgrades() public {
        // Deploy NFT contracts for governance (keeping simple for test)
        address membershipNFT = makeAddr("membershipNFT");
        address investorNFT = makeAddr("investorNFT");
        
        // Deploy Governance via proxy
        vm.startPrank(owner);
        bytes memory govInitData = abi.encodeWithSignature(
            "initialize(address,address,address,address)",
            address(token),
            membershipNFT,
            investorNFT,
            owner
        );
        migrationProxy.deployProxy(
            address(governanceImplementation),
            govInitData,
            "Governance"
        );
        
        governance = Governance(migrationProxy.getProxyAddress("Governance"));
        vm.stopPrank();
        
        // Verify both contracts work
        assertEq(address(governance.bltbyToken()), address(token));
        assertEq(governance.proposalCounter(), 1);
        
        // Upgrade both contracts
        BLTBYToken newTokenImpl = new BLTBYToken();
        Governance newGovImpl = new Governance();
        
        vm.startPrank(owner);
        migrationProxy.upgradeProxy("BLTBYToken", address(newTokenImpl));
        migrationProxy.upgradeProxy("Governance", address(newGovImpl));
        vm.stopPrank();
        
        // Verify both still work after upgrade
        assertEq(address(governance.bltbyToken()), address(token));
        assertEq(governance.proposalCounter(), 1);
        assertEq(token.name(), "BLTBY Token Contract");
    }

    function testUpgradeAccessControl() public {
        address nonOwner = makeAddr("nonOwner");
        BLTBYToken newImplementation = new BLTBYToken();
        
        // Non-owner cannot upgrade
        vm.prank(nonOwner);
        vm.expectRevert();
        migrationProxy.upgradeProxy("BLTBYToken", address(newImplementation));
        
        // Owner can upgrade
        vm.prank(owner);
        migrationProxy.upgradeProxy("BLTBYToken", address(newImplementation));
    }

    function testUpgradeNonExistentContract() public {
        BLTBYToken newImplementation = new BLTBYToken();
        
        vm.prank(owner);
        vm.expectRevert("Proxy not found");
        migrationProxy.upgradeProxy("NonExistent", address(newImplementation));
    }
}