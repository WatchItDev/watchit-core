// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./ITreasurer.sol";
import "./IFeesManager.sol";
import "./IDisburser.sol";
import "./IContentVault.sol";
import "./IRightsCustodial.sol";
import "./IBalanceManager.sol";
import "./IRightsDealBroker.sol";
import "./IRightsPolicyAuditor.sol";
import "./IRightsPolicyController.sol";
import "./IRightsCustodialGranter.sol";
import "./IRightsAccessController.sol";

interface IRightsManager is
    ITreasurer,
    IDisburser,
    IFeesManager,
    IBalanceManager,
    IRightsCustodial,
    IRightsDealBroker,
    IRightsAccessController,
    IRightsCustodialGranter,
    IRightsPolicyController,
    IRightsPolicyAuditor
{
    /// @notice Calculates the fees for the treasury based on the provided total amount.
    /// @param total The total amount involved in the transaction.
    /// @param currency The address of the ERC20 token (or native currency) being used in the transaction.
    /// @return treasury The calculated fee for the treasury.
    function calcFees(
        uint256 total,
        address currency
    ) external returns (uint256);

    /// @notice Checks if the content is eligible for distribution by the content holder's custodial.
    /// @param contentId The ID of the content to check for distribution eligibility.
    /// @param contentHolder The address of the content holder whose custodial rights are being checked.
    /// @return True if the content can be distributed, false otherwise.
    function isEligibleForDistribution(
        uint256 contentId,
        address contentHolder
    ) external returns (bool);

    /// @notice Finalizes the deal by registering the agreed-upon policy, effectively closing the deal.
    /// @dev This function verifies the policy's authorization, executes the deal, processes financial transactions,
    ///      and registers the policy in the system, representing the formal closure of the deal.
    /// @param dealProof The unique identifier of the deal to be enforced.
    /// @param policyAddress The address of the policy contract managing the deal.
    /// @param data Additional data required to execute the deal.
    function registerPolicy(
        bytes32 dealProof,
        address policyAddress,
        bytes calldata data
    ) external payable;
}
