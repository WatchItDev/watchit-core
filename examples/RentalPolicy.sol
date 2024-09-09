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

    // this function should be called only by RM and its used to establish
    // any logic or validation needed to set the authorization parameters
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
        deal.holder.transfer(deal.available, deal.currency);
        // setup renting condition..
        rentals[deal.account][contentId] =
            block.timestamp +
            content.rentalDuration;
        return (true, "success");
    }

    function terms(
        address account,
        uint256 contentId
    ) external view override returns (bytes memory) {
        return abi.encode(rentals[account][contentId]);
    }

    function comply(
        address account,
        uint256 contentId
    ) external view override returns (bool) {
        return block.timestamp <= rentals[account][contentId];
    }
}
