// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import "../src/TrustNFT.sol";

contract TrustNFTTest is Test {
    TrustNFTContract public trustNFT;
    address public owner;
    address public minter;
    address public recipient;
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    function setUp() public {
        owner = makeAddr("owner");
        minter = makeAddr("minter");
        recipient = makeAddr("recipient");
        
        vm.startPrank(owner);
        trustNFT = new TrustNFTContract(owner);
        trustNFT.grantRole(MINTER_ROLE, minter);
        vm.stopPrank();
    }

    function testMintTrustNFTInstitutionalInvestor() public {
        vm.prank(minter);
        trustNFT.mintTrustNFT(recipient, true);
        
        assertEq(trustNFT.ownerOf(1), recipient);
        assertTrue(trustNFT.isInstitutionalInvestor(1));
        assertEq(trustNFT.getGovernanceWeight(1), 5);
        assertEq(trustNFT.getInvestmentBenefitRate(1), 25);
    }

    function testMintTrustNFTNonInstitutionalInvestor() public {
        vm.prank(minter);
        trustNFT.mintTrustNFT(recipient, false);
        
        assertEq(trustNFT.ownerOf(1), recipient);
        assertFalse(trustNFT.isInstitutionalInvestor(1));
        assertEq(trustNFT.getGovernanceWeight(1), 3);
        assertEq(trustNFT.getInvestmentBenefitRate(1), 15);
    }

    function testBurnTrustNFTByOwner() public {
        vm.prank(minter);
        trustNFT.mintTrustNFT(recipient, true);
        
        vm.prank(recipient);
        trustNFT.burnTrustNFT(1);
        
        vm.expectRevert();
        trustNFT.ownerOf(1);
    }

    function testBurnTrustNFTByAdmin() public {
        vm.prank(minter);
        trustNFT.mintTrustNFT(recipient, true);
        
        vm.prank(owner);
        trustNFT.burnTrustNFT(1);
        
        vm.expectRevert();
        trustNFT.ownerOf(1);
    }


    function testSupportsInterface() public {
        assertTrue(trustNFT.supportsInterface(type(IERC165).interfaceId));
    }
}