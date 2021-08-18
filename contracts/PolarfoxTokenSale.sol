// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

// To do list
// #1: Remove the AKITA threshold
// #2: Introduce the level system
// #3: USDT / BNB
// #4: Add proper comments, including an introductory comment
// #5: Add more events

import './libraries/Ownable.sol';

struct TransactionData {
    uint256 boughtAmount;
    uint256 dateBought;
    address buyingAddress;
    address receivingAddress;
}

/**
 * Introductory comment goes here 🦊
 */
contract PolarfoxTokenSale is Ownable {
    /// @notice The address that receives the money from the sale
    address payable sellRecipient;

    /// @notice The addresses that participated in the presale
    address[] public buyers;

    /// @notice True if an address has bought tokens in the presale, false otherwise
    mapping(address => bool) hasBought;

    /// @notice The list of transactions that occurred on the sale
    TransactionData[] public transactions;

    /// @notice True if the sell is active, false otherwise
    bool public isSellActive;

    /// @notice An event that is emmitted when some tokens are bought
    event Sold(uint256 boughtAmount, uint256 dateBought, address buyingAddress, address receivingAddress);

    constructor(address payable sellRecipient_) {
        sellRecipient = sellRecipient_;
        isSellActive = false;
    }

    // Returns the number of buyers participating in the presale
    function numberOfBuyers() public view returns (uint256) {
        return buyers.length;
    }

    // Buys tokens in the presale - msg.sender receives the tokens
    function buyTokens() public payable {
        buyTokens(msg.sender);
    }

    // Buys tokens in the presale - recipient receives the tokens
    function buyTokens(address recipient) public payable {
        // Safety checks
        require(isSellActive, 'Sale has not started or is finished');
        require(msg.value > 0, 'Cannot buy 0 PFX tokens');

        // Add the buyer to the list of buyers if needed
        if (!hasBought[recipient]) {
            buyers.push(recipient);
            hasBought[recipient] = true;
        }

        // Append the transaction to the list of transactions
        transactions.push(TransactionData(msg.value, block.timestamp, msg.sender, recipient));

        emit Sold(msg.value, block.timestamp, msg.sender, recipient);
    }

    // Collects the sale funds. Only callable by the owner
    function collectSale() public onlyOwner {
        sellRecipient.transfer(address(this).balance);

        // TODO: Add event
    }

    // Starts the sale. Only callable by the owner
    function startSale() public onlyOwner {
        isSellActive = true;

        // TODO: Add event
    }

    // Stops the sale. Only callable by the owner
    function endSale() public onlyOwner {
        isSellActive = false;

        // TODO: Add event
    }
}
