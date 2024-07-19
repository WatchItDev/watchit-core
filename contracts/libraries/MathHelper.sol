// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library MathHelper {
    // We can not operate with float so we use base points instead..
    // If we need more precision we can adjust this bps..
    // https://en.wikipedia.org/wiki/Basis_point
    // 1 bps = 0.01, 10 bps = 0.1
    // ...
    uint8 internal constant SCALE_FACTOR = 100;
    uint16 internal constant BPS_MAX = 10_000;

     /// @dev Calculates the percentage of `amount` based on the given `bps` (basis points).
     /// @param amount The amount to calculate the percentage of.
     /// @param bps The basis points to use for the calculation.
     /// @return The percentage of `amount` based on the given `bps`.
    function perOf(
        uint256 amount,
        uint256 bps
    ) internal pure returns (uint256) {
        // 10 * (5*100) / 10_000
        return (amount * bps) / BPS_MAX;
    }

    /// @dev Calculates the basis points (`bps`) based on the given percentage.
    /// @param per The percentage to calculate the `bps` for.
    /// @return The `bps` based on the given percentage.
    function calcBps(uint256 per) internal pure returns (uint256) {
        return per * SCALE_FACTOR;
    }
}
