const { IS_PRODUCTION } = require('./const')

const PFX = IS_PRODUCTION ? '' : '0x683FBa38e08e768981a42dB6425a01864cBA8d63'
const AIRDROP = IS_PRODUCTION ? '' : '0xB4c1eB86a66B0b781F672a38372c138C21ED2D13'

// Export
module.exports = {
    PFX,
    AIRDROP
}
