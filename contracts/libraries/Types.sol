// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html
pragma solidity ^0.8.24;

/// @title Type Definitions Library
/// @notice This library provides common type definitions for use in other contracts.
/// @dev This library defines types and structures that can be imported and used in other contracts.
library T {
    enum ContractTypes {
        __, // Undefined type
        SYNDICATION, // Syndication contract
        TREASURY, // Treasury contract
        REFERENDUM, // Content referendum
        DRM // Digital Rights Management contract
    }

    struct AccessCondition {
        address witnessAddress;
        bytes4 witnessSelector;
        address txCurrency; // currency transaction
        uint256 txAmount; // amount of transaction
    }

    /**
     * @notice A struct containing the necessary information to reconstruct an EIP-712 typed data signature.
     * @dev We could use this information to handle signature logic with delegated actions from the account owner.
     * @param signer The address of the signer. Specially needed as a parameter to support EIP-1271.
     * @param v The signature's recovery parameter.
     * @param r The signature's r parameter.
     * @param s The signature's s parameter.
     * @param deadline The signature's deadline.
     */
    struct EIP712Signature {
        address signer;
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 deadline;
    }

    // This struct provides critical parameters that will be used during the referendum process
    // to give voters context about the content and help distributors determine where the content
    // can be appropriately projected. These parameters ensure the content meets local regulations,
    // aligns with audience expectations, and is suitable for distribution.
    // Define a struct for ContentParams
    struct ContentParams {
        string trailer;
        string geofencing; // Expected geographic restriction for content distribution.
        string rating; // Content rating (e.g., G, PG, PG-13, R).
        string language; // Language of the content.
        string license; // Distribution license information.
        string contentWarnings; // Content warnings (e.g., violence, strong language).
        string targetAudience; // Target audience of the content.
    }
}
