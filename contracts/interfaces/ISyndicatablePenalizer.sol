// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html
pragma solidity ^0.8.24;


/// @title Content Syndication Interface
/// @notice This interface spec all distribution logic needed for creators and distributors.
interface ISyndicatablePenalizer {
    /// @notice Function to set the penalty rate for quitting enrollment.
    /// @param newPenaltyRate The new penalty rate to be set. It should be a value representing base points (bps).
    /// @param currency The currency to set penalty rate.
    /// @dev The penalty rate is represented as base points (expressed as a uint256)
    /// That will be applied to the enrollment fee when a distributor quits.
    function setPenaltyRate(uint256 newPenaltyRate, address currency) external;
}
