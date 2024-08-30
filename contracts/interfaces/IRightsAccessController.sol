// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "contracts/libraries/Types.sol";

interface IRightsAccessController {
    /// @notice Retrieves the registered policy for a specific user and content ID.
    /// @param account The address of the account to evaluate.
    /// @param contentId The content ID to evaluate policies for.
    function getAccessPolicy(
        address account,
        uint256 contentId
    ) external returns (bool, address);
}
