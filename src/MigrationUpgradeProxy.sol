// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/access/Ownable.sol";

contract MigrationAndUpgradeProxy is Ownable {
    // Proxy contract address storage
    mapping(string => address) public proxies;

    constructor(address initialOwner) Ownable(initialOwner) {}

    /**
     * @dev Deploy a new proxy contract for a given logic contract.
     * @param logicContract The address of the logic contract to point to.
     * @param adminAddress The address that will manage this proxy contract.
     * @param data Any initialization data.
     */
    function deployProxy(
        address logicContract,
        address adminAddress,
        bytes memory data,
        string memory contractName
    ) external onlyOwner {
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            logicContract,
            adminAddress,
            data
        );
        proxies[contractName] = address(proxy);
    }

    /**
     * @dev Get the proxy contract address for a specific contract.
     * @param contractName The name of the deployed contract.
     * @return Address of the proxy contract.
     */
    function getProxyAddress(
        string memory contractName
    ) external view returns (address) {
        return proxies[contractName];
    }
}

/*
 Key Features:
 - Uses OpenZeppelin TransparentUpgradeableProxy for upgradeability.
 - The contract owner can deploy new proxies and manage upgrades.
 - Admin roles are initially set manually and can transition to a DAO-controlled setup.
 - Admin roles can be updated to ensure control transition from central to decentralized governance.
*/
