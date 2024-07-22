// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title IContentVault
/// @notice Interface for a content vault that manages secured content.
/// @dev This interface defines the methods to retrieve and secure content.
interface IContentVault {
    /// @notice Retrieves the secured content for a given content ID.
    /// @dev Returns the encrypted content stored in the vault.
    /// @param contentId The ID of the content to retrieve.
    /// @return The encrypted content as a bytes array.
    function getSecuredContent(
        uint256 contentId
    ) external view returns (bytes memory);

    /// @notice Secures content in the vault.
    /// @dev Stores the encrypted content associated with the given content ID. 
    /// The secured content could be any content that utilizes an off-chain encryption schema, 
    /// e.g., LIT ciphertext + cypherhash, public key encrypted data, shared key encrypted data.
    /// @param contentId The ID of the content to secure.
    /// @param encryptedContent The encrypted content to store.
    function secureContent(
        uint256 contentId,
        bytes calldata encryptedContent
    ) external;
}
