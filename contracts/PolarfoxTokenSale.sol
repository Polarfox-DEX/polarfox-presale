// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

interface IERC20Token {
    function balanceOf(address owner) external returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function decimals() external returns (uint256);
}

contract PolarfoxTokenSale {
    IERC20Token public tokenContract;  // the token being sold
    uint256 public price;              // the price, in wei, per token
    address owner;

    uint256 public tokensSold;

    event Sold(address buyer, uint256 amount);

    constructor(IERC20Token _tokenContract, uint256 _price) {
        owner = msg.sender;
        tokenContract = _tokenContract;
        price = _price;
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

    function buyTokens(uint256 numberOfTokens) public payable {
        require(msg.value == safeMultiply(numberOfTokens, price), 'The amount of ETH sent does not match the desired amount of PFX');

        uint256 scaledAmount = safeMultiply(numberOfTokens, uint256(10) ** tokenContract.decimals());

        require(tokenContract.balanceOf(address(this)) >= scaledAmount, 'Not enough PFX to sell');

        emit Sold(msg.sender, numberOfTokens);
        tokensSold += numberOfTokens;

        require(tokenContract.transfer(msg.sender, scaledAmount), 'PFX transfer failed');
    }

    function collectSale(address payable recipient) public {
        require(msg.sender == owner, 'Sender is not owner');

        recipient.transfer(address(this).balance);
    }

    function endSale(address payable recipient) public {
        require(msg.sender == owner, 'Sender is not owner');

        // Send unsold PFX to the owner
        require(tokenContract.transfer(recipient, tokenContract.balanceOf(address(this))), 'Unsold PFX transfer failed');
    }
}

