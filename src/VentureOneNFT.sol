// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract VentureOneNFTContract is
    ERC721URIStorage,
    AccessControl,
    Ownable,
    ReentrancyGuard
{
    uint256 private _tokenIdCounter;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Metadata attributes for Venture One investors
    struct VentureOneAttributes {
        bool isVentureRoundOne; // Indicates if the holder is part of the first venture round
        uint8 governanceWeight; // Governance weight for DAO decision making
        uint256 discountRate; // Discount rate for future BLTBY token purchases
    }

    // Mapping from token ID to Venture One attributes
    mapping(uint256 => VentureOneAttributes) public ventureOneDetails;

    // Events for minting, burning, and assigning venture one attributes
    event VentureOneNFTMinted(
        address indexed to,
        uint256 tokenId,
        bool isVentureRoundOne
    );
    event VentureOneNFTBurned(uint256 tokenId);

    // Custom errors for efficient error handling
    error UnauthorizedAccess();
    error TokenNonExistent(uint256 tokenId);

    constructor() ERC721("Venture One Membership", "V1NFT") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _tokenIdCounter = 1; // Start token IDs at 1
    }

    /**
     * @dev Mint a new Venture One NFT.
     * Only an address with the MINTER_ROLE can mint new tokens.
     * @param to The address that will receive the minted NFT.
     * @param isVentureRoundOne True if the recipient is part of the first venture round, otherwise false.
     */
    function mintVentureOneNFT(
        address to,
        bool isVentureRoundOne
    ) external onlyRole(MINTER_ROLE) nonReentrant {
        uint256 tokenId = _tokenIdCounter;
        _safeMint(to, tokenId);

        // Set URI for metadata (to be replaced with actual URI)
        _setTokenURI(tokenId, "https://metadata.uri/for/VentureOneNFT");

        // Set specific attributes for venture round one investors
        VentureOneAttributes memory attributes;
        attributes.isVentureRoundOne = isVentureRoundOne;
        attributes.governanceWeight = isVentureRoundOne ? 4 : 2; // Venture round one investors get higher governance weight
        attributes.discountRate = isVentureRoundOne ? 20 : 10; // Discount rate for BLTBY token purchases
        ventureOneDetails[tokenId] = attributes;

        _tokenIdCounter += 1;
        emit VentureOneNFTMinted(to, tokenId, isVentureRoundOne);
    }

    /**
     * @dev Burn a Venture One NFT.
     * Only the owner or admin can burn the NFT in cases of revocation, termination, or upgrades.
     * @param tokenId The ID of the token to be burned.
     */
    function burnVentureOneNFT(uint256 tokenId) external nonReentrant {
        if (
            ownerOf(tokenId) != msg.sender &&
            !hasRole(DEFAULT_ADMIN_ROLE, msg.sender)
        ) {
            revert UnauthorizedAccess();
        }
        _burn(tokenId);
        delete ventureOneDetails[tokenId];
        emit VentureOneNFTBurned(tokenId);
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
        revert("Venture One NFTs are non-transferable");
    }

    /**
     * @dev Check if a specific token ID belongs to a Venture Round One investor.
     * @param tokenId The ID of the token to check.
     * @return True if the token belongs to a Venture Round One investor, otherwise false.
     */
    function isVentureRoundOne(uint256 tokenId) external view returns (bool) {
        if (!_exists(tokenId)) {
            revert TokenNonExistent(tokenId);
        }
        return ventureOneDetails[tokenId].isVentureRoundOne;
    }

    /**
     * @dev Get the governance weight assigned to a specific token ID.
     * @param tokenId The ID of the token to check.
     * @return Governance weight for the token.
     */
    function getGovernanceWeight(
        uint256 tokenId
    ) external view returns (uint8) {
        if (!_exists(tokenId)) {
            revert TokenNonExistent(tokenId);
        }
        return ventureOneDetails[tokenId].governanceWeight;
    }

    /**
     * @dev Get the discount rate assigned to a specific token ID for future BLTBY token purchases.
     * @param tokenId The ID of the token to check.
     * @return Discount rate for the token.
     */
    function getDiscountRate(uint256 tokenId) external view returns (uint256) {
        if (!_exists(tokenId)) {
            revert TokenNonExistent(tokenId);
        }
        return ventureOneDetails[tokenId].discountRate;
    }
}

/*
 Key Features:
 - Separate contract for Venture One (V1) NFTs, tailored for first-round venture capital investors.
 - Minting restricted to addresses with the MINTER_ROLE, typically DAO administrators.
 - Soul-bound: NFTs are non-transferable, but can be burned by the owner or admin under specific conditions.
 - Venture round one investors receive special privileges: higher governance weight and a greater discount rate for future BLTBY token purchases.
 - Interoperability: Designed for integration with the Governance Contract to determine voting rights and influence within the DAO ecosystem.
 - Improved error handling with custom errors for more efficient gas usage.
 - Reentrancy guard applied for security in minting and burning operations.
*/
