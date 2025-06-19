// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/access/AccessControl.sol";
import "@openzeppelin/access/Ownable.sol";
import "@openzeppelin/utils/ReentrancyGuard.sol";

contract LeadershipCouncilNFT is
    ERC721URIStorage,
    AccessControl,
    Ownable,
    ReentrancyGuard
{
    uint256 private _tokenIdCounter;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant FOUNDER_DIRECTOR_ROLE =
        keccak256("FOUNDER_DIRECTOR_ROLE");

    // Metadata attributes for super-admin rights
    struct LeadershipAttributes {
        bool isFounderDirector;
        uint8 extraVotes; // Extra votes for tie-breaking and special privileges
        bool hasVetoPower; // Indicates veto rights
    }

    // Mapping from token ID to leadership attributes
    mapping(uint256 => LeadershipAttributes) public leadershipDetails;

    // Events for minting, burning, and assigning founder roles
    event LeadershipCouncilMinted(
        address indexed to,
        uint256 tokenId,
        bool isFounderDirector
    );
    event LeadershipCouncilBurned(uint256 tokenId);

    error UnauthorizedAccess();
    error TokenNonExistent(uint256 tokenId);

    constructor(
        address initialOwner
    ) ERC721("Leadership Council Membership", "LDCN") Ownable(initialOwner) {
        grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(MINTER_ROLE, msg.sender);
        _tokenIdCounter = 1; // Start token IDs at 1
    }

    /**
     * @dev Mint a new Leadership Council NFT.
     * Only an address with the MINTER_ROLE can mint new tokens.
     * @param to The address that will receive the minted NFT.
     * @param isFounderDirector True if the recipient is a Founder Director, otherwise false.
     */
    function mintLeadershipNFT(
        address to,
        bool isFounderDirector
    ) external onlyRole(MINTER_ROLE) nonReentrant {
        uint256 tokenId = _tokenIdCounter;
        _safeMint(to, tokenId);

        // Set URI for metadata (to be replaced with actual URI)
        _setTokenURI(tokenId, "https://metadata.uri/for/LeadershipCouncilNFT");

        // Set specific attributes for Founder Directors
        LeadershipAttributes memory attributes;
        attributes.isFounderDirector = isFounderDirector;
        attributes.extraVotes = isFounderDirector ? 3 : 0; // Founder Directors get 3 extra votes
        attributes.hasVetoPower = isFounderDirector; // Founder Directors have veto rights
        leadershipDetails[tokenId] = attributes;

        _tokenIdCounter += 1;
        emit LeadershipCouncilMinted(to, tokenId, isFounderDirector);
    }

    /**
     * @dev Burn a Leadership Council NFT.
     * Only the owner or admin can burn the NFT in cases of revocation, termination, or upgrades.
     * @param tokenId The ID of the token to be burned.
     */
    function burnLeadershipNFT(uint256 tokenId) external nonReentrant {
        if (
            ownerOf(tokenId) != msg.sender &&
            !hasRole(DEFAULT_ADMIN_ROLE, msg.sender)
        ) {
            revert UnauthorizedAccess();
        }
        _burn(tokenId);
        delete leadershipDetails[tokenId];
        emit LeadershipCouncilBurned(tokenId);
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
        revert("Leadership Council NFTs are non-transferable");
    }

    /**
     * @dev Check if a specific token ID belongs to a Founder Director.
     * @param tokenId The ID of the token to check.
     * @return True if the token belongs to a Founder Director, otherwise false.
     */
    function isFounderDirector(uint256 tokenId) external view returns (bool) {
        return leadershipDetails[tokenId].isFounderDirector;
    }

    /**
     * @dev Get the number of extra votes assigned to a specific token ID.
     * @param tokenId The ID of the token to check.
     * @return Number of extra votes for the token.
     */
    function getExtraVotes(uint256 tokenId) external view returns (uint8) {
        return leadershipDetails[tokenId].extraVotes;
    }

    /**
     * @dev Check if a specific token ID has veto power.
     * @param tokenId The ID of the token to check.
     * @return True if the token has veto power, otherwise false.
     */
    function hasVetoPower(uint256 tokenId) external view returns (bool) {
        return leadershipDetails[tokenId].hasVetoPower;
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
 - Separate contract for Leadership Council NFTs.
 - Minting restricted to addresses with the MINTER_ROLE, typically DAO administrators.
 - Soul-bound: NFTs are non-transferable, but can be burned by the owner or admin under specific conditions.
 - Founder Directors receive special privileges: extra votes, veto rights, and are assigned via metadata.
 - Interoperability: Direct integration with the Governance Contract to determine voting rights and influence within the DAO ecosystem.
 - Improved error handling with custom errors for more efficient gas usage.
 - Reentrancy guard applied for security in minting and burning operations.
*/
