// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/access/AccessControl.sol";
import "@openzeppelin/access/Ownable.sol";
import "@openzeppelin/utils/ReentrancyGuard.sol";

contract FramerNFT is
    ERC721URIStorage,
    AccessControl,
    Ownable,
    ReentrancyGuard
{
    uint256 private _tokenIdCounter;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Metadata attributes for governance rights and benefits
    struct FramerAttributes {
        bool isEarlyContributor;
        uint8 governanceWeight; // Weight assigned for governance decisions
        bool hasLifetimeBenefits; // Indicates lifetime rewards and benefits
    }

    // Mapping from token ID to framer attributes
    mapping(uint256 => FramerAttributes) public framerDetails;

    // Events for minting, burning, and assigning contributor roles
    event FramerNFTMinted(
        address indexed to,
        uint256 tokenId,
        bool isEarlyContributor
    );
    event FramerNFTBurned(uint256 tokenId);

    // Custom errors for efficient error handling
    error UnauthorizedAccess();
    error TokenNonExistent(uint256 tokenId);

    constructor(
        address initialOwner
    ) ERC721("Framer Membership", "FRMR") Ownable(initialOwner) {
        grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(MINTER_ROLE, msg.sender);
        _tokenIdCounter = 1; // Start token IDs at 1
    }

    /**
     * @dev Mint a new Framer NFT.
     * Only an address with the MINTER_ROLE can mint new tokens.
     * @param to The address that will receive the minted NFT.
     * @param isEarlyContributor True if the recipient is an early contributor, otherwise false.
     */
    function mintFramerNFT(
        address to,
        bool isEarlyContributor
    ) external onlyRole(MINTER_ROLE) nonReentrant {
        uint256 tokenId = _tokenIdCounter;
        _safeMint(to, tokenId);

        // Set URI for metadata (to be replaced with actual URI)
        _setTokenURI(tokenId, "https://metadata.uri/for/FramerNFT");

        // Set specific attributes for early contributors
        FramerAttributes memory attributes;
        attributes.isEarlyContributor = isEarlyContributor;
        attributes.governanceWeight = isEarlyContributor ? 2 : 1; // Early contributors get higher governance weight
        attributes.hasLifetimeBenefits = isEarlyContributor; // Early contributors have lifetime rewards
        framerDetails[tokenId] = attributes;

        _tokenIdCounter += 1;
        emit FramerNFTMinted(to, tokenId, isEarlyContributor);
    }

    /**
     * @dev Burn a Framer NFT.
     * Only the owner or admin can burn the NFT in cases of revocation, termination, or upgrades.
     * @param tokenId The ID of the token to be burned.
     */
    function burnFramerNFT(uint256 tokenId) external nonReentrant {
        if (
            ownerOf(tokenId) != msg.sender &&
            !hasRole(DEFAULT_ADMIN_ROLE, msg.sender)
        ) {
            revert UnauthorizedAccess();
        }
        _burn(tokenId);
        delete framerDetails[tokenId];
        emit FramerNFTBurned(tokenId);
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
        revert("Framer NFTs are non-transferable");
    }

    /**
     * @dev Check if a specific token ID belongs to an early contributor.
     * @param tokenId The ID of the token to check.
     * @return True if the token belongs to an early contributor, otherwise false.
     */
    function isEarlyContributor(uint256 tokenId) external view returns (bool) {
        return framerDetails[tokenId].isEarlyContributor;
    }

    /**
     * @dev Get the governance weight assigned to a specific token ID.
     * @param tokenId The ID of the token to check.
     * @return Governance weight for the token.
     */
    function getGovernanceWeight(
        uint256 tokenId
    ) external view returns (uint8) {
        return framerDetails[tokenId].governanceWeight;
    }

    /**
     * @dev Check if a specific token ID has lifetime benefits.
     * @param tokenId The ID of the token to check.
     * @return True if the token has lifetime benefits, otherwise false.
     */
    function hasLifetimeBenefits(uint256 tokenId) external view returns (bool) {
        return framerDetails[tokenId].hasLifetimeBenefits;
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
 - Separate contract for Framer NFTs, tailored for early contributors and key strategic partners.
 - Minting restricted to addresses with the MINTER_ROLE, typically DAO administrators.
 - Soul-bound: NFTs are non-transferable, but can be burned by the owner or admin under specific conditions.
 - Early contributors receive special privileges: higher governance weight and lifetime benefits.
 - Interoperability: Designed for integration with the Governance Contract to determine voting rights and influence within the DAO ecosystem.
 - Improved error handling with custom errors for more efficient gas usage.
 - Reentrancy guard applied for security in minting and burning operations.
*/
