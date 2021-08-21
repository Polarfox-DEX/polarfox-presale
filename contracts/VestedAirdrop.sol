// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

// To do list:
// Proper introductory comment
// Update values
// Rewrite comments in the style of PTS
// Events

// TODO: This contract should be excluded from the PFX fees (same for InitialAirdrop).

import './libraries/Ownable.sol';
import './interfaces/IPFX.sol';

/**
 * Introductory comment goes here
 */
contract VestedAirdrop is Ownable {
    /// @notice Total number of levels in the airdrop
    uint8 public constant NUMBER_OF_LEVELS = 120;

    address public pfx;

    bool isActive;
    bool[NUMBER_OF_LEVELS] public isInitialized;

    uint256 public currentDistributedAmount;

    uint256[NUMBER_OF_LEVELS] public vestingStarts = [];
    uint256[NUMBER_OF_LEVELS] public vestingEnds = [];

    // 120 mappings, one per level, each one detailing how much should be given to each address
    mapping(address => uint256)[NUMBER_OF_LEVELS] amountPerAddress; // TODO: Initialize this

    // Remaining amount per address
    mapping(address => uint256)[NUMBER_OF_LEVELS] claimedAmountPerAddress; // TODO: Initialize this

    constructor(address _pfx) {
        // Set the PFX address
        pfx = _pfx;

        // Mark the airdrop as inactive
        isActive = false;

        // The current distributed amount starts at 0
        currentDistributedAmount = 0;

        for (uint256 i = 0; i < NUMBER_OF_LEVELS; i++) {
            isInitialized[i] = false;
        }
    }

    // Public methods

    function claim(uint8 level) public {
        // Safety checks
        require(block.timestamp >= vestingStarts[level], 'VestedAirdrop::claim: vesting has not started for this level');

        // Calculate the amount of PFX to send
        uint256 amount;
        if (block.timestamp >= vestingEnds[level]) {
            // The vesting has ended: send all the remaining PFX for that address
            amount = amountPerAddress[level][msg.sender] - claimedAmountPerAddress[level][msg.sender];

            // Set the claimed amount to the maximum
            claimedAmountPerAddress[level][msg.sender] = amountPerAddress[level][msg.sender];
        } else {
            // The vesting is ongoing: calculate how much PFX that address is entitled to
            uint256 entitledAmount = (amountPerAddress[level][msg.sender] * (block.timestamp - vestingStarts[level])) /
                (vestingEnds[level] - vestingStarts[level]);

            // Remove the amount that was already sent for this address
            amount = entitledAmount - claimedAmountPerAddress[level][msg.sender];

            // Do not send 0 PFX
            require(amount > 0, 'VestedAirdrop::claim: no PFX to send right now');

            // Store the amount that was retrieved in the database
            claimedAmountPerAddress[level][msg.sender] += amount;
        }

        // Send the PFX
        IPFX(pfx).transfer(msg.sender, amount);
    }

    // Private methods

    // ...

    // Owner methods

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
        }

        // Mark this level as initialized
        isInitialized[level] = true;
    }
}
