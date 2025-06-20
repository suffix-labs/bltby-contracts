// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

interface IAccessTokenSubContract {
    function initialize(
        string memory _name,
        string memory _symbol,
        address _admin,
        uint256 _duration,
        uint8 _tokenType
    ) external;
}

contract UmbrellaAccessTokenContract is AccessControl, ReentrancyGuard {
    uint256 private _subContractCounter;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant REVIEWER_ROLE = keccak256("REVIEWER_ROLE");

    address public immutable subContractTemplate;

    struct SubContractInfo {
        address contractAddress;
        string name;
        uint256 createdAt;
        uint8 tokenType; // 0 = Gym, 1 = Event, 2 = Seminar, etc.
        bool approved;
    }

    mapping(uint256 => SubContractInfo) public subContracts;
    mapping(address => bool) public existingSubContracts;

    event SubContractCreated(
        uint256 indexed subContractId,
        address contractAddress,
        string name,
        uint8 tokenType
    );
    event SubContractApproved(
        uint256 indexed subContractId,
        address contractAddress
    );

    error Unauthorized();
    error SubContractAlreadyApproved(uint256 subContractId);
    error InvalidSubContractAddress(address contractAddress);

    constructor(address _subContractTemplate, address admin, address reviewer) {
        require(_subContractTemplate != address(0), "Invalid template address");
        subContractTemplate = _subContractTemplate;
        _grantRole(ADMIN_ROLE, admin);
        _grantRole(REVIEWER_ROLE, reviewer);
    }

    /**
     * @dev Create a new Access Token sub-contract using a clone of the template.
     * Only an address with the ADMIN_ROLE can initiate this process.
     * @param name The name of the sub-contract token (e.g., "Gym Access Token").
     * @param symbol The symbol of the sub-contract token (e.g., "GYM").
     * @param duration The duration for which access tokens issued by this sub-contract will be valid.
     * @param tokenType The type of the token (e.g., 0 for Gym, 1 for Event, etc.).
     */
    function createSubContract(
        string memory name,
        string memory symbol,
        uint256 duration,
        uint8 tokenType
    ) external onlyRole(ADMIN_ROLE) nonReentrant {
        address clone = Clones.clone(subContractTemplate);
        IAccessTokenSubContract(clone).initialize(
            name,
            symbol,
            msg.sender,
            duration,
            tokenType
        );

        uint256 subContractId = _subContractCounter;
        subContracts[subContractId] = SubContractInfo({
            contractAddress: clone,
            name: name,
            createdAt: block.timestamp,
            tokenType: tokenType,
            approved: false
        });

        existingSubContracts[clone] = true;
        _subContractCounter++;
        emit SubContractCreated(subContractId, clone, name, tokenType);
    }

    /**
     * @dev Approve a newly created Access Token sub-contract.
     * Only an address with the REVIEWER_ROLE can approve a sub-contract.
     * @param subContractId The ID of the sub-contract to approve.
     */
    function approveSubContract(
        uint256 subContractId
    ) external onlyRole(REVIEWER_ROLE) nonReentrant {
        SubContractInfo storage subContract = subContracts[subContractId];
        if (subContract.approved) {
            revert SubContractAlreadyApproved(subContractId);
        }
        subContract.approved = true;
        emit SubContractApproved(subContractId, subContract.contractAddress);
    }

    /**
     * @dev Check if a sub-contract has been approved and is valid.
     * @param subContractAddress The address of the sub-contract to verify.
     * @return True if the sub-contract is approved and valid, otherwise false.
     */
    function isSubContractApproved(
        address subContractAddress
    ) external view returns (bool) {
        if (!existingSubContracts[subContractAddress]) {
            revert InvalidSubContractAddress(subContractAddress);
        }
        for (uint256 i = 0; i < _subContractCounter; i++) {
            if (subContracts[i].contractAddress == subContractAddress) {
                return subContracts[i].approved;
            }
        }
        return false;
    }
}
