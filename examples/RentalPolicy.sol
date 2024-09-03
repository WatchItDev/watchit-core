// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "contracts/base/RMRestricted.sol";
import "contracts/interfaces/IPolicy.sol";
import "contracts/libraries/Types.sol";

contract RentalPolicy is RMRestricted, IPolicy {
    struct Content {
        uint256 rentalDuration; // Duración de la renta en segundos
        uint256 price; // Precio de la renta
    }

    mapping(uint256 => Content) public contents; // Contenidos identificados por contentId
    mapping(address => mapping(uint256 => uint256)) private rentals; // Renta de los usuarios

    constructor(
        address rmAddress,
        address ownershipAddress
    ) RMRestricted(rmAddress, ownershipAddress) {}

    // Función que retorna el nombre de la política
    function name() external pure override returns (string memory) {
        return "RentalPolicy";
    }

    // Registrar un nuevo contenido disponible para renta
    function registerContent(
        uint256 contentId,
        uint256 rentalDuration,
        uint256 price
    ) external onlyRegisteredContent(contentId) {
        contents[contentId] = Content(rentalDuration, price);
    }

    // this function shopuld be called only by DRM and its used to establish
    // any logic needed to authorize the user
    function process(
        T.Deal calldata deal,
        bytes calldata data
    ) external onlyRM returns (bool, string memory) {
        uint256 contentId = abi.decode(data, (uint256));
        Content memory content = contents[contentId];
            
        if (!isValidHolder(contentId, deal.holder))
            return (false, "Invalid content id holder");
        if (deal.total < content.price)
            return (false, "Insufficient funds for rental");

        // Establece la renta del usuario
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
        return block.timestamp <= rentals[account][contentId]; // Verifica que la renta no haya expirado
    }

    function shares() external view returns (T.Shares[] memory) {
        T.Shares[] memory payout = new T.Shares[](0);
        // payout.s4s[0] = T.Shares({account: 0xCreatorAddress, value: 70}); // 70% al creador
        // payout.s4s[1] = T.Shares({account: 0xPlatformAddress, value: 30}); // 30% a la plataforma
        return payout;
    }
}
