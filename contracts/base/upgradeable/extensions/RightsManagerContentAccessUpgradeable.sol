// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "contracts/interfaces/IRightsAccessController.sol";
import "contracts/interfaces/ILicense.sol";
import "contracts/libraries/Types.sol";

/// @title Rights Manager Content Access Upgradeable
/// @notice This abstract contract manages content access control using a license 
/// validator contract that must implement the ILicense interface.
abstract contract RightsManagerContentAccessUpgradeable is
    Initializable,
    IRightsAccessController
{
    using ERC165Checker for address;

    /// @dev The interface ID for ILicense, used to verify that a validator contract implements the correct interface.
    bytes4 private constant INTERFACE_STRATEGY_VALIDATOR =
        type(ILicense).interfaceId;

    /// @custom:storage-location erc7201:rightscontentaccess.upgradeable
    /// @dev Storage struct for the access control list (ACL) that maps content IDs and accounts to validator contracts.
    struct ACLStorage {
        /// @dev Mapping to store the access control list for each content ID and account.
        mapping(uint256 => mapping(address => address)) _acl;
    }

    /// @dev Namespaced storage slot for ACLStorage to avoid storage layout collisions in upgradeable contracts.
    /// @dev The storage slot is calculated using a combination of keccak256 hashes and bitwise operations.
    bytes32 private constant ACCESS_CONTROL_SLOT =
        0xcd95b85482a9213e30949ccc9c44037e29b901ca879098f5c64dd501b45d9200;

    /**
     * @notice Internal function to access the ACL storage.
     * @dev Uses inline assembly to assign the correct storage slot to the ACLStorage struct.
     * @return $ The storage struct containing the access control list.
     */
    function _getACLStorage() private pure returns (ACLStorage storage $) {
        assembly {
            $.slot := ACCESS_CONTROL_SLOT
        }
    }

    /// @dev Error thrown when the validator contract does not implement the ILicense interface.
    error InvalidStrategyContract(address strategy);

    /**
     * @dev Modifier to check that a license contract implements the ILicense interface.
     * @param license The address of the license validator contract.
     * Reverts if the validator does not implement the required interface.
     */
    modifier onlyLicenseContract(address license) {
        if (!license.supportsInterface(INTERFACE_STRATEGY_VALIDATOR)) {
            revert InvalidStrategyContract(license);
        }
        _;
    }

    /**
     * @notice Grants access to a specific account for a certain content ID.
     * @dev The function associates a content ID and account with a validator contract in the ACL storage.
     * @param account The address of the account to be granted access.
     * @param contentId The ID of the content for which access is being granted.
     * @param validator The address of the license validator contract that will be used to validate access.
     */
    function _grantAccess(
        address account,
        uint256 contentId,
        address validator
    ) internal {
        ACLStorage storage $ = _getACLStorage();
        // Register the validator for the content and account.
        $._acl[contentId][account] = validator;
    }

    /**
     * @notice Checks if access is allowed for a specific account and content.
     * @dev The function calls the `approved` method on the validator contract to determine if access is granted.
     * @param account The address of the account to check access for.
     * @param contentId The ID of the content to check access for.
     * @return bool True if access is allowed, false otherwise.
     */
    function _isAccessGranted(
        address account,
        uint256 contentId
    ) internal view returns (bool) {
        ACLStorage storage $ = _getACLStorage();
        address strategyValidator = $._acl[contentId][account];
        // if the access is not registered, return false.
        if (strategyValidator == address(0)) return false;
        // The approved method is called and executed according to the ILicense specification.
        return ILicense(strategyValidator).terms(account, contentId);
    }
}
