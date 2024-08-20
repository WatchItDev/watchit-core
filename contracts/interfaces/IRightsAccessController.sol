// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "contracts/libraries/Types.sol";

interface IRightsAccessController {
    /// @notice Grants access to specific accounts for a certain content ID based on given conditions.
    /// @param accounts The addresses of the accounts to be granted access.
    /// @param contentId The ID of the content for which access is being granted.
    /// @param alloc The allocation specification to distribute the royalties or fees.
    /// @dev Access can be granted only if the validator contract is valid and has been granted delegation rights.
    function grantAccess(
        uint256 contentId,
        address[] calldata accounts,
        T.Allocation calldata alloc
    ) external payable;

    /// @notice Checks if access is allowed for a specific user and content.
    /// @param account The address of the user.
    /// @param contentId The content ID to check access.
    /// @return True if access is allowed, false otherwise.
    function isAccessGranted(
        address account,
        uint256 contentId
    ) external returns (bool);
}
