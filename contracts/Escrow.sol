// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./SellerRating.sol";
import "./DisputeResolver.sol";

contract Escrow is ReentrancyGuard {
    enum State { AWAITING_DELIVERY, DISPUTED, COMPLETE, REFUNDED }

    address payable public buyer;
    address payable public seller;
    address public arbiter;       // может быть 0x0
    uint256 public dealId;
    uint256 public amount;
    uint256 public fee;           // зарезервировано под комиссию
    uint256 public deadline;      // для автоматического тайм-аута спора

    State public currentState;
    uint256 public disputeRaisedAt;
    bool public rated;            // чтобы нельзя было дважды оценить

    SellerRating public ratingContract;
    DisputeResolver public disputeResolver;

    // События
    event DeliveryConfirmed(uint256 dealId);
    event DisputeRaised(uint256 dealId, address raiser);
    event ArbiterChanged(uint256 dealId, address newArbiter);
    event Resolved(uint256 dealId, bool releasedToSeller);
    event TimeoutExecuted(uint256 dealId);

    modifier onlyBuyer() { require(msg.sender == buyer, "Только покупатель"); _; }
    modifier onlySeller() { require(msg.sender == seller, "Только продавец"); _; }
    modifier onlyArbiter() { require(msg.sender == arbiter, "Только арбитр"); _; }
    modifier inState(State s) { require(currentState == s, "Неверный статус"); _; }

    /// @param _ratingContract адрес SellerRating
    /// @param _disputeResolver адрес DisputeResolver
    constructor(
        address _buyer,
        address _seller,
        address _arbiter,
        uint256 _dealId,
        address _ratingContract,
        address _disputeResolver
    ) payable {
        require(msg.value > 0, "Нет депозита");
        buyer = payable(_buyer);
        seller = payable(_seller);
        arbiter = _arbiter;
        dealId = _dealId;
        amount = msg.value;
        fee = 0;
        deadline = 0;  // тайм-аут спора станет актуален только после raiseDispute()
        currentState = State.AWAITING_DELIVERY;

        ratingContract = SellerRating(_ratingContract);
        disputeResolver = DisputeResolver(_disputeResolver);
    }

    /// @notice Покупатель подтверждает получение: перевод продавцу
    function confirmDelivery()
        external nonReentrant onlyBuyer inState(State.AWAITING_DELIVERY)
    {
        currentState = State.COMPLETE;
        _payout(seller, amount - fee);
        emit DeliveryConfirmed(dealId);
    }

    /// @notice Поднять спор до подтверждения доставки
    function raiseDispute()
        external inState(State.AWAITING_DELIVERY)
    {
        require(msg.sender == buyer || msg.sender == seller, "Не участник");
        currentState = State.DISPUTED;
        disputeRaisedAt = block.timestamp + 30 days;
        emit DisputeRaised(dealId, msg.sender);
    }

    /// @notice Сменить арбитра до момента разрешения
    function setArbiter(address newArbiter)
        external inState(State.AWAITING_DELIVERY)
    {
        require(msg.sender == buyer || msg.sender == seller, "Не участник");
        arbiter = newArbiter;
        emit ArbiterChanged(dealId, newArbiter);
    }

    /// @notice Арбитр ручной резолв, до 30 дней
    function resolve(bool releaseToSeller)
        external nonReentrant onlyArbiter inState(State.DISPUTED)
    {
        currentState = State.COMPLETE;
        address payable recipient = releaseToSeller ? seller : buyer;
        _payout(recipient, amount - fee);
        emit Resolved(dealId, releaseToSeller);
    }

    /// @notice Авто-резолв после 30 дней с момента raiseDispute()
    function autoResolve()
        external nonReentrant inState(State.DISPUTED)
    {
        require(block.timestamp >= disputeRaisedAt, "Ещё не истёк срок спора");
        bool toSeller = disputeResolver.shouldReleaseToSeller(seller);
        currentState = State.COMPLETE;
        address payable recipient = toSeller ? seller : buyer;
        _payout(recipient, amount - fee);
        emit Resolved(dealId, toSeller);
    }

    /// @notice Единожды покупатель может поставить рейтинг (1–5) после COMPLETE
    function leaveRating(uint8 rating)
        external
    {
        require(msg.sender == buyer, "Только покупатель");
        require(currentState == State.COMPLETE, "Не завершено");
        require(!rated, "Уже оценено");
        ratingContract.submitRating(seller, rating);
        rated = true;
    }

    /// @notice Внутренняя выплата
    function _payout(address payable to, uint256 payoutAmount) internal {
        require(address(this).balance >= payoutAmount, "Недостаточно средств");
        to.transfer(payoutAmount);
    }

    /// @notice Для фронтенда: просмотр всех деталей
    function getDetails() external view returns (
        address, address, address, uint256, uint256, State, uint256
    ) {
        return (
            buyer, seller, arbiter, dealId, amount, currentState, disputeRaisedAt
        );
    }
}