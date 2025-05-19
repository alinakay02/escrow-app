// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Escrow.sol";

/// Фабрика сделок, хранит ссылки
contract EscrowFactory {
    uint256 public dealCount;
    mapping(uint256 => address) public escrows;

    // индексы сделок по ролям
    mapping(address => uint256[]) public dealsByBuyer;
    mapping(address => uint256[]) public dealsBySeller;
    mapping(address => uint256[]) public dealsByArbiter;

    address public ratingContract;
    address public disputeResolver;

    event DealCreated(
        uint256 indexed dealId,
        address indexed buyer,
        address indexed seller,
        address arbiter,
        address escrowAddress,
        uint256 amount
    );

    constructor(address _ratingContract, address _disputeResolver) {
        ratingContract = _ratingContract;
        disputeResolver = _disputeResolver;
    }

    /// Покупатель создаёт сделку, сразу депонируя ETH
    function createDeal(address seller, address arbiter) external payable returns (uint256) {
        require(msg.value > 0, "Нужно положить сумму");
        dealCount++;

        Escrow esc = new Escrow{ value: msg.value }(
            msg.sender,
            seller,
            arbiter,
            dealCount,
            ratingContract,
            disputeResolver
        );
        address escAddr = address(esc);

        escrows[dealCount] = escAddr;
        dealsByBuyer[msg.sender].push(dealCount);
        dealsBySeller[seller].push(dealCount);
        if (arbiter != address(0)) {
            dealsByArbiter[arbiter].push(dealCount);
        }

        emit DealCreated(dealCount, msg.sender, seller, arbiter, escAddr, msg.value);
        return dealCount;
    }

    // Геттеры для фронтенда
    function getDealsOfBuyer(address b) external view returns (uint256[] memory) {
        return dealsByBuyer[b];
    }
    function getDealsOfSeller(address s) external view returns (uint256[] memory) {
        return dealsBySeller[s];
    }
    function getDealsOfArbiter(address a) external view returns (uint256[] memory) {
        return dealsByArbiter[a];
    }
}