// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract GeneralMembershipNFT is ERC721, AccessControl {
    uint256 private _tokenIdCounter;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Packed struct to reduce storage slots
    struct MembershipAttributes {
        bool isActiveMember;
        uint8 accessLevel;
    }

    mapping(uint256 => MembershipAttributes) public membershipDetails;
    mapping(address => bool) public hasMembershipNFT;

    event GeneralMembershipNFTMinted(
        address indexed to,
        uint256 tokenId,
        bool isActiveMember
    );
    event GeneralMembershipNFTBurned(uint256 tokenId);
    event MembershipUpdated(
        uint256 tokenId,
        bool isActiveMember,
        uint8 accessLevel
    );

    error UnauthorizedAccess();
    error AlreadyHoldsMembershipNFT(address account);

    constructor(address initialOwner) ERC721("General Membership", "GMEM") {
        _grantRole(DEFAULT_ADMIN_ROLE, initialOwner);
        _grantRole(MINTER_ROLE, initialOwner);
        _tokenIdCounter = 1;
    }

    function mintGeneralMembershipNFT(
        address to,
        bool _isActiveMember
    ) external onlyRole(MINTER_ROLE) {
        if (hasMembershipNFT[to]) {
            revert AlreadyHoldsMembershipNFT(to);
        }

        uint256 tokenId = _tokenIdCounter++;
        
        // Update state variables before external call to prevent reentrancy
        _setMembershipAttributes(tokenId, _isActiveMember);
        hasMembershipNFT[to] = true;
        
        _safeMint(to, tokenId);
        emit GeneralMembershipNFTMinted(to, tokenId, _isActiveMember);
    }

    function _setMembershipAttributes(
        uint256 tokenId,
        bool _isActiveMember
    ) private {
        membershipDetails[tokenId] = MembershipAttributes({
            isActiveMember: _isActiveMember,
            accessLevel: _isActiveMember ? 1 : 0
        });
    }

    function burnGeneralMembershipNFT(uint256 tokenId) external {
        address owner = ownerOf(tokenId);
        if (owner != msg.sender && !hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert UnauthorizedAccess();
        }
        _burn(tokenId);
        delete membershipDetails[tokenId];
        hasMembershipNFT[owner] = false;
        emit GeneralMembershipNFTBurned(tokenId);
    }

    function updateMembership(
        uint256 tokenId,
        bool _isActiveMember,
        uint8 _accessLevel
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        membershipDetails[tokenId].isActiveMember = _isActiveMember;
        membershipDetails[tokenId].accessLevel = _accessLevel;
        emit MembershipUpdated(tokenId, _isActiveMember, _accessLevel);
    }

    function isActiveMember(uint256 tokenId) external view returns (bool) {
        return membershipDetails[tokenId].isActiveMember;
    }

    function getAccessLevel(uint256 tokenId) external view returns (uint8) {
        return membershipDetails[tokenId].accessLevel;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(AccessControl, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
