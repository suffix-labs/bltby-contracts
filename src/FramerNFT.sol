// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/token/ERC721/ERC721.sol";
import "@openzeppelin/access/AccessControl.sol";

contract FramerNFT is ERC721, AccessControl {
    uint256 private _tokenIdCounter;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Packed struct to reduce storage slots
    struct FramerAttributes {
        bool isEarlyContributor;
        uint8 governanceWeight;
        bool hasLifetimeBenefits;
    }

    mapping(uint256 => FramerAttributes) public framerDetails;

    event FramerNFTMinted(address indexed to, uint256 tokenId, bool isEarlyContributor);
    event FramerNFTBurned(uint256 tokenId);

    error UnauthorizedAccess();

    constructor(address initialOwner) ERC721("Framer Membership", "FRMR") {
        _grantRole(DEFAULT_ADMIN_ROLE, initialOwner);
        _grantRole(MINTER_ROLE, initialOwner);
        _tokenIdCounter = 1;
    }

    function mintFramerNFT(address to, bool _isEarlyContributor) external onlyRole(MINTER_ROLE) {
        uint256 tokenId = _tokenIdCounter++;
        _safeMint(to, tokenId);
        
        _setFramerAttributes(tokenId, _isEarlyContributor);
        emit FramerNFTMinted(to, tokenId, _isEarlyContributor);
    }

    function _setFramerAttributes(uint256 tokenId, bool _isEarlyContributor) private {
        framerDetails[tokenId] = FramerAttributes({
            isEarlyContributor: _isEarlyContributor,
            governanceWeight: _isEarlyContributor ? 2 : 1,
            hasLifetimeBenefits: _isEarlyContributor
        });
    }

    function burnFramerNFT(uint256 tokenId) external {
        address owner = ownerOf(tokenId);
        if (owner != msg.sender && !hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert UnauthorizedAccess();
        }
        _burn(tokenId);
        delete framerDetails[tokenId];
        emit FramerNFTBurned(tokenId);
    }


    function isEarlyContributor(uint256 tokenId) external view returns (bool) {
        return framerDetails[tokenId].isEarlyContributor;
    }

    function getGovernanceWeight(uint256 tokenId) external view returns (uint8) {
        return framerDetails[tokenId].governanceWeight;
    }

    function hasLifetimeBenefits(uint256 tokenId) external view returns (bool) {
        return framerDetails[tokenId].hasLifetimeBenefits;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}