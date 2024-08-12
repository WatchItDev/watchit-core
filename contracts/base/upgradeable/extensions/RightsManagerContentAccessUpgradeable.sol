// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "contracts/interfaces/IRightsAccessController.sol";
import "contracts/interfaces/IAccessWitness.sol";
import "contracts/libraries/Types.sol";

/// @title Rights Manager Content Access Upgradeable
/// @notice This contract manages access control for content based on timeframes.
/// @dev This contract is upgradeable and uses ReentrancyGuard to prevent reentrant calls.
abstract contract RightsManagerContentAccessUpgradeable is
    Initializable,
    IRightsAccessController
{
    using ERC165Checker for address;
    bytes4 private constant INTERFACE_WITNESS_ACCESS =
        type(IAccessWitness).interfaceId;

    // TODO namespace refactor
    /// @dev Error thrown when access control validation fails.
    /// @param contractAddress The address of the contract where validation failed.
    error InvalidAccessControlValidation(address contractAddress);
    /// @dev Error thrown when the witness contract does not implement the correct interface.
    error InvalidWitnessContract();

    /// @dev Mapping to store the access control list for each account and content hash.
    mapping(uint256 => mapping(address => Witness )) private acl;
    // The access to content can be delegated, so the owner can delegate "holding" rights.
    // under specific conditions and admin the access to others account under that conditions.
    // eg: you are allowed to handle X, Y, Z access conditions..
    mapping(uint256 => mapping(address => T.AccessCondition)) private allowed;

    /// @dev Modifier to check that the witness contract implements the IAccessWitness interface.
    /// @param witness The address of the witness contract.
    modifier validWitnessOnly(address witness) {
        if (!witness.supportsInterface(INTERFACE_WITNESS_ACCESS))
            revert InvalidWitnessContract();
        _;
    }

    /// @notice Grants access to a specific account for a certain content ID.
    /// @param account The address of the account.
    /// @param contentId The content ID to grant access to.
    /// @param condition The conditional access control.
    function _grantAccess(
        address account,
        uint256 contentId,
        T.AccessCondition calldata condition
    ) internal validWitnessOnly(condition.witness.contractAddress) {
        // Register the condition to validate access.
        acl[contentId][account] = condition;
    }

    /// @notice Grants delegate right to address under specific conditions.
    /// @param delegate The address of the account.
    /// @param contentId The content ID to grant access to.
    /// @param condition The conditional access control.
    function _delegateRights(
        address delegate,
        uint256 contentId,
        T.AccessCondition calldata condition
    ) internal validWitnessOnly(condition.witness.contractAddress) {
        // Register the condition to validate access.
        allowed[contentId][account] = condition;
    }

    function _hasDelegatedRights(
        address delegate,
        uint256 contentId
        ){

    }

    /// @notice Checks if access is allowed for a specific account and content.
    /// @param account The address of the account.
    /// @param contentId The content ID to check access for.
    /// @return bool True if access is allowed, false otherwise.
    function _isAccessGranted(
        address account,
        uint256 contentId
    ) internal view returns (bool) {
        // The approve method is called and executed according to the IAccessWitness spec.
        T.AccessCondition memory condition = acl[contentId][account];
        (bool success, bytes memory result) = condition
            .witness.contractAddress
            // staticcall does not allow changing the state of the blockchain.
            .staticcall(
                abi.encodeWithSelector(
                    condition.witness.functionSelector,
                    account,
                    contentId
                )
            );

        if (!success)
            revert InvalidAccessControlValidation(
                condition.witness.contractAddress
            );
        // Decode the expected result and return it.
        return abi.decode(result, (bool));
    }
}
