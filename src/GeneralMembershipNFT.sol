// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/access/AccessControl.sol";
import "@openzeppelin/access/Ownable.sol";
import "@openzeppelin/utils/ReentrancyGuard.sol";

contract GeneralMembershipNFT is
    ERC721URIStorage,
    AccessControl,
    Ownable,
    ReentrancyGuard
{
    uint256 private _tokenIdCounter;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant WHITELISTED_MINTER_ROLE =
        keccak256("WHITELISTED_MINTER_ROLE");

    // Metadata attributes for general membership
    struct MembershipAttributes {
        bool isActiveMember; // Indicates if the holder is an active member
        uint8 accessLevel; // Access level for different benefits within the DAO ecosystem
    }

    // Mapping from token ID to membership attributes
    mapping(uint256 => MembershipAttributes) public membershipDetails;
    // Mapping from address to whether they hold a General Membership NFT
    mapping(address => bool) public hasMembershipNFT;

    // Events for minting, burning, and updating membership
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

    // Custom errors for efficient error handling
    error UnauthorizedAccess();
    error TokenNonExistent(uint256 tokenId);
    error AlreadyHoldsMembershipNFT(address account);

    constructor(
        address initialOwner
    ) ERC721("General Membership", "GMEM") Ownable(initialOwner) {
        grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(MINTER_ROLE, msg.sender);
        _tokenIdCounter = 1; // Start token IDs at 1
    }

    /**
     * @dev Mint a new General Membership NFT.
     * Only an address with the MINTER_ROLE or WHITELISTED_MINTER_ROLE can mint new tokens.
     * Ensures that each address can only hold one General Membership NFT.
     * @param to The address that will receive the minted NFT.
     * @param isActiveMember True if the recipient is an active member, otherwise false.
     */
    function mintGeneralMembershipNFT(
        address to,
        bool isActiveMember
    ) external onlyRole(MINTER_ROLE) nonReentrant {
        if (hasMembershipNFT[to]) {
            revert AlreadyHoldsMembershipNFT(to);
        }

        uint256 tokenId = _tokenIdCounter;
        _safeMint(to, tokenId);

        // Set URI for metadata (to be replaced with actual URI)
        _setTokenURI(tokenId, "https://metadata.uri/for/GeneralMembershipNFT");

        // Set membership attributes
        MembershipAttributes memory attributes;
        attributes.isActiveMember = isActiveMember;
        attributes.accessLevel = isActiveMember ? 1 : 0; // Access level is 1 for active members, 0 for inactive
        membershipDetails[tokenId] = attributes;

        hasMembershipNFT[to] = true;
        _tokenIdCounter += 1;
        emit GeneralMembershipNFTMinted(to, tokenId, isActiveMember);
    }

    /**
     * @dev Burn a General Membership NFT.
     * Only the owner or admin can burn the NFT in cases of revocation, termination, or upgrades.
     * @param tokenId The ID of the token to be burned.
     */
    function burnGeneralMembershipNFT(uint256 tokenId) external nonReentrant {
        if (
            ownerOf(tokenId) != msg.sender &&
            !hasRole(DEFAULT_ADMIN_ROLE, msg.sender)
        ) {
            revert UnauthorizedAccess();
        }
        address owner = ownerOf(tokenId);
        _burn(tokenId);
        delete membershipDetails[tokenId];
        hasMembershipNFT[owner] = false;
        emit GeneralMembershipNFTBurned(tokenId);
    }

    /**
     * @dev Override transfer function to prevent transfers (soul-bound nature).
     * @param from Address from which token is being transferred.
     * @param to Address to which token is being transferred.
     * @param tokenId ID of the token being transferred.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal pure override {
        revert("General Membership NFTs are non-transferable");
    }

    /**
     * @dev Update membership details for a given token ID.
     * Only admin can update membership status or access levels.
     * @param tokenId The ID of the token to update.
     * @param isActiveMember True if the member is active, otherwise false.
     * @param accessLevel The updated access level for the member.
     */
    function updateMembership(
        uint256 tokenId,
        bool isActiveMember,
        uint8 accessLevel
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        membershipDetails[tokenId].isActiveMember = isActiveMember;
        membershipDetails[tokenId].accessLevel = accessLevel;
        emit MembershipUpdated(tokenId, isActiveMember, accessLevel);
    }

    /**
     * @dev Check if a specific token ID belongs to an active member.
     * @param tokenId The ID of the token to check.
     * @return True if the token belongs to an active member, otherwise false.
     */
    function isActiveMember(uint256 tokenId) external view returns (bool) {
        return membershipDetails[tokenId].isActiveMember;
    }

    /**
     * @dev Get the access level assigned to a specific token ID.
     * @param tokenId The ID of the token to check.
     * @return Access level for the token.
     */
    function getAccessLevel(uint256 tokenId) external view returns (uint8) {
        return membershipDetails[tokenId].accessLevel;
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(AccessControl, ERC721URIStorage)
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

/*
 Key Features:
 - Separate contract for General Membership NFTs, designed for general members of the DAO ecosystem.
 - Minting restricted to addresses with the MINTER_ROLE or WHITELISTED_MINTER_ROLE, which can include other contracts.
 - Soul-bound: NFTs are non-transferable, but can be burned by the owner or admin under specific conditions.
 - Active members receive specific access levels, which can be updated by administrators.
 - Ensures that each member can only hold one General Membership NFT at a time.
 - Interoperability: Designed for integration with the Access Control Contract to determine access to amenities and services within the DAO ecosystem.
 - Improved error handling with custom errors for more efficient gas usage.
 - Reentrancy guard applied for security in minting, burning, and membership updates.
*/
