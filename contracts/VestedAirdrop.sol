// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import './libraries/Ownable.sol';
import './interfaces/IPFX.sol';

/**
 * The Vested Airdrop contract 🦊
 * This contract's job is to distribute PFX over time to participants in the PFX presale.
 *
 * Every level of the presale will see different rules applied to the distribution of their investment.
 * Each one will have a custom:
 * - percentage of tokens locked
 * - start of vesting
 * - end of vesting
 *
 * This is done, among other things, to lower sell pressure on the PFX token at launch, while remaining
 * fair to investors.
 */
contract VestedAirdrop is Ownable {
    /// @notice Total number of levels in the airdrop
    uint8 public constant NUMBER_OF_LEVELS = 120;

    /// @notice Address of the PFX token
    address public pfx;

    /// @notice Whether or not the sale is active
    bool public isActive;

    /// @notice Whether or not the sale is paused. This is here for safety purposes
    bool public isPaused;

    /// @notice Whether or not a level has been initialized.
    /// This is only used when setting up the contract
    bool[NUMBER_OF_LEVELS] public isInitialized;

    /// @notice The current amount of PFX that was distributed by this contract
    uint256 public currentDistributedAmount;

    /// @notice The dates at which vesting starts for each level
    // uint256[NUMBER_OF_LEVELS] public vestingStarts = [];

    /// @notice The dates at which vesting ends for each level
    // uint256[NUMBER_OF_LEVELS] public vestingEnds = [];

    // Test values:
    uint256[NUMBER_OF_LEVELS] public vestingStarts = [
        1629728000, 1629730000, 1629732000, 1629734000, 1629736000, // Levels 00 to 04
        1629728000, 1629730000, 1629732000, 1629734000, 1629736000, // Levels 05 to 09
        1629728000, 1629730000, 1629732000, 1629734000, 1629736000, // Levels 10 to 14
        1629728000, 1629730000, 1629732000, 1629734000, 1629736000, // Levels 15 to 19
        1629728000, 1629730000, 1629732000, 1629734000, 1629736000, // Levels 20 to 24
        1629728000, 1629730000, 1629732000, 1629734000, 1629736000, // Levels 25 to 29
        1629728000, 1629730000, 1629732000, 1629734000, 1629736000, // Levels 30 to 34
        1629728000, 1629730000, 1629732000, 1629734000, 1629736000, // Levels 35 to 39
        1629728000, 1629730000, 1629732000, 1629734000, 1629736000, // Levels 40 to 44
        1629728000, 1629730000, 1629732000, 1629734000, 1629736000, // Levels 45 to 49
        1629728000, 1629730000, 1629732000, 1629734000, 1629736000, // Levels 50 to 54
        1629728000, 1629730000, 1629732000, 1629734000, 1629736000, // Levels 55 to 59
        1629728000, 1629730000, 1629732000, 1629734000, 1629736000, // Levels 60 to 64
        1629728000, 1629730000, 1629732000, 1629734000, 1629736000, // Levels 65 to 69
        1629728000, 1629730000, 1629732000, 1629734000, 1629736000, // Levels 70 to 74
        1629728000, 1629730000, 1629732000, 1629734000, 1629736000, // Levels 75 to 79
        1629728000, 1629730000, 1629732000, 1629734000, 1629736000, // Levels 80 to 84
        1629728000, 1629730000, 1629732000, 1629734000, 1629736000, // Levels 85 to 89
        1629728000, 1629730000, 1629732000, 1629734000, 1629736000, // Levels 90 to 94
        1629728000, 1629730000, 1629732000, 1629734000, 1629736000, // Levels 95 to 99
        1629728000, 1629730000, 1629732000, 1629734000, 1629736000, // Levels 100 to 104
        1629728000, 1629730000, 1629732000, 1629734000, 1629736000, // Levels 105 to 109
        1629728000, 1629730000, 1629732000, 1629734000, 1629736000, // Levels 110 to 114
        1629728000, 1629730000, 1629732000, 1629734000, 1629736000 // Levels 115 to 119
    ];

    uint256[NUMBER_OF_LEVELS] public vestingEnds = [
        1629730000, 1629732000, 1629734000, 1629736000, 1629738000, // Levels 00 to 04
        1629730000, 1629732000, 1629734000, 1629736000, 1629738000, // Levels 05 to 09
        1629730000, 1629732000, 1629734000, 1629736000, 1629738000, // Levels 10 to 14
        1629730000, 1629732000, 1629734000, 1629736000, 1629738000, // Levels 15 to 19
        1629730000, 1629732000, 1629734000, 1629736000, 1629738000, // Levels 20 to 24
        1629730000, 1629732000, 1629734000, 1629736000, 1629738000, // Levels 25 to 29
        1629730000, 1629732000, 1629734000, 1629736000, 1629738000, // Levels 30 to 34
        1629730000, 1629732000, 1629734000, 1629736000, 1629738000, // Levels 35 to 39
        1629730000, 1629732000, 1629734000, 1629736000, 1629738000, // Levels 40 to 44
        1629730000, 1629732000, 1629734000, 1629736000, 1629738000, // Levels 45 to 49
        1629730000, 1629732000, 1629734000, 1629736000, 1629738000, // Levels 50 to 54
        1629730000, 1629732000, 1629734000, 1629736000, 1629738000, // Levels 55 to 59
        1629730000, 1629732000, 1629734000, 1629736000, 1629738000, // Levels 60 to 64
        1629730000, 1629732000, 1629734000, 1629736000, 1629738000, // Levels 65 to 69
        1629730000, 1629732000, 1629734000, 1629736000, 1629738000, // Levels 70 to 74
        1629730000, 1629732000, 1629734000, 1629736000, 1629738000, // Levels 75 to 79
        1629730000, 1629732000, 1629734000, 1629736000, 1629738000, // Levels 80 to 84
        1629730000, 1629732000, 1629734000, 1629736000, 1629738000, // Levels 85 to 89
        1629730000, 1629732000, 1629734000, 1629736000, 1629738000, // Levels 90 to 94
        1629730000, 1629732000, 1629734000, 1629736000, 1629738000, // Levels 95 to 99
        1629730000, 1629732000, 1629734000, 1629736000, 1629738000, // Levels 100 to 104
        1629730000, 1629732000, 1629734000, 1629736000, 1629738000, // Levels 105 to 109
        1629730000, 1629732000, 1629734000, 1629736000, 1629738000, // Levels 110 to 114
        1629730000, 1629732000, 1629734000, 1629736000, 1629738000 // Levels 115 to 119
    ];

    /// @notice The total amount of PFX to be distributed among all levels.
    /// This is only used when setting up the contract
    uint256 public totalAllLevels;

    /// @notice The total amount of PFX to be distributed among one level.
    /// This is only used when setting up the contract
    uint256[NUMBER_OF_LEVELS] public totalAmounts;

    /// @notice A collection of 120 mappings, one per level, each one detailing how much PFX
    /// should be given to each address
    mapping(address => uint256)[NUMBER_OF_LEVELS] public amountPerAddress;

    /// @notice Same as the mapping above, but instead highlights how much PFX each address
    /// already claimed
    mapping(address => uint256)[NUMBER_OF_LEVELS] public claimedAmountPerAddress;

    /// @notice An event that is emitted when some PFX is claimed
    event ClaimedPfx(uint256 amount, address recipient, uint8 level);

    /// @notice An event that is emitted when the vested airdrop starts
    event StartedVestedAirdrop();

    /// @notice An event that is emitted when the vested airdrop ends
    event EndedVestedAirdrop();

    /// @notice An event that is emitted when the vested airdrop is paused
    event PausedVestedAirdrop();

    /// @notice An event that is emitted when the vested airdrop is unpaused
    event ResumedVestedAirdrop();

    /// @notice An event that is emitted when addresses are set for a level
    event SetAddressesForLevel(address[] addresses, uint256[] amounts, uint8 level);

    constructor(address _pfx) {
        // Set the PFX address
        pfx = _pfx;

        // Mark the airdrop as inactive
        isActive = false;
        isPaused = false;
        totalAllLevels = 0;

        // The current distributed amount starts at 0
        currentDistributedAmount = 0;

        for (uint256 i = 0; i < NUMBER_OF_LEVELS; i++) {
            isInitialized[i] = false;
        }
    }

    // Public methods

    // Allows a user to claim their earnings at a given level
    // Dynamically calculates how much PFX an address is entitled to, and sends that amount
    function claim(uint8 level) public {
        // Safety checks
        require(isActive, 'VestedAirdrop::claim: Vesting is not active');
        require(!isPaused, 'VestedAirdrop::claim: Vesting is paused');
        require(block.timestamp >= vestingStarts[level], 'VestedAirdrop::claim: Vesting has not started for this level');
        require(
            amountPerAddress[level][msg.sender] - claimedAmountPerAddress[level][msg.sender] > 0,
            'VestedAirdrop::claim: There is no PFX to claim for this address'
        );

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
            require(amount > 0, 'VestedAirdrop::claim: No PFX to send right now');

            // Store the amount that was retrieved in the database
            claimedAmountPerAddress[level][msg.sender] += amount;
        }

        // Send the PFX
        IPFX(pfx).transfer(msg.sender, amount);

        // Store this information
        currentDistributedAmount += amount;

        emit ClaimedPfx(amount, msg.sender, level);
    }

    // Owner methods

    // Starts the vested airdrop. Performs various safety checks
    function startVestedAirdrop() public onlyOwner {
        // Safety checks
        require(!isActive, 'VestedAirdrop::startVestedAirdrop: Airdrop already started');

        for (uint256 i = 0; i < NUMBER_OF_LEVELS; i++) {
            require(isInitialized[i], 'VestedAirdrop::startVestedAirdrop: One level or more are not initialized');
        }

        // Make sure we have enough PFX to start
        require(IPFX(pfx).balanceOf(address(this)) >= totalAllLevels, 'VestedAirdrop::startVestedAirdrop: PFX balance is too low to start');

        // Start the airdrop
        isActive = true;

        emit StartedVestedAirdrop();
    }

    // Ends the vested airdrop, and burns what has not been distributed
    function endVestedAirdrop() public onlyOwner {
        // Safety checks
        require(isActive, 'VestedAirdrop::endVestedAirdrop: The presale has not started yet');

        // Burn the remaining PFX
        require(IPFX(pfx).transfer(address(0), IPFX(pfx).balanceOf(address(this))), 'VestedAirdrop::endVestedAirdrop: Burn failed');

        // End the presale
        isActive = false;

        emit EndedVestedAirdrop();
    }

    // Pauses the vested airdrop. In theory, this should not have to be used
    function pauseVestedAirdrop() public onlyOwner {
        isPaused = true;

        emit PausedVestedAirdrop();
    }

    // Unpauses the vested airdrop
    function resumeVestedAirdrop() public onlyOwner {
        isPaused = false;

        emit ResumedVestedAirdrop();
    }

    // Main setup function. This allows the owner to tell the contract the amounts of PFX each address
    // is entitled to, for each level
    function setAddressesForLevel(
        address[] memory addresses,
        uint256[] memory amounts,
        uint8 level
    ) public onlyOwner {
        // Safety checks
        require(addresses.length == amounts.length, "VestedAirdrop::setAddressesForLevel: Arrays' lengths do not match");
        require(!isActive, 'VestedAirdrop::setAddressesForLevel: Airdrop has started');

        uint256 total = 0;

        // Initialize values
        for (uint256 i = 0; i < addresses.length; i++) {
            amountPerAddress[level][addresses[i]] = amounts[i];
            total += amounts[i];
        }

        // Mark this level as initialized
        isInitialized[level] = true;

        // Store the total
        totalAllLevels += total - totalAmounts[level]; // Remove the old total amount that was calculated for this level
        totalAmounts[level] = total;

        emit SetAddressesForLevel(addresses, amounts, level);
    }
}
