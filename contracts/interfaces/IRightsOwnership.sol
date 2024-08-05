// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html
pragma solidity ^0.8.24;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface IRightsOwnership is IERC721, IERC721Metadata {
    /// @notice Mints a new NFT to the specified address.
    /// @dev Our naive assumption is that only those who know the CID hash can mint the corresponding token.
    function mint(address, uint256) external;
}
