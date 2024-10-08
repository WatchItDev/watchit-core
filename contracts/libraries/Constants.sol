// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html
pragma solidity 0.8.26;

library C {
    // We can not operate with float so we use base points instead..
    // If we need more precision we can adjust this bps..
    // https://en.wikipedia.org/wiki/Basis_point
    // 1 bps = 0.01, 10 bps = 0.1
    // ...
    uint8 public constant SCALE_FACTOR = 100;
    uint16 public constant BPS_MAX = 10_000;

    bytes32 internal constant REFERENDUM_SUBMIT_TYPEHASH =
        keccak256("Submission(uint256 contentId, address initiator, uint256 nonce)");
}
