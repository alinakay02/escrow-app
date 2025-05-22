// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title UserProfile
 * @dev Contract for managing user profiles and registration
 */
contract UserProfile is AccessControl, Pausable {
    struct Profile {
        string username;
        string email;
        uint256 reputation;
        uint256 totalTransactions;
        uint256 successfulTransactions;
        uint256 disputedTransactions;
        bool isRegistered;
        uint256 registrationDate;
    }

    mapping(address => Profile) public profiles;
    mapping(string => address) public usernameToAddress;
    
    event UserRegistered(address indexed user, string username, uint256 timestamp);
    event ProfileUpdated(address indexed user, string username, string email);
    event ReputationUpdated(address indexed user, uint256 newReputation);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    modifier onlyRegistered() {
        require(profiles[msg.sender].isRegistered, "User not registered");
        _;
    }

    function registerUser(string memory _username, string memory _email) 
        external 
        whenNotPaused 
    {
        require(!profiles[msg.sender].isRegistered, "User already registered");
        require(usernameToAddress[_username] == address(0), "Username taken");
        require(bytes(_username).length > 0, "Username cannot be empty");
        require(bytes(_email).length > 0, "Email cannot be empty");

        profiles[msg.sender] = Profile({
            username: _username,
            email: _email,
            reputation: 100,
            totalTransactions: 0,
            successfulTransactions: 0,
            disputedTransactions: 0,
            isRegistered: true,
            registrationDate: block.timestamp
        });

        usernameToAddress[_username] = msg.sender;

        emit UserRegistered(msg.sender, _username, block.timestamp);
    }

    function updateProfile(string memory _username, string memory _email) 
        external 
        whenNotPaused
        onlyRegistered 
    {
        require(bytes(_username).length > 0, "Username cannot be empty");
        require(bytes(_email).length > 0, "Email cannot be empty");
        
        address currentUsernameOwner = usernameToAddress[_username];
        require(
            currentUsernameOwner == address(0) || currentUsernameOwner == msg.sender,
            "Username taken"
        );

        // Remove old username mapping
        delete usernameToAddress[profiles[msg.sender].username];
        
        // Update profile
        profiles[msg.sender].username = _username;
        profiles[msg.sender].email = _email;
        
        // Update username mapping
        usernameToAddress[_username] = msg.sender;

        emit ProfileUpdated(msg.sender, _username, _email);
    }

    function updateTransactionStats(
        address _user,
        bool _successful,
        bool _disputed
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(profiles[_user].isRegistered, "User not registered");
        
        Profile storage profile = profiles[_user];
        profile.totalTransactions++;
        
        if (_successful) {
            profile.successfulTransactions++;
            if (profile.reputation < 200) {
                profile.reputation += 1;
                emit ReputationUpdated(_user, profile.reputation);
            }
        }
        
        if (_disputed) {
            profile.disputedTransactions++;
            if (profile.reputation > 0) {
                profile.reputation -= 1;
                emit ReputationUpdated(_user, profile.reputation);
            }
        }
    }

    function getProfile(address _user)
        external
        view
        returns (
            string memory username,
            string memory email,
            uint256 reputation,
            uint256 totalTransactions,
            uint256 successfulTransactions,
            uint256 disputedTransactions,
            bool isRegistered,
            uint256 registrationDate
        )
    {
        Profile storage profile = profiles[_user];
        return (
            profile.username,
            profile.email,
            profile.reputation,
            profile.totalTransactions,
            profile.successfulTransactions,
            profile.disputedTransactions,
            profile.isRegistered,
            profile.registrationDate
        );
    }

    function isUserRegistered(address _user) external view returns (bool) {
        return profiles[_user].isRegistered;
    }

    function getAddressByUsername(string memory _username) 
        external 
        view 
        returns (address) 
    {
        return usernameToAddress[_username];
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }
} 