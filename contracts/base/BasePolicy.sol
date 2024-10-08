// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import { Ledger } from "contracts/base/Ledger.sol";
import { IPolicy } from "contracts/interfaces/IPolicy.sol";
import { IOwnership } from "contracts/interfaces/IOwnership.sol";
import { ICurrencyManager } from "contracts/interfaces/ICurrencyManager.sol";
import { IBalanceWithdrawable } from "contracts/interfaces/IBalanceWithdrawable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title BasePolicy
/// @notice This abstract contract serves as a base for policies that manage access to content.
/// It defines the use of ownership and rights manager contracts, with validations and access
/// restrictions based on content holders.
abstract contract BasePolicy is Ledger, ReentrancyGuard, IPolicy, IBalanceWithdrawable {
    // Immutable public variables to store the addresses of the Rights Manager and Ownership.
    address public immutable RIGHTS_MANAGER;
    address public immutable OWNERSHIP;

    // Event emitted when a balance is extracted in a specific currency.
    event FundsWithdrawn(address indexed recipient, uint256 amount, address indexed currency);
    /// @dev Error thrown when attempting to access content without proper authorization.
    error InvalidContentHolder();
    error InvalidNoBalanceToWithdraw();

    /// @notice Error thrown when a function is called by an address other than the Rights Manager.
    error InvalidCallOnlyRightsManagerAllowed();

    /// @dev Error thrown when attempting to access unregistered content.
    error InvalidUnknownContent();

    /// @dev Modifier to restrict function calls to the Rights Manager address.
    modifier onlyRM() {
        if (msg.sender != address(RIGHTS_MANAGER)) {
            revert InvalidCallOnlyRightsManagerAllowed();
        }
        _;
    }

    /// @notice Constructor to initialize the Rights Manager and Ownership contract addresses.
    /// @param rightsManagerAddress Address of the Rights Manager contract.
    /// @param ownershipAddress Address of the Ownership contract.
    constructor(address rightsManagerAddress, address ownershipAddress) {
        RIGHTS_MANAGER = rightsManagerAddress; // Assign the Rights Manager address.
        OWNERSHIP = ownershipAddress; // Assign the Ownership address.
    }

    /// @notice Function to receive native coins (e.g., ETH).
    receive() external payable {}

    /// @notice Withdraws tokens from the contract to a specified recipient's address.
    /// @param recipient The address that will receive the withdrawn tokens.
    /// @param amount The amount of tokens to withdraw.
    /// @param currency The currency to associate fees with. Use address(0) for the native coin.
    function withdraw(address recipient, uint256 amount, address currency) external nonReentrant {
        // Calls the Rights Manager to withdraw the specified amount in the given currency.
        if (getLedgerBalance(msg.sender, currency) < amount) revert InvalidNoBalanceToWithdraw();
        // In this case the rights manager allows withdraw funds from policy balance and send it to recipient directly.
        // This happens only if the policy has balance and the sender has registered balance in ledger..
        _subLedgerEntry(msg.sender, amount, currency);
        IBalanceWithdrawable fundsManager = IBalanceWithdrawable(RIGHTS_MANAGER);
        fundsManager.withdraw(recipient, amount, currency);
        emit FundsWithdrawn(recipient, amount, currency);
    }

    /// @notice Returns the content holder registered in the ownership contract.
    /// @param contentId The content ID to retrieve the holder.
    /// @return The address of the content holder.
    function getHolder(uint256 contentId) public view returns (address) {
        return IOwnership(OWNERSHIP).ownerOf(contentId); // Returns the registered owner.
    }

    /// @notice Validates if the rights manager support the currency.
    /// @param currency The currency to check.
    function isValidCurrency(address currency) internal view returns (bool) {
        return ICurrencyManager(RIGHTS_MANAGER).isCurrencySupported(currency);
    }

    // /// @notice Allocates the specified amount across a distribution array and returns the unallocated remaining amount.
    // /// @dev Distributes the amount based on the provided shares array.
    // /// @param amount The total amount to be allocated.
    // /// @param currency The address of the currency being allocated.
    // /// @param shares An array of Splits structs specifying split percentages and target addresses.
    // /// @return The remaining unallocated amount after distribution.
    // function _allocate(
    //     uint256 amount,
    //     address currency,
    //     T.Shares[] memory shares
    // ) private returns (uint256) {
    //     // If there is no distribution, return the full amount.
    //     if (shares.length == 0) return amount;
    //     if (shares.length > 100) {
    //         revert NoDeal(
    //             "Invalid split allocations. Cannot exceed 100."
    //         );
    //     }

    //     uint8 i = 0;
    //     uint256 accBps = 0; // Accumulated base points.
    //     uint256 accTotal = 0; // Accumulated total allocation.

    //     while (i < shares.length) {
    //         // Retrieve base points and target address from the distribution array.
    //         uint256 bps = shares[i].bps;
    //         address target = shares[i].target;
    //         // Safely increment i (unchecked overflow).
    //         unchecked {
    //             ++i;
    //         }

    //         if (bps == 0) continue;
    //         // Calculate and register the allocation for each distribution.
    //         uint256 registeredAmount = amount.perOf(bps);
    //         target.transfer(registeredAmount, currency);
    //         accTotal += registeredAmount;
    //         accBps += bps;
    //     }

    //     // Ensure total base points do not exceed the maximum allowed (100%).
    //     if (accBps > C.BPS_MAX)
    //         revert NoDeal("Invalid split base points overflow.");
    //     return amount - accTotal; // Returns the remaining unallocated amount.
    // }
}
