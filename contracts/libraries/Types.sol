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
        OWNERSHIP, // Syndication contract
        TREASURY, // Treasury contract
        REFERENDUM, // Content referendum
        RM, // Rights Management contract
        WVC
    }

    /// @title Splits
    /// @dev Represents the distribution of royalties to a specific address.
    struct Splits {
        address target;
        uint256 bps; // Basis points, with 10000 bps being equivalent to 100%.
    }

    /// @title Transaction
    /// @dev Represents the details of a transaction involving a specific currency and amount.
    struct Transaction {
        address currency;
        uint256 amount;
    }

    /// @notice Represents the terms and conditions associated with accessing content.
    /// @dev This struct encapsulates the transaction details and the fee splits for the content.
    struct Terms {
        Transaction t9n;
        Splits[] s4s;
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
