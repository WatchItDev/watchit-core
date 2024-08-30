// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title Address Helper Library
/// @notice Provides functions to convert an address to a bytes32 representation.
/// @dev Contains functions to convert an address to a bytes32 value with proper alignment.
library AddressHelper {
    /// @notice Converts an address to a bytes32 representation.
    /// @dev This function uses inline assembly to directly cast an address to a bytes32 type.
    ///      The address is placed into the least significant 20 bytes of the resulting bytes32 value,
    ///      and the most significant 12 bytes are filled with zeros.
    /// @param addr The address to be converted to bytes32.
    /// @return byte32Addr The address in bytes32 format, with the 12 most significant bytes as zero.
    function toByte32(
        address addr
    ) internal pure returns (bytes32 byte32Addr) {
        assembly {
            byte32Addr := addr
        }
    }
}
