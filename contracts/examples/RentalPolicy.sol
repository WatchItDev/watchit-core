// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "./IPolicy.sol";
import "./Types.sol";
import "./RightsManager.sol"; // Asumimos que RightsManager es el contrato que tiene el método registerPolicy.

contract RentalPolicy is IPolicy {
    struct Content {
        uint256 rentalDuration; // Duración de la renta en segundos
        uint256 price; // Precio de la renta
    }

    mapping(uint256 => Content) public contents; // Contenidos identificados por contentId
    mapping(address => mapping(uint256 => uint256)) private rentals; // Renta de los usuarios

    RightsManager public rightsManager;

    constructor(address _rightsManager) {
        rightsManager = RightsManager(_rightsManager);
    }

    // Función que retorna el nombre de la política
    function name() external pure override returns (string memory) {
        return "RentalPolicy";
    }

    // Registrar un nuevo contenido disponible para renta
    function registerContent(
        uint256 contentId,
        uint256 rentalDuration,
        uint256 price
    ) external {
        contents[contentId] = Content(rentalDuration, price);
    }

    // Función para que un usuario rente un contenido específico
    function rent(uint256 contentId) external payable {
        Content memory content = contents[contentId];
        require(content.rentalDuration > 0, "Content does not exist");
        require(msg.value >= content.price, "Insufficient funds for rental");

        // Establece la renta del usuario
        rentals[msg.sender][contentId] = block.timestamp + content.rentalDuration;

        // Registra la política en el RightsManager
        rightsManager.registerPolicy{value: msg.value}(contentId, msg.sender);
    }

    // Retorna los términos de acceso para un usuario y un contenido
    function terms(address account, uint256 contentId) external view override returns (bytes memory) {
        return abi.encode(rentals[account][contentId]);
    }

    // Verifica si el usuario tiene una renta activa
    function comply(address account, uint256 contentId) external view override returns (bool) {
        return block.timestamp <= rentals[account][contentId]; // Verifica que la renta no haya expirado
    }

    // Define cómo se manejarán los pagos de renta
    function payouts(address account, uint256 contentId) external view override returns (T.Payouts memory) {
        T.Payouts memory payout;
        payout.t9n.amount = contents[contentId].price; // Precio del contenido
        payout.t9n.currency = address(0); // Asume moneda nativa (ETH)
        payout.s4s = new T.Shares ;
        payout.s4s[0] = T.Shares({account: 0xCreatorAddress, value: 70}); // 70% al creador
        payout.s4s[1] = T.Shares({account: 0xPlatformAddress, value: 30}); // 30% a la plataforma
        return payout;
    }
}
