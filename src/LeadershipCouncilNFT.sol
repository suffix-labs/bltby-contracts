// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract LeadershipCouncilNFT is ERC721, AccessControl {
    uint256 private _tokenIdCounter;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Packed struct to reduce storage slots
    struct LeadershipAttributes {
        bool isFounderDirector;
        uint8 extraVotes;
        bool hasVetoPower;
    }

    mapping(uint256 => LeadershipAttributes) public leadershipDetails;

    event LeadershipCouncilMinted(
        address indexed to,
        uint256 tokenId,
        bool isFounderDirector
    );
    event LeadershipCouncilBurned(uint256 tokenId);

    error UnauthorizedAccess();

    constructor(
        address initialOwner
    ) ERC721("Leadership Council Membership", "LDCN") {
        _grantRole(DEFAULT_ADMIN_ROLE, initialOwner);
        _grantRole(MINTER_ROLE, initialOwner);
        _tokenIdCounter = 1;
    }

    function mintLeadershipNFT(
        address to,
        bool _isFounderDirector
    ) external onlyRole(MINTER_ROLE) {
        uint256 tokenId = _tokenIdCounter++;
        _safeMint(to, tokenId);

        _setLeadershipAttributes(tokenId, _isFounderDirector);
        emit LeadershipCouncilMinted(to, tokenId, _isFounderDirector);
    }

    function _setLeadershipAttributes(
        uint256 tokenId,
        bool _isFounderDirector
    ) private {
        leadershipDetails[tokenId] = LeadershipAttributes({
            isFounderDirector: _isFounderDirector,
            extraVotes: _isFounderDirector ? 3 : 0,
            hasVetoPower: _isFounderDirector
        });
    }

    function burnLeadershipNFT(uint256 tokenId) external {
        address owner = ownerOf(tokenId);
        if (owner != msg.sender && !hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert UnauthorizedAccess();
        }
        _burn(tokenId);
        delete leadershipDetails[tokenId];
        emit LeadershipCouncilBurned(tokenId);
    }

    function isFounderDirector(uint256 tokenId) external view returns (bool) {
        return leadershipDetails[tokenId].isFounderDirector;
    }

    function getExtraVotes(uint256 tokenId) external view returns (uint8) {
        return leadershipDetails[tokenId].extraVotes;
    }

    function hasVetoPower(uint256 tokenId) external view returns (bool) {
        return leadershipDetails[tokenId].hasVetoPower;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(AccessControl, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
