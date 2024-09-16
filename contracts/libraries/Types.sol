// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html
pragma solidity ^0.8.24;

/// @title Type Definitions Library
/// @notice This library provides common type definitions for use in other contracts.
/// @dev This library defines types and structures that can be imported and used in other contracts.
library T {
    enum ContractTypes {
        __, // Undefined type
        SYN, // Syndication contract
        OWN, // Syndication contract
        TRE, // Treasury contract
        REF, // Content referendum
        RM, // Rights Management contract
        WVC
    }

    /// @title Shares
    /// @dev Represents the distribution of funds to a specific address.
    /// @notice This struct is used to define the share of funds (e.g., royalties, service fees) 
    /// that should be allocated to a particular address.
    struct Shares {
        address target;
        uint256 bps; // Basis points, with 10000 bps being equivalent to 100%.
    }

    /// @title Deal
    /// @dev Represents an agreement between multiple parties regarding the distribution and management of content.
    /// @notice This struct captures the total amount involved, net amount after deductions, distribution fees,
    /// and the relevant addresses involved in the deal.
    struct Deal {
        uint256 time; // the deal creation date
        uint256 total; // the transaction total amount
        uint256 fees; // distribution fees
        uint256 available; // the remaining amount after fees
        address currency; // the currency used in transaction
        address account; // the account related to deal
        address holder; // the content holder
        address custodial; // the distributor address
        bool active; // the deal status
    }

    /// @notice A struct containing the necessary information to reconstruct an EIP-712 typed data signature.
    /// @dev We could use this information to handle signature logic with delegated actions from the account owner.
    /// @param v The signature's recovery parameter.
    /// @param r The signature's r parameter.
    /// @param s The signature's s parameter.
    struct EIP712Signature {
        uint8 v; // 1 byte
        bytes32 r; // 32 bytes
        bytes32 s; // 32 bytes
    }
}
