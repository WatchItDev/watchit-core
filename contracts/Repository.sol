// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "contracts/interfaces/IRepository.sol";
import "contracts/libraries/Types.sol";

/// @title Repository Contract (Registry)
/// @notice Manages the addresses of different contract types and their versions.
/// @dev This contract uses the UUPS upgradeable pattern and AccessControl for role-based access control.
contract Repository is
    Initializable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    IRepository
{
    /// @notice Stores the addresses of the contracts by their type.
    mapping(T.ContractTypes => address) public contracts;

    /// @notice Stores the versions of the contracts by their type.
    mapping(T.ContractTypes => uint256) public versions;

    /// @notice Error that is thrown when a contract is not registered.
    error ContractIsNotRegistered();
    error InvalidPopulationParams(string);

    /// @dev Constructor that disables initializers to prevent the implementation contract from being initialized.
    /// @notice This constructor prevents the implementation contract from being initialized.
    /// @dev See https://forum.openzeppelin.com/t/uupsupgradeable-vulnerability-post-mortem/15680
    /// https://forum.openzeppelin.com/t/what-does-disableinitializers-function-mean/28730/5
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the contract with the given dependencies.
    function initialize() public initializer {
        __UUPSUpgradeable_init();
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev Authorizes the upgrade of the contract.
    /// @notice Only the admin can authorize the upgrade.
    /// @param newImplementation The address of the new implementation contract.
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    /// @notice Gets the address of the contract for the given key.
    /// @param key The type of the contract to retrieve.
    /// @return The address of the contract.
    /// @dev Reverts with `ContractIsNotRegistered` if the contract is not found.
    function getContract(T.ContractTypes key) external view returns (address) {
        if (contracts[key] == address(0)) revert ContractIsNotRegistered();
        return contracts[key];
    }

    /// @notice Sets the address of the contract for the given key.
    /// @param key The type of the contract to set.
    /// @param contractAddress The address of the contract to set.
    /// @dev Only callable by an admin.
    function setContract(
        T.ContractTypes key,
        address contractAddress
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        contracts[key] = contractAddress;
        versions[key]++;
    }

    /// @notice Populates the repository with multiple contract addresses.
    /// @param key An array of contract types to set.
    /// @param contractAddress An array of contract addresses to set.
    /// @dev Only callable by an admin.
    function populate(
        T.ContractTypes[] calldata key,
        address[] calldata contractAddress
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 length = key.length;
        if (length != contractAddress.length)
            revert InvalidPopulationParams(
                "Input arrays must have the same length"
            );

        for (uint8 i = 0; i < length; i++) {
            setContract(key[i], contractAddress[i]);
        }
    }
}
