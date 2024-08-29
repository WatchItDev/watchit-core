// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "contracts/libraries/Types.sol";

interface IRightsDelegableDelegator {

    /// @notice Delegates rights for a specific content ID to a grantee.
    /// @param grantee The address of the account or contract to delegate rights to.
    /// @param contentId The content ID for which rights are being delegated.
    function delegateRights(address grantee, uint256 contentId) external;

}
