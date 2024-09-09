// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./ITreasurer.sol";
import "./IFeesManager.sol";
import "./IDisburser.sol";
import "./IRightsCustodial.sol";
import "./IRightsDealBroker.sol";
import "./IRightsPolicyAuditor.sol";
import "./IRightsPolicyController.sol";
import "./IRightsCustodialGranter.sol";
import "./IRightsAccessController.sol";
import "./IFundsManager.sol";
import "./IContentVault.sol";

interface IRightsManager is
    ITreasurer,
    IDisburser,
    IFeesManager,
    IFundsManager,
    IRightsCustodial,
    IRightsDealBroker,
    IRightsAccessController,
    IRightsCustodialGranter,
    IRightsPolicyController,
    IRightsPolicyAuditor
{
    /// @notice Checks if the content is eligible for distribution by the content holder's custodial.
    /// @param contentId The ID of the content to check for distribution eligibility.
    /// @param contentHolder The address of the content holder whose custodial rights are being checked.
    /// @return True if the content can be distributed, false otherwise.
    function isEligibleForDistribution(
        uint256 contentId,
        address contentHolder
    ) external returns (bool);
}
