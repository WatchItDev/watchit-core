// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;
import { T } from "contracts/libraries/Types.sol";

/// @title IRightsManagerBroker
/// @notice Interface for managing agreements related to content rights.
/// @dev This interface handles the creation, retrieval, and execution of agreements within the RightsManager context.
interface IRightsManagerBroker {
    /// @notice Retrieves an agreement associated with the given proof.
    /// @param proof The unique identifier of the agreement to retrieve.
    /// @return agreement The agreement object associated with the provided proof.
    function getAgreement(bytes32 proof) external view returns (T.Agreement memory);

    /// @notice Creates a new agreement between the account and the content holder, returning a unique agreement identifier.
    /// @param total The total amount involved in the agreement.
    /// @param currency The address of the ERC20 token (or native currency) being used in the agreement.
    /// @param holder The address of the content holder whose content is being accessed.
    /// @param account The address of the account proposing the agreement.
    /// @param data Additional data required to execute the policy.
    /// @return bytes32 A unique identifier (agreementProof) representing the created agreement.
    function createAgreement(
        uint256 total,
        address currency,
        address holder,
        address account,
        bytes calldata data
    ) external returns (bytes32);

    /// @notice Executes the creation of an agreement and immediately registers the policy in a single transaction.
    /// @param total The total amount involved in the agreement.
    /// @param currency The address of the ERC20 token (or native currency) used in the transaction.
    /// @param holder The address of the content rights holder whose content is being accessed.
    /// @param account The address of the user or account proposing the agreement.
    /// @param policyAddress The address of the policy contract managing the agreement.
    /// @param data Additional data required to execute the policy.
    /// @return bytes32 A unique identifier (agreementProof) representing the executed agreement.
    function flashAgreement(
        uint256 total,
        address currency,
        address holder,
        address account,
        address policyAddress,
        bytes calldata data
    ) external payable returns (bytes32);
}
