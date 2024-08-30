// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "contracts/libraries/Types.sol";

interface IRightsAccessControllerRegistrar {
    /// @notice Enforces access for a specific account to a content ID based on the conditions set by a policy.
    /// @param account The address of the account to be granted access to the content.
    /// @param contentId The unique identifier of the content for which access is being registered.
    /// @dev Access is granted only if the caller policy contract is valid and has the necessary delegation rights.
    /// If the policy conditions are not met, access will not be registered, and the operation will be rejected.
    function grantAccess(uint256 contentId, address account) external payable;
}
