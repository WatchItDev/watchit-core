// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html
pragma solidity 0.8.26;

/// @title Content Syndication Interface
/// @notice This interface specifies all distribution logic needed for creators and distributors.
interface ISyndicatablePenalizer {
    /// @notice Sets the penalty rate for quitting enrollment.
    /// @param newPenaltyRate The new penalty rate to be set, represented in basis points (bps).
    /// @param currency The currency in which to set the penalty rate.
    /// @dev The penalty rate is represented as basis points (bps) and applied to the enrollment fee when a distributor quits.
    function setPenaltyRate(uint256 newPenaltyRate, address currency) external;

    /// @notice Retrieves the penalty rate for quitting enrollment.
    /// @param currency The currency in which to query the penalty rate.
    /// @dev The penalty rate is stored in basis points (bps).
    function getPenaltyRate(address currency) external view returns (uint256);
}
