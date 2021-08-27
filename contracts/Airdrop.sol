// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

// Contract for administering the Airdrop of PFX to the people who participated in the PFX pre-sale on Ethereum!
contract Airdrop {
    // Constants
    uint constant public TOTAL_AIRDROP_SUPPLY = 9_250_000e18;
    address public pfx; // PFX address

    // Variables
    address public owner; // Owner of the contract
    bool public claimingAllowed; // True if claiming is allowed

    // PFX amounts
    mapping (address => uint96) public withdrawAmount; // Amount of PFX to transfer
    uint public totalAllocated; // Total number of PFX tokens in the withdrawAmount mapping

    // Events
    event ClaimingAllowed();
    event ClaimingOver();
    event PfxClaimed(address claimer, uint amount);

    /**
     * Initializes the contract. Sets the pfx token address and the owner.
     * Claiming period is not enabled.
     *
     * @param pfx_ the PFX token contract address
     * @param owner_ the privileged contract owner
     */
    constructor(address pfx_, address owner_) {
        pfx = pfx_;
        owner = owner_;
        claimingAllowed = false;
        totalAllocated = 0;
    }

    /**
     * Changes the contract owner. Can only be set by the contract owner.
     *
     * @param owner_ new contract owner address
     */
    function setOwner(address owner_) external {
        require(msg.sender == owner, 'Airdrop::setOwner: Sender is not owner');
        owner = owner_;
    }

    /**
     * Enable the claiming period and allow user to claim PFX. Before activation,
     * this contract must have a PFX balance equal to the total airdrop PFX
     * supply of 9.25 million PFX. All claimable PFX tokens must be whitelisted
     * before claiming is enabled. Only callable by the owner.
     */
    function allowClaiming() external {
        require(IPFX(pfx).balanceOf(address(this)) >= TOTAL_AIRDROP_SUPPLY, 'Airdrop::allowClaiming: Insufficient PFX supply');
        require(msg.sender == owner, 'Airdrop::allowClaiming: Sender is not owner');
        claimingAllowed = true;
        emit ClaimingAllowed();
    }

    /**
     * End the claiming period. All unclaimed PFX will be burnt.
     * Can only be called by the owner.
     */
    function endClaiming() external {
        require(msg.sender == owner, 'Airdrop::endClaiming: Sender is not owner');
        require(claimingAllowed, "Airdrop::endClaiming: Claiming not started");

        claimingAllowed = false;
        emit ClaimingOver();

        // Burn the remainder
        uint amount = IPFX(pfx).balanceOf(address(this));
        require(IPFX(pfx).transfer(address(0), amount), 'Airdrop::endClaiming: Burn failed');
    }

    /**
     * Withdraw your PFX. In order to qualify for a withdrawal, the caller's address
     * must be whitelisted. All PFX must be claimed at once. Only the full amount can be
     * claimed and only one claim is allowed per user.
     */
    function claim() external {
        require(claimingAllowed, 'Airdrop::claim: Claiming is not allowed');
        require(withdrawAmount[msg.sender] > 0, 'Airdrop::claim: No PFX to claim');

        uint amountToClaim = withdrawAmount[msg.sender];
        withdrawAmount[msg.sender] = 0;

        emit PfxClaimed(msg.sender, amountToClaim);

        require(IPFX(pfx).transfer(msg.sender, amountToClaim), 'Airdrop::claim: Transfer failed');
    }

    /**
     * Whitelist an address to claim PFX. Specify the amount of PFX to be allocated.
     * That address will then be able to claim that amount of PFX during the claiming
     * period. The transferrable amount of PFX must be nonzero. The total amount allocated 
     * must be less than or equal to the total airdrop supply. Whitelisting must occur 
     * before the claiming period is enabled. Whitelisting an address twice will replace
     * the old allocation with the new one.
     * Only called by the owner.
     *
     * @param addr address that may claim PFX
     * @param pfxOut the amount of PFX that addr may withdraw
     */
    function whitelistAddress(address addr, uint96 pfxOut) public {
        require(msg.sender == owner, 'Airdrop::whitelistAddress: Sender is not owner');
        require(!claimingAllowed, 'Airdrop::whitelistAddress: Claiming in session');
        require(pfxOut > 0, 'Airdrop::whitelistAddress: Allocated amount cannot be zero');

        if (withdrawAmount[addr] > 0) {
            totalAllocated -= withdrawAmount[addr];
        }

        withdrawAmount[addr] = pfxOut;

        totalAllocated += pfxOut;
        require(totalAllocated <= TOTAL_AIRDROP_SUPPLY, 'Airdrop::whitelistAddress: Exceeds PFX allocation');
    }

    /**
     * Whitelist multiple addresses in one call. Wrapper around whitelistAddress.
     * All parameters are arrays. Each array must be the same length. Each index
     * corresponds to one (address, pfx) tuple. Only callable by the owner.
     */
    function whitelistAddresses(address[] memory addrs, uint96[] memory pfxOuts) external {
        require(msg.sender == owner, 'Airdrop::whitelistAddresses: Sender is not owner');
        require(addrs.length == pfxOuts.length, 'Airdrop::whitelistAddresses: incorrect array length');

        for (uint i = 0; i < addrs.length; i++) {
            whitelistAddress(addrs[i], pfxOuts[i]);
        }
    }
}

interface IPFX {
    function balanceOf(address account) external view returns (uint);
    function transfer(address dst, uint rawAmount) external returns (bool);
}
