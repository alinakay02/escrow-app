// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./SellerRating.sol";

/// Логика автоматического разрешения споров по тайм-ауту
contract DisputeResolver {
    SellerRating public ratingContract;

    constructor(address _ratingContract) {
        ratingContract = SellerRating(_ratingContract);
    }

    /// Решение: вернуть ли деньги продавцу?
    /// Если рейтинг есть: avg >= 2.5 true, иначе false  
    /// Если нет оценок: в первый спор true, в последующие false
    function shouldReleaseToSeller(address seller) external returns (bool) {
        uint256 rc = ratingContract.getRatingCount(seller);
        if (rc == 0) {
            // никаких отзывов — смотрим, какой это по счёту спор
            uint256 dc = ratingContract.incrementDisputeCount(seller);
            return (dc == 1);  
        } else {
            uint256 total = ratingContract.getTotalRating(seller);
            // avg >= 2.5  ↔  total*2 >= rc*5
            return (total * 2 >= rc * 5);
        }
    }
}