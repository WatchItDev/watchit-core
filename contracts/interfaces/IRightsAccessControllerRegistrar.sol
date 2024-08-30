// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "contracts/libraries/Types.sol";

interface IRightsAccessControllerRegistrar {
    /// @notice Registers and enforces access for a specific account to a content ID based on the conditions set by a policy.
    /// @param account The address of the account to be granted access to the content.
    /// @param contentId The unique identifier of the content for which access is being registered.
    /// @dev Access is granted only if the specified policy contract is valid and has the necessary delegation rights.
    /// If the policy conditions are not met, access will not be registered, and the operation will be rejected.
    function registerPolicy(
        uint256 contentId,
        address policy,
        address account
    ) external payable;
}
