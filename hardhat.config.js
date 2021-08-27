require('@nomiclabs/hardhat-waffle')

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
    },
    networks: {
        fuji: {
            url: 'https://api.avax-test.network/ext/bc/C/rpc',
            chainId: 43113,
            accounts: {
                mnemonic
            }
        }
    },
    namedAccounts: {
        klemah: {
            fuji: '0x211550Ac42f0E8E82dda7CBC7B0CfCB0C710f954'
        }
    }
}
