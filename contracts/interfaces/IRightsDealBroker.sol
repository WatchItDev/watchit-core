// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "contracts/libraries/Types.sol";

interface IRightsDealBroker {
    /// @notice Retrieves a deal associated with the given proof.
    /// @param proof The unique identifier of the deal to retrieve.
    /// @return deal The deal object associated with the provided proof.
    function getDeal(bytes32 proof) external view returns (T.Deal memory);

    /// @notice Creates a new deal between the account and the content holder, returning a unique deal identifier.
    /// @param total The total amount involved in the deal.
    /// @param currency The address of the ERC20 token (or native currency) being used in the deal.
    /// @param holder The address of the content holder whose content is being accessed.
    /// @param account The address of the account proposing the deal.
    /// @return bytes32 A unique identifier (dealProof) representing the created deal.
    function createDeal(
        uint256 total,
        address currency,
        address holder,
        address account
    ) external returns (bytes32);

    /// @notice Finalizes the deal by registering the agreed-upon policy, effectively closing the deal.
    /// @dev This function verifies the policy's authorization, executes the deal, processes financial transactions,
    ///      and registers the policy in the system, representing the formal closure of the deal.
    /// @param dealProof The unique identifier of the deal to be enforced.
    /// @param policyAddress The address of the policy contract managing the deal.
    /// @param data Additional data required to execute the deal.
    function closeDeal(
        bytes32 dealProof,
        address policyAddress,
        bytes calldata data
    ) external payable;

    /// @notice Calculates the fees for both the treasury and the distributor based on the provided total amount.
    /// @param total The total amount involved in the transaction.
    /// @param currency The address of the ERC20 token (or native currency) being used in the transaction.
    /// @param holder The address of the content holder whose content is being accessed.
    /// @return treasury The calculated fee for the treasury.
    /// @return distribution The calculated fee for the distributor.
    function calcFees(
        uint256 total,
        address currency,
        address holder
    ) external returns (uint256, uint256);
}
