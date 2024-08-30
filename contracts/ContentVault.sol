// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "contracts/interfaces/IContentVault.sol";

// TODO upgradeable y inicializar con DRM
contract ContentVault is Initializable, IContentVault {
    mapping(uint256 => bytes) secured; // Mapping to store encrypted content by content ID

    /// @notice Returns the encrypted content for a given content ID.
    /// @param contentId The identifier of the content.
    /// @return The encrypted content as bytes.
    function getContent(uint256 contentId) public view returns (bytes memory) {
        return secured[contentId];
    }

    /// @notice Stores encrypted content in the vault.
    /// @param contentId The identifier of the content.
    /// @param encryptedContent The encrypted content to store.
    /// @dev This function allows storing any secured data as bytes, enabling dynamic secure data storage.
    /// For example: LIT chain.ciphertext.dataToEncryptHash combination, public key encrypted data,
    /// shared key encrypted data, etc.
    function setContent(
        uint256 contentId,
        bytes memory encryptedContent
    ) public {
        secured[contentId] = encryptedContent;
    }
}
