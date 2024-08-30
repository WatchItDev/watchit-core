// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./ITreasurer.sol";
import "./ILedger.sol";
import "./IFundsManager.sol";
import "./IFeesManager.sol";
import "./IDisburser.sol";
import "./IRightsCustodial.sol";
import "./IRightsPolicyController.sol";
import "./IRightsCustodialGranter.sol";
import "./IRightsAccessController.sol";
import "./IRightsPolicyControllerRevoker.sol";
import "./IRightsPolicyControllerAuthorizer.sol";
import "./IRightsAccessControllerRegistrar.sol";
import "./IContentVault.sol";

interface IRightsManager is
    ILedger,
    ITreasurer,
    IDisburser,
    IFeesManager,
    IFundsManager,
    IRightsCustodial,
    IRightsPolicyController,
    IRightsAccessController,
    IRightsCustodialGranter,
    IRightsPolicyControllerRevoker,
    IRightsPolicyControllerAuthorizer,
    IRightsAccessControllerRegistrar
{
    /// @notice Checks if the content is eligible for distribution.
    /// @param contentId The ID of the content.
    /// @return True if the content can be distributed, false otherwise.
    function isEligibleForDistribution(
        uint256 contentId
    ) external returns (bool);
}
