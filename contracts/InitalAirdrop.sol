// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import './libraries/Ownable.sol';
import './interfaces/IPFX.sol';

/**
 * The Initial Airdrop contract 🦊
 * This contract will distribute a part of the PFX bought in the presale, immediately after it is done.
 *
 * Not all tokens will be distributed using this contract - this is done to reduce immediate sell pressure.
 */
contract InitialAirdrop is Ownable {
    /// @notice The total amount of PFX to distribute
    uint256 public constant TOTAL_AIRDROP_SUPPLY = 1_000e18; // TODO: Exact amount TBD

    /// @notice The PFX token address
    address public pfx;

    /// @notice True if claiming is allowed, false otherwise
    bool public claimingAllowed;

    /// @notice The amount of PFX that is claimable, per address
    mapping(address => uint96) public withdrawAmount;

    /// @notice The total amount of PFX tokens om the withdrawAmount mapping
    uint256 public totalAllocated;

    /// @notice An event that is emitted when claiming starts
    event ClaimingAllowed();

    /// @notice An event that is emitted when claiming ends
    event ClaimingOver();

    /// @notice An event that is emitted when some PFX is claimed by an address
    event PfxClaimed(address claimer, uint256 amount);

    /**
     * Initializes the contract. Sets the pfx token address and the owner.
     * Claiming period is not enabled.
     *
     * @param pfx_ the PFX token contract address
     */
    constructor(address pfx_) {
        pfx = pfx_;
        claimingAllowed = false;
        totalAllocated = 0;
    }

    /**
     * Enable the claiming period and allow user to claim PFX. Before activation,
     * this contract must have a PFX balance equal to the total airdrop PFX
     * supply. All claimable PFX tokens must be whitelisted before claiming is enabled.
     * Only callable by the owner.
     */
    function allowClaiming() external onlyOwner {
        require(IPFX(pfx).balanceOf(address(this)) >= TOTAL_AIRDROP_SUPPLY, 'InitialAirdrop::allowClaiming: Insufficient PFX supply');
        claimingAllowed = true;
        emit ClaimingAllowed();
    }

    /**
     * End the claiming period. All unclaimed PFX will be burnt.
     * Can only be called by the owner.
     */
    function endClaiming() external onlyOwner {
        require(claimingAllowed, 'InitialAirdrop::endClaiming: Claiming not started');

        claimingAllowed = false;
        emit ClaimingOver();

        // Burn the remainder
        uint256 amount = IPFX(pfx).balanceOf(address(this));
        require(IPFX(pfx).transfer(address(0), amount), 'InitialAirdrop::endClaiming: Burn failed');
    }

    /**
     * Withdraw your PFX. In order to qualify for a withdrawal, the caller's address
     * must be whitelisted. All PFX must be claimed at once. Only the full amount can be
     * claimed and only one claim is allowed per user.
     */
    function claim() external {
        require(claimingAllowed, 'InitialAirdrop::claim: Claiming is not allowed');
        require(withdrawAmount[msg.sender] > 0, 'InitialAirdrop::claim: No PFX to claim');

        uint256 amountToClaim = withdrawAmount[msg.sender];
        withdrawAmount[msg.sender] = 0;

        emit PfxClaimed(msg.sender, amountToClaim);

        require(IPFX(pfx).transfer(msg.sender, amountToClaim), 'InitialAirdrop::claim: Transfer failed');
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
    function whitelistAddress(address addr, uint96 pfxOut) public onlyOwner {
        require(!claimingAllowed, 'InitialAirdrop::whitelistAddress: Claiming in session');
        require(pfxOut > 0, 'InitialAirdrop::whitelistAddress: Allocated amount cannot be zero');

        if (withdrawAmount[addr] > 0) {
            totalAllocated -= withdrawAmount[addr];
        }

        withdrawAmount[addr] = pfxOut;

        totalAllocated += pfxOut;
        require(totalAllocated <= TOTAL_AIRDROP_SUPPLY, 'InitialAirdrop::whitelistAddress: Exceeds PFX allocation');
    }

    /**
     * Whitelist multiple addresses in one call. Wrapper around whitelistAddress.
     * All parameters are arrays. Each array must be the same length. Each index
     * corresponds to one (address, pfx) tuple. Only callable by the owner.
     */
    function whitelistAddresses(address[] memory addrs, uint96[] memory pfxOuts) external onlyOwner {
        require(addrs.length == pfxOuts.length, 'InitialAirdrop::whitelistAddresses: incorrect array length');

        for (uint256 i = 0; i < addrs.length; i++) {
            whitelistAddress(addrs[i], pfxOuts[i]);
        }
    }
}
