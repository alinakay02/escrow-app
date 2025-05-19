// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title Хранение рейтингов продавцов и учёт споров
contract SellerRating {
    // суммарные оценки и количество оценок по каждому продавцу
    mapping(address => uint256) public totalRating;
    mapping(address => uint256) public ratingCount;
    // сколько споров уже было по каждому продавцу
    mapping(address => uint256) public disputeCount;

    event RatingSubmitted(address indexed seller, uint8 rating, uint256 newCount);
    event DisputeLogged(address indexed seller, uint256 newDisputeCount);

    /// @notice Запись рейтинга (1–5) от любого контракта
    function submitRating(address seller, uint8 rating) external {
        require(rating >= 1 && rating <= 5, "Rating must be 1-5");
        totalRating[seller] += rating;
        ratingCount[seller] += 1;
        emit RatingSubmitted(seller, rating, ratingCount[seller]);
    }

    /// @notice Логируем факт нового спора, возвращаем обновлённое число
    function incrementDisputeCount(address seller) external returns (uint256) {
        disputeCount[seller] += 1;
        emit DisputeLogged(seller, disputeCount[seller]);
        return disputeCount[seller];
    }

    function getRatingCount(address seller) external view returns (uint256) {
        return ratingCount[seller];
    }
    function getTotalRating(address seller) external view returns (uint256) {
        return totalRating[seller];
    }
    function getDisputeCount(address seller) external view returns (uint256) {
        return disputeCount[seller];
    }
}
