// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./ITreasurer.sol";
import "./IDisburser.sol";
import "./IFeesManager.sol";
import "./IRightsOwnership.sol";
import "./IRightsCustodial.sol";
import "./IRightsAccessController.sol";
import "./IContentVault.sol";

interface IRightsManager is
    ITreasurer,
    IFeesManager,
    IDisburser,
    IContentVault,
    IRightsOwnership,
    IRightsCustodial,
    IRightsAccessController
{
    /// @notice Checks if the content is eligible for distribution.
    /// @param contentId The ID of the content.
    /// @return True if the content can be distributed, false otherwise.
    function isEligibleForDistribution(uint256 contentId) external returns (bool);
}
