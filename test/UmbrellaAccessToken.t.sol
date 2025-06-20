// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import "../src/UmbrellaAccessToken.sol";

contract MockSubContract {
    string public name;
    string public symbol;
    address public admin;
    uint256 public duration;
    uint8 public tokenType;
    bool public initialized;

    function initialize(string memory _name, string memory _symbol, address _admin, uint256 _duration, uint8 _tokenType)
        external
    {
        name = _name;
        symbol = _symbol;
        admin = _admin;
        duration = _duration;
        tokenType = _tokenType;
        initialized = true;
    }
}

contract UmbrellaAccessTokenTest is Test {
    UmbrellaAccessTokenContract public umbrellaToken;
    MockSubContract public template;
    address public owner;
    address public admin;
    address public reviewer;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant REVIEWER_ROLE = keccak256("REVIEWER_ROLE");

    function setUp() public {
        owner = makeAddr("owner");
        admin = makeAddr("admin");
        reviewer = makeAddr("reviewer");

        template = new MockSubContract();

        vm.startPrank(owner);
        umbrellaToken = new UmbrellaAccessTokenContract(address(template), admin, reviewer);
        vm.stopPrank();
    }

    function testCreateSubContract() public {
        vm.prank(admin);
        umbrellaToken.createSubContract("Gym Access", "GYM", 30 days, 0);

        (address contractAddress, string memory name, uint256 createdAt, uint8 tokenType, bool approved) =
            umbrellaToken.subContracts(0);

        assertTrue(contractAddress != address(0));
        assertEq(name, "Gym Access");
        assertEq(tokenType, 0);
        assertFalse(approved);
        assertTrue(umbrellaToken.existingSubContracts(contractAddress));
    }

    function testApproveSubContract() public {
        vm.prank(admin);
        umbrellaToken.createSubContract("Event Access", "EVENT", 7 days, 1);

        vm.prank(reviewer);
        umbrellaToken.approveSubContract(0);

        (address contractAddress,,,, bool approved) = umbrellaToken.subContracts(0);

        assertTrue(approved);
        assertTrue(umbrellaToken.isSubContractApproved(contractAddress));
    }

    function testIsSubContractApproved() public {
        vm.prank(admin);
        umbrellaToken.createSubContract("Seminar Access", "SEM", 1 days, 2);

        (address contractAddress,,,,) = umbrellaToken.subContracts(0);

        assertFalse(umbrellaToken.isSubContractApproved(contractAddress));

        vm.prank(reviewer);
        umbrellaToken.approveSubContract(0);

        assertTrue(umbrellaToken.isSubContractApproved(contractAddress));
    }

    function testOnlyAdminCanCreateSubContract() public {
        address nonAdmin = makeAddr("nonAdmin");

        vm.prank(nonAdmin);
        vm.expectRevert();
        umbrellaToken.createSubContract("Test", "TEST", 1 days, 0);
    }

    function testOnlyReviewerCanApproveSubContract() public {
        vm.prank(admin);
        umbrellaToken.createSubContract("Test", "TEST", 1 days, 0);

        address nonReviewer = makeAddr("nonReviewer");

        vm.prank(nonReviewer);
        vm.expectRevert();
        umbrellaToken.approveSubContract(0);
    }
}
