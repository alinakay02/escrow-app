// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title EscrowMarketplace
 * @dev Main contract for managing escrow transactions between buyers and sellers
 */
contract EscrowMarketplace is ReentrancyGuard, AccessControl, Pausable {
    bytes32 public constant ARBITRATOR_ROLE = keccak256("ARBITRATOR_ROLE");
    
    enum TransactionStatus {
        Created,
        Funded,
        Delivered,
        Completed,
        Disputed,
        Refunded,
        Cancelled
    }

    struct Transaction {
        uint256 id;
        address payable seller;
        address payable buyer;
        uint256 amount;
        string description;
        TransactionStatus status;
        uint256 createdAt;
        address arbitrator;
        bool isArbitratorAssigned;
        mapping(address => bool) hasConfirmed;
    }

    uint256 private _transactionCounter;
    mapping(uint256 => Transaction) public transactions;
    mapping(address => uint256[]) public userTransactions;
    
    // Events
    event TransactionCreated(
        uint256 indexed id,
        address indexed seller,
        address indexed buyer,
        uint256 amount,
        string description
    );
    event TransactionFunded(uint256 indexed id, uint256 amount);
    event TransactionDelivered(uint256 indexed id);
    event TransactionCompleted(uint256 indexed id);
    event TransactionDisputed(uint256 indexed id);
    event TransactionRefunded(uint256 indexed id);
    event TransactionCancelled(uint256 indexed id);
    event ArbitratorAssigned(uint256 indexed id, address indexed arbitrator);
    event ArbitratorDecision(uint256 indexed id, bool favorsBuyer);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    modifier onlyBuyer(uint256 _transactionId) {
        require(
            transactions[_transactionId].buyer == msg.sender,
            "Only buyer can call this function"
        );
        _;
    }

    modifier onlySeller(uint256 _transactionId) {
        require(
            transactions[_transactionId].seller == msg.sender,
            "Only seller can call this function"
        );
        _;
    }

    modifier onlyArbitrator(uint256 _transactionId) {
        require(
            transactions[_transactionId].arbitrator == msg.sender && 
            hasRole(ARBITRATOR_ROLE, msg.sender),
            "Only assigned arbitrator can call this function"
        );
        _;
    }

    modifier transactionExists(uint256 _transactionId) {
        require(
            transactions[_transactionId].createdAt != 0,
            "Transaction does not exist"
        );
        _;
    }

    function createTransaction(
        address payable _buyer,
        string memory _description
    ) external whenNotPaused returns (uint256) {
        require(_buyer != msg.sender, "Seller cannot be buyer");
        require(_buyer != address(0), "Invalid buyer address");

        uint256 newTransactionId = _transactionCounter++;
        Transaction storage newTx = transactions[newTransactionId];
        
        newTx.id = newTransactionId;
        newTx.seller = payable(msg.sender);
        newTx.buyer = _buyer;
        newTx.description = _description;
        newTx.status = TransactionStatus.Created;
        newTx.createdAt = block.timestamp;
        
        userTransactions[msg.sender].push(newTransactionId);
        userTransactions[_buyer].push(newTransactionId);

        emit TransactionCreated(
            newTransactionId,
            msg.sender,
            _buyer,
            0,
            _description
        );

        return newTransactionId;
    }

    function fundTransaction(uint256 _transactionId) 
        external 
        payable 
        whenNotPaused
        transactionExists(_transactionId)
        onlyBuyer(_transactionId)
    {
        Transaction storage transaction = transactions[_transactionId];
        require(
            transaction.status == TransactionStatus.Created,
            "Transaction cannot be funded"
        );
        require(msg.value > 0, "Amount must be greater than 0");

        transaction.amount = msg.value;
        transaction.status = TransactionStatus.Funded;

        emit TransactionFunded(_transactionId, msg.value);
    }

    function confirmDelivery(uint256 _transactionId)
        external
        whenNotPaused
        transactionExists(_transactionId)
        onlyBuyer(_transactionId)
    {
        Transaction storage transaction = transactions[_transactionId];
        require(
            transaction.status == TransactionStatus.Funded,
            "Transaction is not in funded state"
        );

        transaction.status = TransactionStatus.Delivered;
        emit TransactionDelivered(_transactionId);
    }

    function releasePayment(uint256 _transactionId)
        external
        whenNotPaused
        transactionExists(_transactionId)
        onlyBuyer(_transactionId)
    {
        Transaction storage transaction = transactions[_transactionId];
        require(
            transaction.status == TransactionStatus.Delivered,
            "Transaction is not in delivered state"
        );

        transaction.status = TransactionStatus.Completed;
        (bool success, ) = transaction.seller.call{value: transaction.amount}("");
        require(success, "Transfer failed");

        emit TransactionCompleted(_transactionId);
    }

    function initiateDispute(uint256 _transactionId)
        external
        whenNotPaused
        transactionExists(_transactionId)
    {
        Transaction storage transaction = transactions[_transactionId];
        require(
            msg.sender == transaction.buyer || msg.sender == transaction.seller,
            "Only buyer or seller can initiate dispute"
        );
        require(
            transaction.status == TransactionStatus.Funded ||
            transaction.status == TransactionStatus.Delivered,
            "Transaction cannot be disputed"
        );

        transaction.status = TransactionStatus.Disputed;
        emit TransactionDisputed(_transactionId);
    }

    function assignArbitrator(uint256 _transactionId, address _arbitrator)
        external
        whenNotPaused
        transactionExists(_transactionId)
    {
        Transaction storage transaction = transactions[_transactionId];
        require(
            msg.sender == transaction.buyer || msg.sender == transaction.seller,
            "Only buyer or seller can assign arbitrator"
        );
        require(
            transaction.status == TransactionStatus.Disputed,
            "Transaction must be disputed"
        );
        require(
            hasRole(ARBITRATOR_ROLE, _arbitrator),
            "Address is not an arbitrator"
        );
        require(
            !transaction.isArbitratorAssigned,
            "Arbitrator already assigned"
        );

        transaction.arbitrator = _arbitrator;
        transaction.isArbitratorAssigned = true;
        
        emit ArbitratorAssigned(_transactionId, _arbitrator);
    }

    function resolveDispute(uint256 _transactionId, bool _favorBuyer)
        external
        whenNotPaused
        transactionExists(_transactionId)
        onlyArbitrator(_transactionId)
    {
        Transaction storage transaction = transactions[_transactionId];
        require(
            transaction.status == TransactionStatus.Disputed,
            "Transaction is not disputed"
        );

        if (_favorBuyer) {
            transaction.status = TransactionStatus.Refunded;
            (bool success, ) = transaction.buyer.call{value: transaction.amount}("");
            require(success, "Transfer failed");
        } else {
            transaction.status = TransactionStatus.Completed;
            (bool success, ) = transaction.seller.call{value: transaction.amount}("");
            require(success, "Transfer failed");
        }

        emit ArbitratorDecision(_transactionId, _favorBuyer);
    }

    function addArbitrator(address _arbitrator) 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        grantRole(ARBITRATOR_ROLE, _arbitrator);
    }

    function removeArbitrator(address _arbitrator) 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        revokeRole(ARBITRATOR_ROLE, _arbitrator);
    }

    function getUserTransactions(address _user)
        external
        view
        returns (uint256[] memory)
    {
        return userTransactions[_user];
    }

    function getTransactionDetails(uint256 _transactionId)
        external
        view
        returns (
            address seller,
            address buyer,
            uint256 amount,
            string memory description,
            TransactionStatus status,
            uint256 createdAt,
            address arbitrator,
            bool isArbitratorAssigned
        )
    {
        Transaction storage transaction = transactions[_transactionId];
        return (
            transaction.seller,
            transaction.buyer,
            transaction.amount,
            transaction.description,
            transaction.status,
            transaction.createdAt,
            transaction.arbitrator,
            transaction.isArbitratorAssigned
        );
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }
} 