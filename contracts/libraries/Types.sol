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
        DRM, // Digital Rights Management contract
        WVC
    }

    /// @notice Represents the currency and amount associated with an access condition.
    /// @dev This struct holds the details of the currency and the required amount for a transaction.
    /// @param currency The address of the token or currency used for the transaction.
    /// @param amount The amount of the currency required to satisfy the access condition.
    struct Fees {
        address currency;
        uint256 amount;
    }

    /// @notice Structure representing a witness involved in the validation process.
    /// @dev This structure stores the address of a witness contract and the selector of the function that will be called for validation.
    /// @param contractAddress The address of the witness contract responsible for verifying the condition.
    /// @param functionSelector The function selector within the witness contract that performs the validation.
    struct Witness {
        address contractAddress;
        bytes4 functionSelector;
    }

    /// @notice Defines the conditions required to access specific content.
    /// @dev This struct consolidates various parameters that establish the access requirements.
    /// @param witness A struct containing the address and function selector of the witness contract used for validation.
    /// @param fee A struct representing the currency and amount required to fulfill the access condition.
    struct AccessCondition {
        Witness witness;
        Fees fee;
    }

    // /// @notice Represents the conditions required for accessing specific content.
    // /// @dev This struct holds various parameters that define the access conditions.
    // /// @param witnessAddress The address of the witness contract that validates the access.
    // /// @param witnessSelector The function selector to call on the witness contract for validation.
    // /// @param txCurrency The address of the token or currency used for the transaction.
    // /// @param txAmount The amount of the transaction required to satisfy the access condition.
    // struct AccessCondition {
    //     address witnessAddress;
    //     bytes4 witnessSelector;
    //     address txCurrency;
    //     uint256 txAmount;
    // }

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
