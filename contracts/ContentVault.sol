// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "contracts/base/ContentVaultUpgradeable.sol";


// TODO upgradeable y inicializar con DRM
contract ContentVault is ContentVaultUpgradeable {

    
    function storeSecureContent(contentId, encryptedContent) public {

    }

    function getSecureContent(contentId, encryptedContent) {}
}
