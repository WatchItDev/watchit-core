pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "contracts/base/upgradeable/ContentVaultUpgradeable.sol";

contract ContentVault is Test, ContentVaultUpgradeable {
    function test_secureShortContent() public {
        string memory plain = "5f67abaf5210722b4db03508e65f8bb3";
        bytes memory cypherBytes = abi.encode(plain);
        _secureContent(1, cypherBytes);

        bytes memory secured = getSecuredContent(1);
        string memory decoded = abi.decode(secured, (string));
        assertEq(cypherBytes, secured);
        assertEq(plain, decoded);
    }

    function test_secureLITContent() public {
        // example storing LIT in format: chain.ciphertext.dataToEncryptHash
        // This data is needed in decryption process and obtained during encryption.
        // https://developer.litprotocol.com/sdk/access-control/quick-start#encryption
        // https://developer.litprotocol.com/sdk/access-control/quick-start#decryption
        string
            memory plain = "ethereum.dGVzdF9zZWN1cmVMb25nQ29udGVudF93YXRjaGl0X3Byb3RvY29sX3ZhdWx0c3RvcmFnZQ==.4Kw2DRwEmqK25fOi4bnJ6KLgs8O5gpmxu25VfAUBXXQ=";
        bytes memory cypherBytes = abi.encode(plain);
        _secureContent(1, cypherBytes);

        bytes memory secured = getSecuredContent(1);
        string memory decoded = abi.decode(secured, (string));
        assertEq(cypherBytes, secured);
        assertEq(plain, decoded);
    }

    function test_secureRSAContent() public {
        string
            memory plain = "8c7e50310a8fc4be1bbadfcd8e9359c8b304dbd96dbe1f5b8ee5b8a249b19fc8403e80aeb2a4b9ebec50fabe98b6e632858571aeb4bde8de2a6471d9a41b1b7c5082d2f2";
        bytes memory cypherBytes = abi.encode(plain);
        _secureContent(1, cypherBytes);

        bytes memory secured = getSecuredContent(1);
        string memory decoded = abi.decode(secured, (string));
        assertEq(cypherBytes, secured);
        assertEq(plain, decoded);
    }

    function test_secureChachapolyContent() public {
        // nonce.tag.cyphertext
        string
            memory plain = "e4bfc4a68d3017c1c50cbb65.f579fc8e4f8e917127cd6d10a85ccbf2.976f64c6011a0a94b9495c1bcf5e7e4ecff4c4e1e9f5293d59b19670f7e945a8a3f1b5045fbe7255ec3d41b5";
        bytes memory cypherBytes = abi.encode(plain);
        _secureContent(1, cypherBytes);

        bytes memory secured = getSecuredContent(1);
        string memory decoded = abi.decode(secured, (string));
        assertEq(cypherBytes, secured);
        assertEq(plain, decoded);
    }

    function test_secureAESContent() public {
        // nonce.tag.cyphertext
        string
            memory plain = "2b2e31fc7c0e47818e18d12b.724f1e73e41f6c5e8bc14a7c6f4d481d.3c4a42b0fcd3e4d5856f8e55b5e8f7e45ac8e58ed8bde3b7d1c58bd74eb3d407ab59b252de04a8c390bbd5";
        bytes memory cypherBytes = abi.encode(plain);
        _secureContent(1, cypherBytes);

        bytes memory secured = getSecuredContent(1);
        string memory decoded = abi.decode(secured, (string));
        assertEq(cypherBytes, secured);
        assertEq(plain, decoded);
    }
}
