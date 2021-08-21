// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

// To do list:
// Proper introductory comment
// Update values
// Rewrite comments in the style of PTS
// Events

import './libraries/Ownable.sol';
import './interfaces/IPFX.sol';

/**
 * Introductory comment goes here
 */
contract VestedAirdrop is Ownable {
    /// @notice Total number of levels in the airdrop
    uint8 public constant NUMBER_OF_LEVELS = 120;

    bool isActive;
    bool[NUMBER_OF_LEVELS] public isInitialized;

    uint256 public currentDistributedAmount;

    uint256[NUMBER_OF_LEVELS] public vestingStarts = [];
    uint256[NUMBER_OF_LEVELS] public vestingEnds = [];

    // 120 mappings, one per level, each one detailing how much should be given to each address
    mapping(address => uint256)[NUMBER_OF_LEVELS] amountPerAddress; // TODO: Initialize this

    // Remaining amount per address
    mapping(address => uint256)[NUMBER_OF_LEVELS] remainingAmountPerAddress; // TODO: Initialize this

    constructor() {
        // Mark the airdrop as inactive
        isActive = false;

        // The current distributed amount starts at 0
        currentDistributedAmount = 0;

        for (uint256 i = 0; i < NUMBER_OF_LEVELS; i++) {
            isInitialized[i] = false;
        }
    }

    // Public methods

    // ...

    // Private methods

    // ...

    // Owner methods

    // ...

    function startVestedAirdrop() public onlyOwner {
        // Safety checks
        require(!isActive, 'VestedAirdrop::startVestedAirdrop: airdrop already started');

        for (uint256 i = 0; i < NUMBER_OF_LEVELS; i++) {
            require(isInitialized[i], 'VestedAirdrop::startVestedAirdrop: one level or more are not initialized');
        }

        // TODO: Make sure we have enough bank to start

        // Start the airdrop
        isActive = true;
    }

    function endVestedAirdrop() public onlyOwner {}

    function setAddressesForLevel(
        address[] memory addresses,
        uint256[] memory amounts,
        uint8 level
    ) public onlyOwner {
        // Safety checks
        require(addresses.length == amounts.length, "VestedAirdrop::setAddressesForLevel: arrays' lengths do not match");
        require(!isActive, 'VestedAirdrop::setAddressesForLevel: airdrop has started');

        // Initialize values
        for (uint256 i = 0; i < addresses.length; i++) {
            amountPerAddress[level][addresses[i]] = amounts[i];
            remainingAmountPerAddress[level][addresses[i]] = amounts[i];
        }

        // Mark this level as initialized
        isInitialized[level] = true;
    }
}
