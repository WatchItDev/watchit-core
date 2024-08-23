// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "contracts/libraries/Types.sol";

interface IRightsAccessController {
    /// @notice Register access to specific accounts for a certain content ID based on given conditions.
    /// @param accounts The addresses of the accounts to be granted access.
    /// @param validator The address of the contract responsible for enforcing or validating the conditions of the license.
    /// @param contentId The ID of the content for which access is being granted.
    /// @dev Access can be granted only if the validator contract is valid and has been granted delegation rights. 
    /// If the conditions are not met, access will not be registered.
    function enforceAccess(
        uint256 contentId,
        address validator,
        address[] calldata accounts
    ) external payable;

    /// @notice Checks if access is allowed for a specific user and content.
    /// @param account The address of the account to verify access.
    /// @param contentId The content ID to check access for.
    /// @return True if access is allowed, false otherwise.
    function isAccessGranted(
        address account,
        uint256 contentId
    ) external returns (bool);
}
