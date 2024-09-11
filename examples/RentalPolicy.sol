// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "contracts/base/BasePolicy.sol";
import "contracts/interfaces/IPolicy.sol";
import "contracts/libraries/Types.sol";
import "contracts/libraries/TreasuryHelper.sol";

/// @title RentalPolicy
/// @notice This contract implements the IPolicy interface to manage content rental terms.
/// It allows for registering content with rental durations and prices and handles the rental process.
contract RentalPolicy is BasePolicy, IPolicy {
    using TreasuryHelper for address;

    /// @dev Structure to hold rental details for content.
    struct Content {
        uint256 rentalDuration; // Duration in seconds for which content is rented.
        uint256 price; // Price to rent the content.
    }

    // Mapping to store content data by content ID.
    mapping(uint256 => Content) public contents;

    // Mapping to track rental expiration timestamps for each account and content.
    mapping(address => mapping(uint256 => uint256)) private rentals;

    /// @notice Constructor for the RentalPolicy contract.
    /// @param rmAddress Address of the Rights Manager (RM) contract.
    /// @param ownershipAddress Address of the Ownership contract.
    constructor(
        address rmAddress,
        address ownershipAddress
    ) BasePolicy(rmAddress, ownershipAddress) {}

    /// @notice Returns the name of the policy.
    /// @return The name of the policy, "RentalPolicy".
    function name() external pure override returns (string memory) {
        return "RentalPolicy";
    }

    /// @notice Returns the business/strategy model implemented by the policy.
    /// @return A detailed description of the policy's rental model.
    function description() external pure override returns (bytes memory) {
        return
            abi.encodePacked(
                "The RentalPolicy implements a content rental strategy where users pay a fixed fee to access digital content "
                "for a limited period. The strategy is focused on temporary access, allowing content holders to monetize their assets "
                "through short-term rentals without transferring full ownership. Key aspects of this policy include: \n\n"
                "1) Flexible rental duration: Each content can have a customized rental period defined by the content holder. \n"
                "2) Pay-per-use model: Users pay a one-time fee per rental, providing a cost-effective way to access content without a long-term commitment.\n "
                "3) Automated rental management: Once the rental fee is paid, the content becomes accessible to the user for the specified duration,\n "
                "after which access is automatically revoked.\n "
                "4) Secure revenue distribution: The rental fee is transferred directly to the content holder through the TreasuryHelper, ensuring secure and \n"
                "timely payments. This policy provides a straightforward and transparent way for content owners to generate revenue from their digital assets \n"
                "while giving users temporary access to premium content."
            );
    }

    /// @notice Registers content with rental terms including duration and price.
    /// @dev Only callable for registered content IDs.
    /// @param contentId The ID of the content to register.
    /// @param rentalDuration Duration (in seconds) for which the content will be rented.
    /// @param price The price to rent the content.
    function registerContent(
        uint256 contentId,
        uint256 rentalDuration,
        uint256 price
    ) external onlyRegisteredContent(contentId) {
        contents[contentId] = Content(rentalDuration, price);
    }

    /// @dev Internal function to register the rental of content for a specific account.
    /// @param account The address of the account renting the content.
    /// @param contentId The ID of the content being rented.
    /// @param expire The expiration time (in seconds) for the rental.
    function _registerRent(
        address account,
        uint256 contentId,
        uint256 expire
    ) private {
        rentals[account][contentId] = block.timestamp + expire;
    }

    /// @notice Executes the deal between the content holder and the account based on the policy's rules.
    /// @dev This function is expected to be called only by the Rights Manager (RM) contract.
    /// It handles any logic related to access and validation of the rental terms.
    /// @param deal The deal object containing the agreed terms between the content holder and the account.
    /// @param data Additional data required for processing the deal, e.g., content ID.
    /// @return bool Indicates whether the deal was successfully executed.
    /// @return string Provides a message describing the result of the execution.
    function exec(
        T.Deal calldata deal,
        bytes calldata data
    ) external onlyRM returns (bool, string memory) {
        uint256 contentId = abi.decode(data, (uint256));
        Content memory content = contents[contentId];

        if (contentId == 0) return (false, "Invalid content ID");
        if (getHolder(contentId) != deal.holder)
            return (false, "Invalid content ID holder");
        if (deal.total < content.price)
            return (false, "Insufficient funds for rental");

        // Transfer the funds to the content holder.
        deal.holder.transfer(deal.available, deal.currency);
        // Register the rental for the account with the rental duration.
        _registerRent(deal.account, contentId, content.rentalDuration);

        return (true, "Rental successfully executed");
    }

    /// @notice Retrieves the access terms for a specific account and content ID.
    /// @param account The address of the account for which access terms are being retrieved.
    /// @param contentId The ID of the content associated with the access terms.
    /// @return The access terms as a `bytes` array, which can contain the rental expiration timestamp.
    function terms(
        address account,
        uint256 contentId
    ) external view override returns (bytes memory) {
        return abi.encode(rentals[account][contentId]);
    }

    /// @notice Verifies whether the on-chain access terms for an account and content ID are satisfied.
    /// @param account The address of the account to check.
    /// @param contentId The ID of the content to check against.
    /// @return bool Returns `true` if the rental period is still valid, `false` otherwise.
    function comply(
        address account,
        uint256 contentId
    ) external view override returns (bool) {
        // Check if the current time is before the rental expiration.
        return block.timestamp <= rentals[account][contentId];
    }
}
