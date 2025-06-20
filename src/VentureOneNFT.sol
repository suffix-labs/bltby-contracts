// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract VentureOneNFTContract is ERC721, AccessControl {
    uint256 private _tokenIdCounter;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Packed struct to reduce storage slots
    struct VentureOneAttributes {
        bool isVentureRoundOne;
        uint8 governanceWeight;
        uint8 discountRate; // Changed from uint256 to uint8 for values 0-255
    }

    mapping(uint256 => VentureOneAttributes) public ventureOneDetails;

    event VentureOneNFTMinted(address indexed to, uint256 tokenId, bool isVentureRoundOne);
    event VentureOneNFTBurned(uint256 tokenId);

    error UnauthorizedAccess();

    constructor(address initialOwner) ERC721("Venture One Membership", "V1NFT") {
        _grantRole(DEFAULT_ADMIN_ROLE, initialOwner);
        _grantRole(MINTER_ROLE, initialOwner);
        _tokenIdCounter = 1;
    }

    function mintVentureOneNFT(address to, bool _isVentureRoundOne) external onlyRole(MINTER_ROLE) {
        uint256 tokenId = _tokenIdCounter++;
        _safeMint(to, tokenId);

        _setVentureOneAttributes(tokenId, _isVentureRoundOne);
        emit VentureOneNFTMinted(to, tokenId, _isVentureRoundOne);
    }

    function _setVentureOneAttributes(uint256 tokenId, bool _isVentureRoundOne) private {
        ventureOneDetails[tokenId] = VentureOneAttributes({
            isVentureRoundOne: _isVentureRoundOne,
            governanceWeight: _isVentureRoundOne ? 4 : 2,
            discountRate: _isVentureRoundOne ? 20 : 10
        });
    }

    function burnVentureOneNFT(uint256 tokenId) external {
        address owner = ownerOf(tokenId);
        if (owner != msg.sender && !hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert UnauthorizedAccess();
        }
        _burn(tokenId);
        delete ventureOneDetails[tokenId];
        emit VentureOneNFTBurned(tokenId);
    }

    function isVentureRoundOne(uint256 tokenId) external view returns (bool) {
        return ventureOneDetails[tokenId].isVentureRoundOne;
    }

    function getGovernanceWeight(uint256 tokenId) external view returns (uint8) {
        return ventureOneDetails[tokenId].governanceWeight;
    }

    function getDiscountRate(uint256 tokenId) external view returns (uint8) {
        return ventureOneDetails[tokenId].discountRate;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
