// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "contracts/libraries/Types.sol";

interface IRightsAgreementBroker {
    /// @notice Retrieves a agreement associated with the given proof.
    /// @param proof The unique identifier of the agreement to retrieve.
    /// @return agreement The agreement object associated with the provided proof.
    function getAgreement(bytes32 proof) external view returns (T.Agreement memory);

    /// @notice Creates a new agreement between the account and the content holder, returning a unique agreementidentifier.
    /// @param total The total amount involved in the agreement.
    /// @param currency The address of the ERC20 token (or native currency) being used in the agreement.
    /// @param holder The address of the content holder whose content is being accessed.
    /// @param account The address of the account proposing the agreement.
    /// @return bytes32 A unique identifier (agreementProof) representing the created agreement.
    function createAgreement(
        uint256 total,
        address currency,
        address holder,
        address account
    ) external returns (bytes32);

}
