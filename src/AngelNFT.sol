// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/token/ERC721/ERC721.sol";
import "@openzeppelin/access/AccessControl.sol";

contract AngelNFTContract is ERC721, AccessControl {
    uint256 private _tokenIdCounter;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Packed struct to reduce storage slots
    struct AngelAttributes {
        bool hasEarlyInvestorPrivileges;
        uint8 governanceWeight;
        uint8 discountRate; // Changed from uint256 to uint8 for values 0-255
    }

    mapping(uint256 => AngelAttributes) public angelDetails;

    event AngelNFTMinted(address indexed to, uint256 tokenId, bool hasEarlyInvestorPrivileges);
    event AngelNFTBurned(uint256 tokenId);

    error UnauthorizedAccess();

    constructor(address initialOwner) ERC721("Angel Membership", "ANGL") {
        _grantRole(DEFAULT_ADMIN_ROLE, initialOwner);
        _grantRole(MINTER_ROLE, initialOwner);
        _tokenIdCounter = 1;
    }

    function mintAngelNFT(address to, bool _hasEarlyInvestorPrivileges) external onlyRole(MINTER_ROLE) {
        uint256 tokenId = _tokenIdCounter++;
        _safeMint(to, tokenId);
        
        _setAngelAttributes(tokenId, _hasEarlyInvestorPrivileges);
        emit AngelNFTMinted(to, tokenId, _hasEarlyInvestorPrivileges);
    }

    function _setAngelAttributes(uint256 tokenId, bool _hasEarlyInvestorPrivileges) private {
        angelDetails[tokenId] = AngelAttributes({
            hasEarlyInvestorPrivileges: _hasEarlyInvestorPrivileges,
            governanceWeight: _hasEarlyInvestorPrivileges ? 3 : 1,
            discountRate: _hasEarlyInvestorPrivileges ? 15 : 10
        });
    }

    function burnAngelNFT(uint256 tokenId) external {
        address owner = ownerOf(tokenId);
        if (owner != msg.sender && !hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert UnauthorizedAccess();
        }
        _burn(tokenId);
        delete angelDetails[tokenId];
        emit AngelNFTBurned(tokenId);
    }


    function hasEarlyInvestorPrivileges(uint256 tokenId) external view returns (bool) {
        return angelDetails[tokenId].hasEarlyInvestorPrivileges;
    }

    function getGovernanceWeight(uint256 tokenId) external view returns (uint8) {
        return angelDetails[tokenId].governanceWeight;
    }

    function getDiscountRate(uint256 tokenId) external view returns (uint8) {
        return angelDetails[tokenId].discountRate;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}