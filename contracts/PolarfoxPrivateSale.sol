// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

// To do list
// #3: Whitelist system
// #4: Presale end function

import './libraries/Ownable.sol';
import './interfaces/IPancakePair.sol';

struct TransactionData {
    uint256 boughtAmount;
    uint256 dateBought;
    address buyingAddress;
    address receivingAddress;
}

/**
 * The Polarfox private token sale 🦊
 * 10,000,000 PFX will be offerred for sale before launch, 1,000,000 of which will be sold through
 * this contract.
 *
 * The price in this presale is set as $1 per PFX, which is low when compared to the rest of the sale.
 * The tokens sold through this contract will not be delivered immediately, but rather locked then
 * vested through several years.
 *
 * The code of this contract is a diluted version of PolarfoxTokenSale.
 */
contract PolarfoxPrivateSale is Ownable {
    /// @notice The address that receives the money from the sale
    address payable public saleRecipient;

    /// @notice The addresses that participated in the sale
    address[] public buyers;

    /// @notice True if an address has bought tokens in the sale, false otherwise
    mapping(address => bool) public hasBought;

    /// @notice The list of transactions that occurred on the sale
    TransactionData[] public transactions;

    /// @notice Returns the transactions for each receiving address
    mapping(address => TransactionData[]) public transactionsForReceivingAddress;

    /// @notice True if the sale is active, false otherwise
    bool public isSaleActive;

    /// @notice BNB/USDT price
    uint256 public currentBnbPrice;

    /// @notice Sold amount so far
    uint256 public soldAmount;

    /// @notice Total amount of tokens to sell
    uint256 public amountToSell = 1_000_000e18; // 1,000,000 PFX / USD

    /// @notice True if an address is whitelisted and can participate in the private sale
    mapping(address => bool) public isWhitelisted;

    /// @notice An event that is emitted when some tokens are bought
    event Sold(uint256 boughtAmount, uint256 dateBought, address buyingAddress, address receivingAddress);

    /// @notice An event that is emitted when sale funds are collected
    event SaleCollected(uint256 collectedAmount);

    /// @notice An event that is emitted when the sale is started
    event SaleStarted();

    /// @notice An event that is emitted when the sale is stopped
    event SaleStopped();
    
    /// @notice An event that is emitted when an address is whitelisted
    event WhitelistedAddress(address _address);
    
    /// @notice An event that is emitted when an address is blacklisted
    event BlacklistedAddress(address _address);

    /// @notice An event that is emitted when the sale recipient is changed
    event ChangedSaleRecipient(address _address);

    constructor(address payable saleRecipient_, uint256 currentBnbPrice_) {
        // Initialize values
        saleRecipient = saleRecipient_;
        isSaleActive = false;
        soldAmount = 0;
        currentBnbPrice = currentBnbPrice_;
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
        // Convert the amount from BNB to USD
        uint256 amountUsd = msg.value * currentBnbPrice;

        _buyTokens(recipient, amountUsd);
    }
    
    // Collects the sale funds
    function collectSale() public {
        require(address(this).balance > 0, 'PolarfoxPrivateSale::collectSale: Nothing to collect');

        emit SaleCollected(address(this).balance);

        // Transfer the sale funds
        saleRecipient.transfer(address(this).balance);
    }

    // Private methods

    // Mechanism for buying tokens in the sale
    function _buyTokens(address recipient, uint256 amountUsd) private {
        // Safety checks
        require(amountUsd > 0, 'PolarfoxPrivateSale::_buyTokens: Cannot buy 0 PFX tokens');
        require(isSaleActive, 'PolarfoxPrivateSale::_buyTokens: Sale has not started or is finished');
        require(amountUsd + soldAmount <= amountToSell, 'PolarfoxPrivateSale::_buyTokens: Only 1,000,000 PFX tokens to sell');
        require(isWhitelisted[msg.sender], 'PolarfoxPrivateSale::_buyTokens: Buying address is not whitelisted');

        // Add the buyer to the list of buyers if needed
        if (!hasBought[recipient]) {
            buyers.push(recipient);
            hasBought[recipient] = true;
        }

        soldAmount += amountUsd;

        // Create the transaction
        TransactionData memory transaction = TransactionData(amountUsd, block.timestamp, msg.sender, recipient);

        // Append the transaction to the lists of transactions
        transactions.push(transaction);
        transactionsForReceivingAddress[recipient].push(transaction);

        emit Sold(amountUsd, block.timestamp, msg.sender, recipient);
    }

    // Owner methods

    // Updates the price of BNB manually. Only callable by the owner
    function updateCurrentBnbPrice(uint256 currentBnbPrice_) public onlyOwner {
        currentBnbPrice = currentBnbPrice_;
    }

    // Starts the sale. Only callable by the owner
    function startSale() public onlyOwner {
        isSaleActive = true;

        emit SaleStarted();
    }

    // Stops the sale. Only callable by the owner
    function stopSale() public onlyOwner {
        isSaleActive = false;

        emit SaleStopped();
    }

    // Whitelists an address. Only callable by the owner
    function whitelistAddress(address _address) public onlyOwner {
        isWhitelisted[_address] = true;

        emit WhitelistedAddress(_address);
        
    }

    // Blacklists an address. Only callable by the owner
    function blacklistAddress(address _address) public onlyOwner {
        isWhitelisted[_address] = false;

        emit BlacklistedAddress(_address);
    }

    // Sets a new sale recipient. Only callable by the owner
    function setSaleRecipient(address payable _address) public onlyOwner {
        saleRecipient = _address;

        emit ChangedSaleRecipient(_address);
    }
}
