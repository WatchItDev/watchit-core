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
    
    /// @notice Structure to store an access condition.
    /// @dev The structure contains the address of a witness contract and the selector of the function to call.
    /// @param witnessContractAddress The address of the witness contract that provides testimony of the condition.
    /// @param functionSelector The selector of the function that verifies the access condition.
    struct AccessCondition {
        address witnessContractAddress;
        bytes4 functionSelector;
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

}
