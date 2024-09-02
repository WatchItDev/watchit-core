// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "contracts/libraries/Types.sol";

interface IRightsPolicyControllerRevoker {
    /// @notice Revokes the delegation of rights to a specific policy contract.
    /// @dev This function removes the rights delegation from the RightsStorage struct,
    ///      preventing the specified policy contract from managing rights for the content holder.
    /// @param policy The address of the policy contract whose rights delegation is being revoked.
    function revokePolicy(address policy) external;
}
