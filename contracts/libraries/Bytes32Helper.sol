// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title Fixed Bytes32 Library
/// @notice Provides functions to convert bytes32 to other data types.
/// @dev Contains functions to convert a bytes32 array to an address with proper alignment.
library Bytes32Helper {
    /// @notice Error to be thrown when bytes to address conversion fails.
    error InvalidBytesToAddressConversion();

    /// @notice Converts a bytes32 value to an address.
    /// @param _bytes The bytes32 value to convert.
    /// @return addr The converted address.
    /// @dev This function uses inline assembly to perform the conversion.
    function toAddress(bytes32 _bytes) internal pure returns (address addr) {
        assembly {
            // AND operation with mask to retain only the lower 20 bytes
            // [padding]     [data]
            // [000000000000][11111111111111111111] & 11111111111111111111111111111111
            // Only 20 bytes data remains for address
            addr := and(_bytes, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        }
    }

    /// @notice Converts a bytes32 value to a uint256.
    /// @param _bytes The bytes32 value to convert.
    /// @return The converted uint256 value.
    /// @dev This function performs a direct type casting.
    function toUint256(bytes32 _bytes) internal pure returns (uint256) {
        return uint256(_bytes);
    }
}
