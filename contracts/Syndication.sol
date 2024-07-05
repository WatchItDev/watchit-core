// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./IDistributor.sol";

/// @title Content Syndication contract.
/// @notice Use this contract to handle all distribution logic needed for creators and distributors.
/// @dev This contract uses the UUPS upgradeable pattern and AccessControl for role-based access control.
contract Syndication is
    Initializable,
    UUPSUpgradeable,
    AccessControlUpgradeable
{
    using ERC165Checker for address;
    bytes32 public constant GOB_ROLE = keccak256("GOB_ROLE");
    bytes4 private constant _INTERFACE_ID_IDISTRIBUTOR =
        type(IDistributor).interfaceId;

    /// @notice Emitted when a new distributor is registered.
    /// @param distributor The distributor contract address.
    event DistributorRegistered(IDistributor distributor);

    /// @notice Error thrown when the distributor is inactive.
    error InvalidInactiveDistributor();

    /// @notice Error thrown when the distributor already exists.
    error DistributorAlreadyExists();

    /// @notice Error thrown when the contract does not support the IDistributor interface.
    error InvalidDistributorContract();

    /// @notice Error thrown when the caller is not the content holder.
    error InvalidContentHolder();

    // Default value is the first element listed in
    // definition of the type...
    enum Status {
        Pending,
        Active,
        Blocked
    }

    IERC721 private ownership;
    /// mapping to record distributor state address:active.
    mapping(IDistributor => Status) private status;

    /// @dev Constructor that disables initializers to prevent the implementation contract from being initialized.
    /// https://forum.openzeppelin.com/t/uupsupgradeable-vulnerability-post-mortem/15680
    /// https://forum.openzeppelin.com/t/what-does-disableinitializers-function-mean/28730/5
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the contract with the given ownership address.
    /// @dev This function is called only once during the contract deployment.
    /// @param _ownership The address of the ownership contract that supports the IERC721 interface.
    function initialize(IERC721 _ownership) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        ownership = _ownership;
    }


    /// @notice Modifier to ensure that the given distributor contract supports the IDistributor interface.
    /// @param distributor The address of the distributor contract to check.
    modifier validContractOnly(IDistributor distributor) {
        if (!address(distributor).supportsInterface(_INTERFACE_ID_IDISTRIBUTOR))
            revert InvalidDistributorContract();
        _;
    }

    /// @notice Function that should revert when msg sender is not authorized to upgrade the contract.
    /// @dev see https://docs.openzeppelin.com/contracts/4.x/api/proxy#UUPSUpgradeable-_authorizeUpgrade-address-
    /// @param newImplementation The address of the new implementation contract.
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}


    function setGovernance(
        address _governance
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(GOB_ROLE, _governance);
    }

    function isActive(
        IDistributor distributor
    ) external view validContractOnly(distributor) returns (bool) {
        return status[distributor] == Status.Active;
    }

    function revoke(
        IDistributor distributor
    ) public validContractOnly(distributor) onlyRole(GOB_ROLE) {
        if (status[distributor] != Status.Active)
            revert InvalidInactiveDistributor();
        status[distributor] = Status.Blocked;
    }

    // TODO quit only distributor

    /// @notice Registers a new distributor.
    /// @dev The distributor must be missing or not active.
    /// @param distributor The distributor contract address.
    function register(
        IDistributor distributor
    ) external validContractOnly(distributor) {
        if (status[distributor] != Status.Pending)
            revert DistributorAlreadyExists();

        status[distributor] = Status.Active; // active
        emit DistributorRegistered(distributor);
    }
}
