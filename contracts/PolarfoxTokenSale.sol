// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

// To do list
// #1: Remove the AKITA threshold - OK
// #2: Introduce the level system
// #3: USDT / BNB
// #4: Add proper comments, including an introductory comment
// #5: Add more events
// #6: Gas fees optimizations - some uint256s can be reduced to uint96s

import './libraries/Ownable.sol';

struct TransactionData {
    uint256 boughtAmount;
    uint256 dateBought;
    address buyingAddress;
    address receivingAddress;
    uint8 level;
}

/**
 * Introductory comment goes here 🦊
 */
contract PolarfoxTokenSale is Ownable {
    /// @notice The address that receives the money from the sale
    address payable sellRecipient;

    /// @notice The addresses that participated in the sale
    address[] public buyers;

    /// @notice True if an address has bought tokens in the sale, false otherwise
    mapping(address => bool) hasBought;

    /// @notice The list of transactions that occurred on the sale
    TransactionData[] public transactions;

    /// @notice True if the sell is active, false otherwise
    bool public isSellActive;

    /// @notice Current BNB/USDT price. Recalculated after each level is finished
    uint256 public currentBnbPrice;

    /// @notice Current sale level. This goes from 0 to 119 (and not from 1 to 120)
    uint8 public currentLevel;

    /// @notice Total number of levels in the sale
    uint8 public constant numberOfLevels = 120;

    /// @notice Current sold amount (in USD). When this reaches the batch size or the current level, the sale
    /// moves on to the next level
    uint256 public currentSoldAmountUsd;

    /// @notice Levels of the sale. When one level is done, the sale moves on to the next.
    /// Each number in this array represents the total amount of PFX that can be bought in the sale (in USD)
    // TODO: Need to multiply those numbers by the number of decimals on the USDT token
    uint256[numberOfLevels] public batchSizes = [
        100000, 100000, 100000, 100000, 100000, 100000, 100000, 100000, 100000, 100000, 100000, // Levels 0 to 10
        100000, 100000, 100000, 100000, 100000, 100000, 100000, 100000, 100000, 100000, 100000, // Levels 11 to 21
        250000, 250000, 250000, 250000, 250000, 250000, 250000, 250000, 250000, 250000, 250000, // Levels 22 to 32
        250000, 250000, 250000, 250000, 250000, 250000, 250000, 250000, 250000, 250000, 250000, // Levels 33 to 43
        250000, 250000, 250000, 250000, 250000, 250000, 250000, 250000, 500000, 500000, 500000, // Levels 44 to 54
        500000, 500000, 500000, 500000, 500000, 500000, 500000, 500000, 500000, 500000, 500000, // Levels 55 to 65
        500000, 500000, 500000, 500000, 500000, 500000, 500000, 500000, 500000, 500000, 500000, // Levels 66 to 76
        500000, 500000, 500000, 500000, 500000, 500000, 500000, 500000, 500000, 500000, 500000, // Levels 77 to 87
        500000, 500000, 500000, 500000, 535714, 570796, 1210526, 1278260, 1344827, 1410256, // Levels 88 to 97
        1559322, 2764446, 1000000, 1125000, 1225000, 1305000, 2040000, 2107500, 2175000, // Levels 98 to 106
        2250000, 2325000, 2400000, 2475000, 2550000, 2625000, 2700000, 2775000, 2850000, // Levels 107 to 115
        2925000, 3000000, 3075000, 3150000 // Levels 116 to 119
    ];

    /// @notice An event that is emitted when some tokens are bought
    event Sold(uint256 boughtAmount, uint256 dateBought, address buyingAddress, address receivingAddress, uint8 level);

    /// @notice An event that is emitted when sale funds are collected
    event SaleCollected(uint256 collectedAmount);

    /// @notice An event that is emitted when the sale is started
    event SaleStarted();

    /// @notice An event that is emitted when the sale is stopped
    event SaleStopped();

    constructor(address payable sellRecipient_) {
        sellRecipient = sellRecipient_;
        isSellActive = false;

        // First level is 0
        currentLevel = 0;
        currentSoldAmountUsd = 0;
    }

    // Public methods

    // Returns the number of buyers participating in the sale
    function numberOfBuyers() public view returns (uint256) {
        return buyers.length;
    }

    // Buys tokens in the sale - msg.sender receives the tokens
    function buyTokens() public payable {
        buyTokens(msg.sender);
    }

    // Buys tokens in the sale - recipient receives the tokens
    function buyTokens(address recipient) public payable {
        // Convert the amount from BNB to USD
        uint256 amountUsd = msg.value * currentBnbPrice;

        _buyTokens(recipient, amountUsd);
    }

    // Private methods

    // Mechanism for buying tokens in the sale
    function _buyTokens(address recipient, uint256 amountUsd) private {
        // Safety checks
        require(amountUsd > 0, 'Cannot buy 0 PFX tokens');
        require(isSellActive, 'Sale has not started or is finished');
        require(currentLevel < numberOfLevels, 'No PFX to sell after level 120');

        // Add the buyer to the list of buyers if needed
        if (!hasBought[recipient]) {
            buyers.push(recipient);
            hasBought[recipient] = true;
        }

        // The amount of USD that should be sent to this level
        uint256 amountUsdCurrentLevel;

        // The amount of USD that should be sent to the next level
        uint256 amountUsdNextLevel;

        // If there is enough room in the current level
        if (currentSoldAmountUsd + amountUsd <= batchSizes[currentLevel]) {
            amountUsdCurrentLevel = amountUsd;
            amountUsdNextLevel = 0;
        }

        // If there is not enough room in the current level
        else {
            amountUsdCurrentLevel = batchSizes[currentLevel] - currentSoldAmountUsd;
            amountUsdNextLevel = amountUsd - amountUsdCurrentLevel;
        }

        // Increase the total sold USD amount
        currentSoldAmountUsd += amountUsdCurrentLevel;

        // Append the transaction to the list of transactions
        transactions.push(TransactionData(amountUsdCurrentLevel, block.timestamp, msg.sender, recipient, currentLevel));

        emit Sold(amountUsdCurrentLevel, block.timestamp, msg.sender, recipient, currentLevel);

        // If there is not enough room in the current level
        if (amountUsdNextLevel > 0) {
            // Increase the level
            increaseLevel();

            // Buy tokens at the next level
            _buyTokens(recipient, amountUsdNextLevel);
        }
    }

    // Increases the level of the sale. Upon reaching level 120, it will stop the sale
    function increaseLevel() private {
        currentLevel++;

        // Reinitialize the sold amount
        currentSoldAmountUsd = 0;

        // Recalculate the USD price of BNB
        updateCurrentBnbPrice();

        if (currentLevel >= numberOfLevels) stopSale();
    }

    // Updates the price of BNB using the BNB/USDT pool on PancakeSwap 
    function updateCurrentBnbPrice() private {
        // TODO
        // currentBnbPrice = ...;
    }

    // Owner methods

    // Collects the sale funds. Only callable by the owner
    function collectSale() public onlyOwner {
        emit SaleCollected(address(this).balance);

        // Transfer the sale funds
        sellRecipient.transfer(address(this).balance);
    }

    // Starts the sale. Only callable by the owner
    function startSale() public onlyOwner {
        isSellActive = true;

        emit SaleStarted();
    }

    // Stops the sale. Only callable by the owner
    function stopSale() public onlyOwner {
        isSellActive = false;

        emit SaleStopped();
    }
}
