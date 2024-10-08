// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

interface IRightsManagerVerifiable {
    /// @notice Checks if the content is eligible for distribution by the content holder's custodial.
    /// @param contentId The ID of the content to check for distribution eligibility.
    /// @param contentHolder The address of the content holder whose custodial rights are being checked.
    /// @return True if the content can be distributed, false otherwise.
    function isEligibleForDistribution(uint256 contentId, address contentHolder) external returns (bool);
}
