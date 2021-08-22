const { IS_PRODUCTION } = require('./const')

// TODO: Need to rewrite this so this works with the hardhat scripts
const PFX = IS_PRODUCTION ? '' : '0x683FBa38e08e768981a42dB6425a01864cBA8d63'

const NUMBER_OF_LEVELS = 120

// Export
module.exports = {
    PFX,
    NUMBER_OF_LEVELS
}
