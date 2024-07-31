// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html
pragma solidity ^0.8.24;

library THash {
    bytes32 private constant REFERENDUM_SUBMIT_TYPEHASH =
        keccak256("Submission(uint256 contentId, address initiator, uint256 nonce,uint256 deadline)");

}