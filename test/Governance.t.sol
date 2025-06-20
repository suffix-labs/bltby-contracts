// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import "../src/Governance.sol";
import "../src/BLTBYToken.sol";
import "../src/GeneralMembershipNFT.sol";
import "../src/AngelNFT.sol";
import "../src/MigrationUpgradeProxy.sol";

contract GovernanceTest is Test {
    Governance public governance;
    BLTBYToken public bltbyToken;
    MigrationAndUpgradeProxy public migrationProxy;

    GeneralMembershipNFT public membershipNFT;
    AngelNFTContract public investorNFT;

    address public owner;
    address public proposer;
    address public voter;

    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
    bytes32 public constant LEADERSHIP_ROLE = keccak256("LEADERSHIP_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    function setUp() public {
        owner = makeAddr("owner");
        proposer = makeAddr("proposer");
        voter = makeAddr("voter");

        vm.startPrank(owner);

        // Deploy migration proxy
        migrationProxy = new MigrationAndUpgradeProxy(owner);

        // Deploy BLTBYToken via proxy
        BLTBYToken tokenImplementation = new BLTBYToken();
        bytes memory tokenInitData = abi.encodeWithSignature("initialize(address)", owner);
        migrationProxy.deployProxy(address(tokenImplementation), tokenInitData, "BLTBYToken");
        bltbyToken = BLTBYToken(migrationProxy.getProxyAddress("BLTBYToken"));

        // Deploy NFT contracts (keeping them non-upgradeable for simplicity)
        membershipNFT = new GeneralMembershipNFT(owner);
        investorNFT = new AngelNFTContract(owner);

        // Deploy Governance via proxy
        Governance governanceImplementation = new Governance();
        bytes memory governanceInitData = abi.encodeWithSignature(
            "initialize(address,address,address,address)",
            address(bltbyToken),
            address(membershipNFT),
            address(investorNFT),
            owner
        );
        migrationProxy.deployProxy(address(governanceImplementation), governanceInitData, "Governance");
        governance = Governance(migrationProxy.getProxyAddress("Governance"));

        governance.grantRole(PROPOSER_ROLE, proposer);
        governance.grantRole(LEADERSHIP_ROLE, voter);

        membershipNFT.grantRole(MINTER_ROLE, owner);
        membershipNFT.mintGeneralMembershipNFT(voter, true);

        bltbyToken.transfer(proposer, 10 * 10 ** 18);
        vm.stopPrank();

        vm.prank(proposer);
        bltbyToken.approve(address(governance), 10 * 10 ** 18);
    }

    function testCreateProposal() public {
        vm.prank(proposer);
        governance.createProposal("Test proposal", 7 days, 0);

        (
            uint256 id,
            address creator,
            string memory description,
            ,
            ,
            uint8 category,
            bool resolved,
            bool vetoed,
            ,
            uint256 leadershipVotes
        ) = governance.proposals(1);

        assertEq(id, 1);
        assertEq(creator, proposer);
        assertEq(description, "Test proposal");
        assertEq(category, 0);
        assertFalse(resolved);
        assertFalse(vetoed);
        assertEq(leadershipVotes, 0);
        assertEq(governance.stakedBLTBY(proposer), 2 * 10 ** 18);
    }

    function testVoteOnProposal() public {
        vm.prank(proposer);
        governance.createProposal("Test proposal", 7 days, 0);

        vm.prank(voter);
        governance.vote(1, 1, 1);

        (,,,,,,,, uint256 totalVotes, uint256 leadershipVotes) = governance.proposals(1);

        assertEq(totalVotes, 1);
        assertEq(leadershipVotes, 1);
    }

    function testResolveProposal() public {
        vm.prank(proposer);
        governance.createProposal("Test proposal", 7 days, 0);

        vm.prank(voter);
        governance.vote(1, 1, 1);

        address voter2 = makeAddr("voter2");
        vm.prank(owner);
        governance.grantRole(LEADERSHIP_ROLE, voter2);

        vm.prank(owner);
        membershipNFT.mintGeneralMembershipNFT(voter2, true);

        vm.prank(voter2);
        governance.vote(1, 2, 1);

        vm.warp(block.timestamp + 8 days);

        governance.resolveProposal(1);

        (,,,,,, bool resolved,,,) = governance.proposals(1);

        assertTrue(resolved);
    }

    function testVetoProposal() public {
        vm.prank(proposer);
        governance.createProposal("Test proposal", 7 days, 0);

        vm.prank(owner);
        governance.grantRole(LEADERSHIP_ROLE, owner);

        vm.prank(owner);
        governance.vetoProposal(1);

        (,,,,,, bool resolved, bool vetoed,,) = governance.proposals(1);

        assertTrue(resolved);
        assertTrue(vetoed);
    }

    function testGovernanceUpgrade() public {
        // Create a proposal first to have some state
        vm.prank(proposer);
        governance.createProposal("Test proposal", 7 days, 0);

        // Store original state
        (uint256 id, address creator,,,,,,,,) = governance.proposals(1);

        // Deploy new implementation
        Governance newImplementation = new Governance();

        // Upgrade the governance proxy
        vm.prank(owner);
        migrationProxy.upgradeProxy("Governance", address(newImplementation));

        // Verify state is preserved after upgrade
        (uint256 newId, address newCreator,,,,,,,,) = governance.proposals(1);
        assertEq(newId, id);
        assertEq(newCreator, creator);
        assertEq(governance.proposalCounter(), 2);
    }

    function testCannotInitializeGovernanceTwice() public {
        vm.expectRevert();
        governance.initialize(address(bltbyToken), address(membershipNFT), address(investorNFT), owner);
    }
}
