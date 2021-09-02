// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

// PancakePair BNB/USDT on mainnet: 0x16b9a82891338f9bA80E2D6970FddA79D1eb0daE
// PancakePair BNB/USDT on testnet: 0xF855E52ecc8b3b795Ac289f85F6Fd7A99883492b

import './libraries/Ownable.sol';
import './interfaces/IPancakePair.sol';

struct TransactionData {
    uint256 boughtAmount;
    uint256 dateBought;
    address buyingAddress;
    address receivingAddress;
    address referredAddress;
    uint8 level;
}

/**
 * The Polarfox token sale 🦊
 * 10,000,000 PFX will be offerred for sale before launch, 9,000,000 of which will be sold through
 * this contract.
 *
 * The sale works as follows:
 * The 9,000,000 PFX are distributed among 120 batches. The earlier batches have a lower price and a
 * lower size. Whenever a batch is completed, the presale moves on to the next batch.
 *
 * The sale also supports referrals - you can refer a friend to the presale, and earn a 25% bonus on
 * the amount of PFX they bought.
 */
contract PolarfoxTokenSale is Ownable {
    /// @notice The address that receives the money from the sale
    address payable public sellRecipient;

    /// @notice The addresses that participated in the sale
    address[] public buyers;

    /// @notice True if an address has bought tokens in the sale, false otherwise
    mapping(address => bool) public hasBought;

    /// @notice The list of transactions that occurred on the sale
    TransactionData[] public transactions;

    /// @notice Returns the transactions for each receiving address
    mapping(address => TransactionData[]) public transactionsForReceivingAddress;

    /// @notice Returns the transactions for each referred address
    mapping(address => TransactionData[]) public transactionsForReferralAddress;

    /// @notice True if the sell is active, false otherwise
    bool public isSellActive;

    /// @notice Current BNB/USDT price. Recalculated after each level is finished
    uint256 public currentBnbPrice;

    /// @notice Current sale level. This goes from 0 to 119 (and not from 1 to 120)
    uint8 public currentLevel;

    /// @notice Total number of levels in the sale
    uint8 public constant NUMBER_OF_LEVELS = 120;

    /// @notice Current sold amount (in USD). When this reaches the batch size or the current level, the sale
    /// moves on to the next level
    uint256 public currentSoldAmountUsd;

    /// @notice Levels of the sale. When one level is done, the sale moves on to the next.
    /// Each number in this array represents the total amount of PFX that can be bought in the sale (in USD)
    uint256[NUMBER_OF_LEVELS] public batchSizes = [
        100000000000000000000000, 100000000000000000000000, 100000000000000000000000, 100000000000000000000000, 100000000000000000000000, // Levels 00 to 04
        100000000000000000000000, 100000000000000000000000, 100000000000000000000000, 100000000000000000000000, 100000000000000000000000, // Levels 05 to 09
        100000000000000000000000, 100000000000000000000000, 100000000000000000000000, 100000000000000000000000, 100000000000000000000000, // Levels 10 to 14
        100000000000000000000000, 100000000000000000000000, 100000000000000000000000, 100000000000000000000000, 100000000000000000000000, // Levels 15 to 19
        100000000000000000000000, 100000000000000000000000, 250000000000000000000000, 250000000000000000000000, 250000000000000000000000, // Levels 20 to 24
        250000000000000000000000, 250000000000000000000000, 250000000000000000000000, 250000000000000000000000, 250000000000000000000000, // Levels 25 to 29
        250000000000000000000000, 250000000000000000000000, 250000000000000000000000, 250000000000000000000000, 250000000000000000000000, // Levels 30 to 34
        250000000000000000000000, 250000000000000000000000, 250000000000000000000000, 250000000000000000000000, 250000000000000000000000, // Levels 35 to 39
        250000000000000000000000, 250000000000000000000000, 250000000000000000000000, 250000000000000000000000, 250000000000000000000000, // Levels 40 to 44
        250000000000000000000000, 250000000000000000000000, 250000000000000000000000, 250000000000000000000000, 250000000000000000000000, // Levels 45 to 49
        250000000000000000000000, 250000000000000000000000, 500000000000000000000000, 500000000000000000000000, 500000000000000000000000, // Levels 50 to 54
        500000000000000000000000, 500000000000000000000000, 500000000000000000000000, 500000000000000000000000, 500000000000000000000000, // Levels 55 to 59
        500000000000000000000000, 500000000000000000000000, 500000000000000000000000, 500000000000000000000000, 500000000000000000000000, // Levels 60 to 64
        500000000000000000000000, 500000000000000000000000, 500000000000000000000000, 500000000000000000000000, 500000000000000000000000, // Levels 65 to 69
        500000000000000000000000, 500000000000000000000000, 500000000000000000000000, 500000000000000000000000, 500000000000000000000000, // Levels 70 to 74
        500000000000000000000000, 500000000000000000000000, 500000000000000000000000, 500000000000000000000000, 500000000000000000000000, // Levels 75 to 79
        500000000000000000000000, 500000000000000000000000, 500000000000000000000000, 500000000000000000000000, 500000000000000000000000, // Levels 80 to 84
        500000000000000000000000, 500000000000000000000000, 500000000000000000000000, 500000000000000000000000, 500000000000000000000000, // Levels 85 to 89
        500000000000000000000000, 500000000000000000000000, 535714000000000000000000, 570796000000000000000000, 1210526000000000000000000, // Levels 90 to 94
        1278260000000000000000000, 1344827000000000000000000, 1410256000000000000000000, 1559322000000000000000000, 2764446000000000000000000, // Levels 95 to 99
        1000000000000000000000000, 1125000000000000000000000, 1225000000000000000000000, 1305000000000000000000000, 2040000000000000000000000, // Levels 100 to 104
        2107500000000000000000000, 2175000000000000000000000, 2250000000000000000000000, 2325000000000000000000000, 2400000000000000000000000, // Levels 105 to 109
        2475000000000000000000000, 2550000000000000000000000, 2625000000000000000000000, 2700000000000000000000000, 2775000000000000000000000, // Levels 110 to 114
        2850000000000000000000000, 2925000000000000000000000, 3000000000000000000000000, 3075000000000000000000000, 3150000000000000000000000 // Levels 115 to 119
    ];

    // Test values:
    // uint256[NUMBER_OF_LEVELS] public batchSizes = [
    //     1000, 100, 200, 300, 400, // Levels 00 to 04
    //     1000, 100, 200, 300, 400, // Levels 05 to 09
    //     1000, 100, 200, 300, 400, // Levels 10 to 14
    //     1000, 100, 200, 300, 400, // Levels 15 to 19
    //     1000, 100, 200, 300, 400, // Levels 20 to 24
    //     1000, 100, 200, 300, 400, // Levels 25 to 29
    //     1000, 100, 200, 300, 400, // Levels 30 to 34
    //     1000, 100, 200, 300, 400, // Levels 35 to 39
    //     1000, 100, 200, 300, 400, // Levels 40 to 44
    //     1000, 100, 200, 300, 400, // Levels 45 to 49
    //     1000, 100, 200, 300, 400, // Levels 50 to 54
    //     1000, 100, 200, 300, 400, // Levels 55 to 59
    //     1000, 100, 200, 300, 400, // Levels 60 to 64
    //     1000, 100, 200, 300, 400, // Levels 65 to 69
    //     1000, 100, 200, 300, 400, // Levels 70 to 74
    //     1000, 100, 200, 300, 400, // Levels 75 to 79
    //     1000, 100, 200, 300, 400, // Levels 80 to 84
    //     1000, 100, 200, 300, 400, // Levels 85 to 89
    //     1000, 100, 200, 300, 400, // Levels 90 to 94
    //     1000, 100, 200, 300, 400, // Levels 95 to 99
    //     1000, 100, 200, 300, 400, // Levels 100 to 104
    //     1000, 100, 200, 300, 400, // Levels 105 to 109
    //     1000, 100, 200, 300, 400, // Levels 110 to 114
    //     1000, 100, 200, 300, 400 // Levels 115 to 119
    // ];

    /// @notice Address of the PancakeSwap BNB/USDT pair. Used to calculate the current BNB price
    IPancakePair public pancakeBnbUsdtPair;

    /// @notice An event that is emitted when some tokens are bought
    event Sold(uint256 boughtAmount, uint256 dateBought, address buyingAddress, address receivingAddress, address referrerAddress, uint8 level);

    /// @notice An event that is emitted when sale funds are collected
    event SaleCollected(uint256 collectedAmount);

    /// @notice An event that is emitted when the sale is started
    event SaleStarted();

    /// @notice An event that is emitted when the sale is stopped
    event SaleStopped();
    
    /// @notice An event that is emitted when the level is changed
    event LevelChanged(uint8 oldLevel, uint8 newLevel);
    
    constructor(address payable sellRecipient_, address _pancakeBnbUsdtPair) {
        sellRecipient = sellRecipient_;
        pancakeBnbUsdtPair = IPancakePair(_pancakeBnbUsdtPair);
        isSellActive = false;

        // First level is 0
        currentLevel = 0;
        currentSoldAmountUsd = 0;

        // Set the BNB/USDT price up
        updateCurrentBnbPrice();
    }

    // Public methods

    // Returns the number of buyers participating in the sale
    function numberOfBuyers() public view returns (uint256) {
        return buyers.length;
    }

        // Returns the number of transactions in the sale
    function numberOfTransactions() public view returns (uint256) {
        return transactions.length;
    }

    // Returns the number of transactions a given address has made
    function numberOfTransactionsForReceivingAddress(address _address) public view returns (uint256) {
        return transactionsForReceivingAddress[_address].length;
    }

    // Buys tokens in the sale - msg.sender receives the tokens
    function buyTokens() public payable {
        buyTokens(msg.sender);
    }

    // Buys tokens in the sale - recipient receives the tokens
    function buyTokens(address recipient) public payable {
        buyTokens(recipient, address(0));
    }

    // Buys tokens in the sale - recipient receives the tokens
    function buyTokens(address recipient, address referrer) public payable {
        // Convert the amount from BNB to USD
        uint256 amountUsd = msg.value * currentBnbPrice;

        _buyTokens(recipient, referrer, amountUsd);
    }

    // Private methods

    // Mechanism for buying tokens in the sale
    function _buyTokens(address recipient, address referrer, uint256 amountUsd) private {
        // Safety checks
        require(amountUsd > 0, 'PolarfoxTokenSale::_buyTokens: Cannot buy 0 PFX tokens');
        require(isSellActive, 'PolarfoxTokenSale::_buyTokens: Sale has not started or is finished');
        require(currentLevel < NUMBER_OF_LEVELS, 'PolarfoxTokenSale::_buyTokens: No PFX to sell after level 120');
        require(recipient != referrer, 'PolarfoxTokenSale::_buyTokens: Recipient cannot be referrer');
        require(tx.origin == msg.sender, 'PolarfoxTokenSale::_buyTokens: Caller cannot be a contract');

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

        // Create the transaction
        TransactionData memory transaction = TransactionData(amountUsdCurrentLevel, block.timestamp, msg.sender, recipient, referrer, currentLevel);

        // Append the transaction to the lists of transactions
        transactions.push(transaction);
        transactionsForReceivingAddress[recipient].push(transaction);
        transactionsForReferralAddress[referrer].push(transaction);

        emit Sold(amountUsdCurrentLevel, block.timestamp, msg.sender, recipient, referrer, currentLevel);

        // If there is not enough room in the current level
        if (amountUsdNextLevel > 0) {
            // Increase the level
            increaseLevel();

            // Buy tokens at the next level
            _buyTokens(recipient, referrer, amountUsdNextLevel);
        }
    }

    // Increases the level of the sale. Upon reaching level 120, it will stop the sale
    function increaseLevel() private {
        currentLevel++;

        // Reinitialize the sold amount
        currentSoldAmountUsd = 0;

        // Recalculate the USD price of BNB
        updateCurrentBnbPrice();

        if (currentLevel >= NUMBER_OF_LEVELS) stopSale();

        // Emit an event
        emit LevelChanged(currentLevel - 1, currentLevel);
    }

    // Updates the price of BNB using the BNB/USDT pool on PancakeSwap 
    function updateCurrentBnbPrice() private {
        // Get the reserves of BNB and USDT
        (uint112 reserveUsd, uint112 reserveBnb, ) = pancakeBnbUsdtPair.getReserves();

        // Calculate and set the BNB price
        currentBnbPrice = reserveUsd / reserveBnb;
    }

    // Owner methods

    // Collects the sale funds. Only callable by the owner
    function collectSale() public onlyOwner {
        require(address(this).balance > 0, 'PolarfoxTokenSale::collectSale: Nothing to collect');

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
