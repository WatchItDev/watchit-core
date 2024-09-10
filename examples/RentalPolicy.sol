// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "contracts/base/BasePolicy.sol";
import "contracts/interfaces/IPolicy.sol";
import "contracts/libraries/Types.sol";
import "contracts/libraries/TreasuryHelper.sol";

contract RentalPolicy is BasePolicy, IPolicy {
    using TreasuryHelper for address;

    struct Content {
        uint256 rentalDuration;
        uint256 price;
    }

    mapping(uint256 => Content) public contents;
    mapping(address => mapping(uint256 => uint256)) private rentals;

    constructor(
        address rmAddress,
        address ownershipAddress
    ) BasePolicy(rmAddress, ownershipAddress) {}

    function name() external pure override returns (string memory) {
        return "RentalPolicy";
    }

    function registerContent(
        uint256 contentId,
        uint256 rentalDuration,
        uint256 price
    ) external onlyRegisteredContent(contentId) {
        contents[contentId] = Content(rentalDuration, price);
    }

    function _registerRent(
        address account,
        uint256 contentId,
        uint256 expire
    ) private {
        // setup renting condition..
        rentals[account][contentId] = block.timestamp + expire;
    }

    /// @notice Exec the deal between the content holder and the account based on the policy's rules.
    /// @dev This method is expected to be called only by RM contract and its used to establish
    /// any logic related to access, validations, etc...
    /// @param deal The deal object containing the terms agreed upon between the content holder and the account.
    /// @param data Additional data required for processing the deal.
    /// @return bool A boolean indicating whether the deal was successfully executed (`true`) or not (`false`).
    /// @return string A message providing context for the execution result.
    function exec(
        T.Deal calldata deal,
        bytes calldata data
    ) external onlyRM returns (bool, string memory) {
        uint256 contentId = abi.decode(data, (uint256));
        Content memory content = contents[contentId];

        if (contentId == 0) return (false, "Invalid content id");
        if (getHolder(contentId) != deal.holder)
            return (false, "Invalid content id holder");
        if (deal.total < content.price)
            return (false, "Insufficient funds for rental");

        // The rigths manager send funds to policy before call this method
        // then the logic of distribution could be here...
        // example transfering all the revenues to content holder..
        deal.holder.transfer(deal.available, deal.currency);
        _registerRent(deal.account, contentId, content.rentalDuration);
        return (true, "ok");
    }

    /// @notice Retrieves the access terms for a specific account and content ID.
    /// @param account The address of the account for which access terms are being retrieved.
    /// @param contentId The ID of the content associated with the access terms.
    /// @return The access terms as a `bytes` array, which can contain any necessary data
    /// for validating on-chain or off-chain access. eg: PILTerms https://docs.story.foundation/docs/pil-terms
    function terms(
        address account,
        uint256 contentId
    ) external view override returns (bytes memory) {
        // any data needed to validate by distributors can be returned here..
        return abi.encode(rentals[account][contentId]);
    }

    /// @notice Verify whether the on-chain access terms for an account and content ID are satisfied.
    /// @param account The address of the account to check.
    /// @param contentId The content ID to check against.
    function comply(
        address account,
        uint256 contentId
    ) external view override returns (bool) {
        // the condition to validate access to content by the account..
        return block.timestamp <= rentals[account][contentId];
    }
}
