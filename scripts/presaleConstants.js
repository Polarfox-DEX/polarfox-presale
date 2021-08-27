const { IS_PRODUCTION } = require('./const')

// TODO: Need to rewrite this so this works with the hardhat scripts
const PFX = IS_PRODUCTION ? '' : '0x5728Feb0ABF97938Bbd205fea7148c87d8721C3A'

const NUMBER_OF_LEVELS = 120

// Export
module.exports = {
    PFX,
    NUMBER_OF_LEVELS
}
