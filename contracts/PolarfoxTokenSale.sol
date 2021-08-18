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

contract PolarfoxTokenSale is Ownable {
    // Constants
    address owner; // The owner of the contract
    address payable sellRecipient; // The address that receives the payments

    // Variables
    address[] public buyers;
    mapping(address => bool) hasBought;
    TransactionData[] public transactions;
    bool public isSellActive;

    // Events
    event Sold(address buyer, uint256 amount);

    constructor(address payable sellRecipient_) {
        owner = msg.sender;
        sellRecipient = sellRecipient_;
        isSellActive = false;
    }

    function numberOfBuyers() public view returns (uint256) {
        return buyers.length;
    }

    function buyTokens() public payable {
        buyTokens(msg.sender);
    }

    // Parameters:
    // Recipient: the AVAX address to which the PFX tokens should be sent to
    function buyTokens(address recipient) public payable {
        // Safety checks
        require(isSellActive, 'Sale has not started or is finished');
        require(msg.value > 0, 'Cannot buy 0 PFX tokens');

        // Store the transaction
        if (!hasBought[recipient]) {
            buyers.push(recipient);
            hasBought[recipient] = true;
        }

        transactions.push(TransactionData(msg.value, block.timestamp, msg.sender, recipient));

        // Event
        emit Sold(msg.sender, msg.value);
    }

    function collectSale() public onlyOwner {
        // Collect the sale funds
        sellRecipient.transfer(address(this).balance);
    }

    function startSale() public onlyOwner {
        // Start the sale
        isSellActive = true;
    }

    function endSale() public onlyOwner {
        // Stop the sale
        isSellActive = false;
    }
}
