// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/access/AccessControl.sol";
import "@openzeppelin/access/Ownable.sol";
import "@openzeppelin/utils/ReentrancyGuard.sol";

contract AngelNFTContract is
    ERC721URIStorage,
    AccessControl,
    Ownable,
    ReentrancyGuard
{
    uint256 private _tokenIdCounter;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Metadata attributes for angel investors
    struct AngelAttributes {
        bool hasEarlyInvestorPrivileges;
        uint8 governanceWeight; // Governance weight for DAO decision making
        uint256 discountRate; // Discount rate for future BLTBY token purchases
    }

    // Mapping from token ID to angel attributes
    mapping(uint256 => AngelAttributes) public angelDetails;

    // Events for minting, burning, and assigning angel attributes
    event AngelNFTMinted(
        address indexed to,
        uint256 tokenId,
        bool hasEarlyInvestorPrivileges
    );
    event AngelNFTBurned(uint256 tokenId);

    // Custom errors for efficient error handling
    error UnauthorizedAccess();
    error TokenNonExistent(uint256 tokenId);

    constructor(
        address initialOwner
    ) ERC721("Angel Membership", "ANGL") Ownable(initialOwner) {
        grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(MINTER_ROLE, msg.sender);
        _tokenIdCounter = 1; // Start token IDs at 1
    }

    /**
     * @dev Mint a new Angel NFT.
     * Only an address with the MINTER_ROLE can mint new tokens.
     * @param to The address that will receive the minted NFT.
     * @param hasEarlyInvestorPrivileges True if the recipient is an early investor, otherwise false.
     */
    function mintAngelNFT(
        address to,
        bool hasEarlyInvestorPrivileges
    ) external onlyRole(MINTER_ROLE) nonReentrant {
        uint256 tokenId = _tokenIdCounter;
        _safeMint(to, tokenId);

        // Set URI for metadata (to be replaced with actual URI)
        _setTokenURI(tokenId, "https://metadata.uri/for/AngelNFT");

        // Set specific attributes for early investors
        AngelAttributes memory attributes;
        attributes.hasEarlyInvestorPrivileges = hasEarlyInvestorPrivileges;
        attributes.governanceWeight = hasEarlyInvestorPrivileges ? 3 : 1; // Early investors get higher governance weight
        attributes.discountRate = hasEarlyInvestorPrivileges ? 15 : 10; // Discount rate for BLTBY token purchases
        angelDetails[tokenId] = attributes;

        _tokenIdCounter += 1;
        emit AngelNFTMinted(to, tokenId, hasEarlyInvestorPrivileges);
    }

    /**
     * @dev Burn an Angel NFT.
     * Only the owner or admin can burn the NFT in cases of revocation, termination, or upgrades.
     * @param tokenId The ID of the token to be burned.
     */
    function burnAngelNFT(uint256 tokenId) external nonReentrant {
        if (
            ownerOf(tokenId) != msg.sender &&
            !hasRole(DEFAULT_ADMIN_ROLE, msg.sender)
        ) {
            revert UnauthorizedAccess();
        }
        _burn(tokenId);
        delete angelDetails[tokenId];
        emit AngelNFTBurned(tokenId);
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
        revert("Angel NFTs are non-transferable");
    }

    /**
     * @dev Check if a specific token ID has early investor privileges.
     * @param tokenId The ID of the token to check.
     * @return True if the token has early investor privileges, otherwise false.
     */
    function hasEarlyInvestorPrivileges(
        uint256 tokenId
    ) external view returns (bool) {
        return angelDetails[tokenId].hasEarlyInvestorPrivileges;
    }

    /**
     * @dev Get the governance weight assigned to a specific token ID.
     * @param tokenId The ID of the token to check.
     * @return Governance weight for the token.
     */
    function getGovernanceWeight(
        uint256 tokenId
    ) external view returns (uint8) {
        return angelDetails[tokenId].governanceWeight;
    }

    /**
     * @dev Get the discount rate assigned to a specific token ID for future BLTBY token purchases.
     * @param tokenId The ID of the token to check.
     * @return Discount rate for the token.
     */
    function getDiscountRate(uint256 tokenId) external view returns (uint256) {
        return angelDetails[tokenId].discountRate;
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
 - Separate contract for Angel NFTs, tailored for angel investors with specific investment benefits.
 - Minting restricted to addresses with the MINTER_ROLE, typically DAO administrators.
 - Soul-bound: NFTs are non-transferable, but can be burned by the owner or admin under specific conditions.
 - Early investors receive special privileges: higher governance weight and a greater discount rate for future BLTBY token purchases.
 - Interoperability: Designed for integration with the Governance Contract to determine voting rights and influence within the DAO ecosystem.
 - Improved error handling with custom errors for more efficient gas usage.
 - Reentrancy guard applied for security in minting and burning operations.
*/
