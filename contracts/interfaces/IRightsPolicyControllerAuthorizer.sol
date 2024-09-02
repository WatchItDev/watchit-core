// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "contracts/libraries/Types.sol";

interface IRightsPolicyControllerAuthorizer {
    /// @notice Delegates rights for a specific content ID to a policy contract.
    /// @dev This function stores the delegation details in the RightsStorage struct,
    ///      allowing the specified policy contract to manage rights for the content holder.
    /// @param policy The address of the policy contract to which rights are being delegated.
    function authorizePolicy(address policy) external;
}
