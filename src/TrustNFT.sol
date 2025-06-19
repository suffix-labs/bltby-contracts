// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/token/ERC721/ERC721.sol";
import "@openzeppelin/access/AccessControl.sol";

contract TrustNFTContract is ERC721, AccessControl {
    uint256 private _tokenIdCounter;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Packed struct to reduce storage slots
    struct TrustAttributes {
        bool isInstitutionalInvestor;
        uint8 governanceWeight;
        uint8 investmentBenefitRate; // Changed from uint256 to uint8 for values 0-255
    }

    mapping(uint256 => TrustAttributes) public trustDetails;

    event TrustNFTMinted(address indexed to, uint256 tokenId, bool isInstitutionalInvestor);
    event TrustNFTBurned(uint256 tokenId);

    error UnauthorizedAccess();

    constructor(address initialOwner) ERC721("Trust Membership", "TRUST") {
        _grantRole(DEFAULT_ADMIN_ROLE, initialOwner);
        _grantRole(MINTER_ROLE, initialOwner);
        _tokenIdCounter = 1;
    }

    function mintTrustNFT(address to, bool _isInstitutionalInvestor) external onlyRole(MINTER_ROLE) {
        uint256 tokenId = _tokenIdCounter++;
        _safeMint(to, tokenId);
        
        _setTrustAttributes(tokenId, _isInstitutionalInvestor);
        emit TrustNFTMinted(to, tokenId, _isInstitutionalInvestor);
    }

    function _setTrustAttributes(uint256 tokenId, bool _isInstitutionalInvestor) private {
        trustDetails[tokenId] = TrustAttributes({
            isInstitutionalInvestor: _isInstitutionalInvestor,
            governanceWeight: _isInstitutionalInvestor ? 5 : 3,
            investmentBenefitRate: _isInstitutionalInvestor ? 25 : 15
        });
    }

    function burnTrustNFT(uint256 tokenId) external {
        address owner = ownerOf(tokenId);
        if (owner != msg.sender && !hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert UnauthorizedAccess();
        }
        _burn(tokenId);
        delete trustDetails[tokenId];
        emit TrustNFTBurned(tokenId);
    }


    function isInstitutionalInvestor(uint256 tokenId) external view returns (bool) {
        return trustDetails[tokenId].isInstitutionalInvestor;
    }

    function getGovernanceWeight(uint256 tokenId) external view returns (uint8) {
        return trustDetails[tokenId].governanceWeight;
    }

    function getInvestmentBenefitRate(uint256 tokenId) external view returns (uint8) {
        return trustDetails[tokenId].investmentBenefitRate;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}