// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "contracts/interfaces/IPolicy.sol";
import "contracts/base/RMRestricted.sol";
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
    ) external {
        contents[contentId] = Content(rentalDuration, price);
    }

    // Función para que un usuario rente un contenido específico
    function process(T.Deal calldata deal, bytes calldata data) external onlyRM returns (bool, string memory) {
        uint256 memory contentId = abi.decode(data, (uint256));
        Content memory content = contents[contentId];
        if(content.rentalDuration <= 0) return (false, "Content does not exist");
        if(deal.total < content.price) return (false, "Insufficient funds for rental");

        // Establece la renta del usuario
        rentals[msg.sender][contentId] = block.timestamp + content.rentalDuration;
        return (true, "success");
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
    function payouts() external view override returns (T.Payouts memory) {
        payout.s4s = new T.Shares ;
        payout.s4s[0] = T.Shares({account: 0xCreatorAddress, value: 70}); // 70% al creador
        payout.s4s[1] = T.Shares({account: 0xPlatformAddress, value: 30}); // 30% a la plataforma
        return payout;
    }
}
