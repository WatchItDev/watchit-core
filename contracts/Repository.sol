// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "contracts/interfaces/IRepository.sol";

contract Repository is
    IRepository,
    Initializable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    mapping(ContractTypes => address) public contracts;
    error ContractIsNotRegistered();

    /// @dev Constructor that disables initializers to prevent the implementation contract from being initialized.
    /// https://forum.openzeppelin.com/t/uupsupgradeable-vulnerability-post-mortem/15680
    /// https://forum.openzeppelin.com/t/what-does-disableinitializers-function-mean/28730/5
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the contract with the given dependencies.
    function initialize() public initializer {
        __UUPSUpgradeable_init();
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev Upgrades the contract version.
    /// @notice Only the admin can upgrade the contract.
    /// @param newImplementation The address of the new implementation contract.
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    function getContract(
        ContractTypes key
    ) external view returns (address) {
        if (contracts[key] == address(0)) revert ContractIsNotRegistered();
        return contracts[key];
    }

    function setContract(
        ContractTypes key,
        address contractAddress
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        contracts[key] = contractAddress;
    }

}
