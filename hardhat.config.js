const fs = require('fs')

const mnemonic = fs.existsSync('../mnemonic') ? fs.readFileSync('../mnemonic', 'utf-8').trim() : ''
if (!mnemonic) console.log('Missing mnemonic')

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
    solidity: {
        compilers: [
            {
                version: '0.8.7',
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 1000
                    }
                }
            }
        ]
    }
}
