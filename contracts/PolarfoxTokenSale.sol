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
    uint256 public constant maximumAmount = 1000000000000000000; // The maximum amount of ETH that can be sent (in wei) (1 ETH)
    uint256 public constant minimumAkitaBalance = 100000000; // The minimum AKITA balance required to access the presale (100M AKITA)
    address owner; // The owner of the contract
    IERC20Token public akita; // The AKITA token contract
    address payable sellRecipient; // The address that receives the payments

    // Variables
    address[] public buyers;
    uint32 public numberOfBuyers;
    mapping(address => bool) public hasBought;
    mapping(address => TransactionData) public transactions;
    bool public isSellActive;

    // Events
    event Sold(address buyer, uint256 amount);

    constructor(address payable sellRecipient_, IERC20Token akita_) {
        owner = msg.sender;
        sellRecipient = sellRecipient_;
        akita = akita_;
        numberOfBuyers = 0;
        isSellActive = false;
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
        require(msg.value <= maximumAmount, 'Cannot buy more PFX than the limit allows');
        require(akita.balanceOf(msg.sender) >= safeMultiply(minimumAkitaBalance, 10 ** akita.decimals()), 'The sender does not have enough AKITA');
        
        // This address has already bought PFX before: Make sure they do not buy more than the limit
        if(hasBought[msg.sender]) {
            uint256 newAmount = transactions[msg.sender].boughtAmount + msg.value;

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
            numberOfBuyers++;
            hasBought[msg.sender] = true;
            transactions[msg.sender] = TransactionData(msg.value, block.timestamp, recipient);
        }

        // Event
        emit Sold(msg.sender, msg.value);
    }

    function collectSale() public {
        require(msg.sender == owner, 'Sender is not owner');

        sellRecipient.transfer(address(this).balance);
    }

    function startSale() public {
        require(msg.sender == owner, 'Sender is not owner');

        // Start the sale
        isSellActive = true;
    }

    function endSale() public {
        require(msg.sender == owner, 'Sender is not owner');

        // Stop the sale
        isSellActive = false;
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
