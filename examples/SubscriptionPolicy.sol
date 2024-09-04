// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "contracts/base/BasePolicy.sol";
import "contracts/interfaces/IPolicy.sol";
import "contracts/libraries/Types.sol";

contract SubscriptionPolicy is IPolicy {
    struct Package {
        uint256 subscriptionDuration; 
        uint256 price;
    }

    mapping(address => Package) public packages;
    mapping(address => mapping(address => uint256)) private subscriptions; 

    constructor(
        address rmAddress,
        address ownershipAddress
    ) RMRestricted(rmAddress, ownershipAddress) {}

    // Función que retorna el nombre de la política
    function name() external pure override returns (string memory) {
        return "SubscriptionPolicy";
    }

    function registerPackage(
        uint256 subscriptionDuration,
        uint256 price
    ) external {
        require(subscriptionDuration > 0);
        require(price > 0);
        // only native token is approached in this example
        // expected content rights holder sending subscription params..
        packages[msg.sender] = Package(subscriptionDuration, price);
    }

    // this function shopuld be called only by DRM and its used to establish
    // any logic or validation needed to set the authorization parameters
    function exec(
        T.Deal calldata deal,
        bytes calldata
    ) external onlyRM returns (bool, string memory) {
        Package memory pkg = packages[deal.holder];

        if (deal.total < pck.price)
            return (false, "Insufficient funds for subscription");

        // Establece la renta del usuario
        uint256 subTime = block.timestamp + pck.subscriptionDuration;
        // subscribe to content owner catalog (content package)
        subscriptions[deal.account][deal.holder] = subTime;
        return (true, "success");
    }

    function terms(
        address account,
        uint256 contentId
    ) external view override returns (bytes memory) {
        address holder = getHolder(contentId);
        return abi.encode(packages[holder]);
    }

    function comply(
        address account,
        uint256 contentId
    ) external view override returns (bool) {
        address holder = getHolder(contentId);
        return block.timestamp <= subscriptions[account][holder]; 
    }

    // Define cómo se manejarán los pagos de suscripción
    function shares(
        address account,
        uint256 contentId
    ) external view override returns (T.Shares[] memory) {}
}
