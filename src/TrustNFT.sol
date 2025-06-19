// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/access/AccessControl.sol";
import "@openzeppelin/access/Ownable.sol";
import "@openzeppelin/utils/ReentrancyGuard.sol";

contract TrustNFTContract is
    ERC721URIStorage,
    AccessControl,
    Ownable,
    ReentrancyGuard
{
    uint256 private _tokenIdCounter;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Metadata attributes for Trust investors
    struct TrustAttributes {
        bool isInstitutionalInvestor; // Indicates if the holder is an institutional investor or a trust
        uint8 governanceWeight; // Governance weight for DAO decision making
        uint256 investmentBenefitRate; // Special investment benefit rate for future opportunities
    }

    // Mapping from token ID to Trust attributes
    mapping(uint256 => TrustAttributes) public trustDetails;

    // Events for minting, burning, and assigning trust attributes
    event TrustNFTMinted(
        address indexed to,
        uint256 tokenId,
        bool isInstitutionalInvestor
    );
    event TrustNFTBurned(uint256 tokenId);

    // Custom errors for efficient error handling
    error UnauthorizedAccess();
    error TokenNonExistent(uint256 tokenId);

    constructor(
        address initialOwner
    ) ERC721("Trust Membership", "TRUST") Ownable(initialOwner) {
        grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(MINTER_ROLE, msg.sender);
        _tokenIdCounter = 1; // Start token IDs at 1
    }

    /**
     * @dev Mint a new Trust NFT.
     * Only an address with the MINTER_ROLE can mint new tokens.
     * @param to The address that will receive the minted NFT.
     * @param isInstitutionalInvestor True if the recipient is an institutional investor or trust, otherwise false.
     */
    function mintTrustNFT(
        address to,
        bool isInstitutionalInvestor
    ) external onlyRole(MINTER_ROLE) nonReentrant {
        uint256 tokenId = _tokenIdCounter;
        _safeMint(to, tokenId);

        // Set URI for metadata (to be replaced with actual URI)
        _setTokenURI(tokenId, "https://metadata.uri/for/TrustNFT");

        // Set specific attributes for institutional investors or trusts
        TrustAttributes memory attributes;
        attributes.isInstitutionalInvestor = isInstitutionalInvestor;
        attributes.governanceWeight = isInstitutionalInvestor ? 5 : 3; // Institutional investors have higher governance weight
        attributes.investmentBenefitRate = isInstitutionalInvestor ? 25 : 15; // Investment benefit rate
        trustDetails[tokenId] = attributes;

        _tokenIdCounter += 1;
        emit TrustNFTMinted(to, tokenId, isInstitutionalInvestor);
    }

    /**
     * @dev Burn a Trust NFT.
     * Only the owner or admin can burn the NFT in cases of revocation, termination, or upgrades.
     * @param tokenId The ID of the token to be burned.
     */
    function burnTrustNFT(uint256 tokenId) external nonReentrant {
        if (
            ownerOf(tokenId) != msg.sender &&
            !hasRole(DEFAULT_ADMIN_ROLE, msg.sender)
        ) {
            revert UnauthorizedAccess();
        }
        _burn(tokenId);
        delete trustDetails[tokenId];
        emit TrustNFTBurned(tokenId);
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
        revert("Trust NFTs are non-transferable");
    }

    /**
     * @dev Check if a specific token ID belongs to an institutional investor or trust.
     * @param tokenId The ID of the token to check.
     * @return True if the token belongs to an institutional investor or trust, otherwise false.
     */
    function isInstitutionalInvestor(
        uint256 tokenId
    ) external view returns (bool) {
        return trustDetails[tokenId].isInstitutionalInvestor;
    }

    /**
     * @dev Get the governance weight assigned to a specific token ID.
     * @param tokenId The ID of the token to check.
     * @return Governance weight for the token.
     */
    function getGovernanceWeight(
        uint256 tokenId
    ) external view returns (uint8) {
        return trustDetails[tokenId].governanceWeight;
    }

    /**
     * @dev Get the investment benefit rate assigned to a specific token ID for future investment opportunities.
     * @param tokenId The ID of the token to check.
     * @return Investment benefit rate for the token.
     */
    function getInvestmentBenefitRate(
        uint256 tokenId
    ) external view returns (uint256) {
        return trustDetails[tokenId].investmentBenefitRate;
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
 - Separate contract for Trust NFTs, designed for institutional investors and trusts.
 - Minting restricted to addresses with the MINTER_ROLE, typically DAO administrators.
 - Soul-bound: NFTs are non-transferable, but can be burned by the owner or admin under specific conditions.
 - Institutional investors receive special privileges: higher governance weight and greater investment benefit rates.
 - Interoperability: Designed for integration with the Governance Contract to determine voting rights and influence within the DAO ecosystem.
 - Improved error handling with custom errors for more efficient gas usage.
 - Reentrancy guard applied for security in minting and burning operations.
*/
