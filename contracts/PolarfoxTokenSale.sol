// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

interface IERC20Token {
    function balanceOf(address owner) external returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function decimals() external returns (uint256);
}

struct TransactionData { 
   uint256 boughtAmount;
   uint256 dateBought;
   address receivingAddress;
}

contract PolarfoxTokenSale {
    // Constants
    uint256 public constant price = 1; // The price, in wei, per PFX // TODO
    uint256 public constant maximumAmount = 1; // The maximum amount of PFX that can be bought // TODO
    address owner; // The owner of the contract
    address payable sellRecipient; // The address that receives the payments

    // Variables
    uint256 public tokensSold;
    uint256 public tokensToSell = 9250000; // Total amount of tokens to sell // TODO
    address[] public buyers;
    mapping(address => bool) public hasBought;
    mapping(address => TransactionData) public transactions;

    // Events
    event Sold(address buyer, uint256 amount);

    constructor(address payable sellRecipient_) {
        owner = msg.sender;
        sellRecipient = sellRecipient_;
    }

    // Parameters:
    // Number of tokens: number of PFX to buy 
    function buyTokens(uint256 numberOfTokens) public payable {
        buyTokens(numberOfTokens, msg.sender);
    }

    // Parameters:
    // Number of tokens: number of PFX to buy
    // Recipient: the AVAX address to which the PFX tokens should be sent to
    function buyTokens(uint256 numberOfTokens, address recipient) public payable {
        // Safety checks 
        require(numberOfTokens > 0, 'Cannot buy 0 PFX tokens');
        require(msg.value == safeMultiply(numberOfTokens, price), 'The amount of ETH sent does not match the desired amount of PFX');
        require(numberOfTokens <= tokensToSell - tokensSold, 'Not enough PFX to sell');
        require(numberOfTokens <= maximumAmount, 'Cannot buy more PFX than the limit allows');
        
        // This address has already bought PFX before: Make sure they do not buy more than the limit
        if(hasBought[msg.sender]) {
            uint256 newAmount = transactions[msg.sender].boughtAmount + numberOfTokens;

            require(
                newAmount <= maximumAmount,
                'The total amount of PFX bought in the past and in the current transaction are higher than the limit'
            );

            transactions[msg.sender] = TransactionData(newAmount, block.timestamp, recipient);
        }

        // This address is participating in the sale for the first time
        else {
            // Store the transaction
            buyers.push(msg.sender);
            hasBought[msg.sender] = true;
            transactions[msg.sender] = TransactionData(numberOfTokens, block.timestamp, recipient);
        }

        // Update public data
        tokensSold += numberOfTokens;

        // Event
        emit Sold(msg.sender, numberOfTokens);
    }

    function collectSale() public {
        require(msg.sender == owner, 'Sender is not owner');

        sellRecipient.transfer(address(this).balance);
    }

    function endSale() public {
        require(msg.sender == owner, 'Sender is not owner');

        // Stop the sale
        tokensToSell = 0;
    }

    // Guards against integer overflows
    function safeMultiply(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        } else {
            uint256 c = a * b;
            assert(c / a == b);
            return c;
        }
    }
}

