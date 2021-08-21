pragma solidity ^0.5.16;

import './SafeMath.sol';

/**
 * The Polarfox treasury vester contract.
 * The treasury vesters' job is to distribute PFX to three multisig wallets over time:
 * 1/ The liquidity mining multisig, which will hold the PFX tokens to be sent for liquidity mining;
 * 2/ The governance treasury multisig, which will be given to the governance in time;
 * 3/ The team treasury multisig, which the team will use to fund its work.
 *
 * Five of such contracts will be deployed, four of which will last four years:
 * 1/ Pair Treasury Vester 2021-2025 | 5,232,000 PFX distributed | 4,800,000 PFX to liquidity mining (91.7%) | 432,000 PFX to governance treasury (08.3%);
 * 2/ Pair Treasury Vester 2025-2029 | 2,776,000 PFX distributed | 2,560,000 PFX to liquidity mining (92.2%) | 216,000 PFX to governance treasury (07.8%);
 * 3/ Pair Treasury Vester 2029-2033 | 1,388,000 PFX distributed | 1,280,000 PFX to liquidity mining (92.2%) | 108,000 PFX to governance treasury (07.8%);
 * 4/ Pair Treasury Vester 2033-2037 |   694,000 PFX distributed |   640,000 PFX to liquidity mining (92.2%) |  54,000 PFX to governance treasury (07.8%).
 *
 * 320,000 PFX will be set aside for the first round of liquidity mining, hence the difference in percentages between
 * the first treasury vester contract and the others.
 *
 * A fifth contract will be deployed separately for team funding and will last three years:
 * 5/ Treasury Vester 2021-2024 | 1,590,000 PFX distributed | 1,590,000 to team funding (100.0%)
 *
 * When those contracts are deployed, the Polarfox team will not be using multisigs as there are no good multisig
 * implementations of Avalanche at this time. The team will look into the possibility of creating our own multisig
 * wallets and change the recipients from this contract to the relevant multisig wallets.
 */
contract TreasuryVester {
    using SafeMath for uint256;

    address public pfx;
    address public recipient;

    uint256 public vestingAmount;
    uint256 public vestingBegin;
    uint256 public vestingCliff;
    uint256 public vestingEnd;

    uint256 public lastUpdate;

    constructor(
        address pfx_,
        address recipient_,
        uint256 vestingAmount_,
        uint256 vestingBegin_,
        uint256 vestingCliff_,
        uint256 vestingEnd_
    ) public {
        require(vestingBegin_ >= block.timestamp, 'TreasuryVester::constructor: vesting begin too early');
        require(vestingCliff_ >= vestingBegin_, 'TreasuryVester::constructor: cliff is too early');
        require(vestingEnd_ > vestingCliff_, 'TreasuryVester::constructor: end is too early');

        pfx = pfx_;
        recipient = recipient_;

        vestingAmount = vestingAmount_;
        vestingBegin = vestingBegin_;
        vestingCliff = vestingCliff_;
        vestingEnd = vestingEnd_;

        lastUpdate = vestingBegin;
    }

    function setRecipient(address recipient_) public {
        require(msg.sender == recipient, 'TreasuryVester::setRecipient: unauthorized');
        recipient = recipient_;
    }

    function claim() public {
        require(block.timestamp >= vestingCliff, 'TreasuryVester::claim: not time yet');
        uint256 amount;
        if (block.timestamp >= vestingEnd) {
            amount = IPfx(pfx).balanceOf(address(this));
        } else {
            amount = vestingAmount.mul(block.timestamp - lastUpdate).div(vestingEnd - vestingBegin);
            lastUpdate = block.timestamp;
        }
        IPfx(pfx).transfer(recipient, amount);
    }
}

interface IPfx {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address dst, uint256 rawAmount) external returns (bool);
}
