const HDWalletProvider = require('@truffle/hdwallet-provider')
const fs = require('fs')

const CHAIN_ID = {
    ETHEREUM: 1,
    ROPSTEN: 3,
    AVALANCHE: 43114,
    FUJI: 43113
}

// Is production
const IS_PRODUCTION = false

const PROVIDER = {
    [CHAIN_ID.ETHEREUM]: 'https://mainnet.infura.io/v3/418e2ad2a59645cab005c2a1712a1873',
    [CHAIN_ID.ROPSTEN]: 'https://ropsten.infura.io/v3/418e2ad2a59645cab005c2a1712a1873',
    [CHAIN_ID.AVALANCHE]: 'https://avalanche--mainnet--rpc.datahub.figment.io/apikey/9dbc9db32d2aa223eec796262c6339b6/ext/bc/C/rpc',
    [CHAIN_ID.FUJI]: 'https://avalanche--fuji--rpc.datahub.figment.io/apikey/9dbc9db32d2aa223eec796262c6339b6/ext/bc/C/rpc'
}

// Danger zone
const MNEMONIC = '../mnemonic'

// Utilities
function safeReadFile(path) {
    try {
        return fs.readFileSync(path, 'utf8').trim()
    } catch (error) {
        console.error('An error occurred in safeReadFile("' + path + '"):\n', error)
    }
}

function getProvider(chainId) {
    const devMnemonic = safeReadFile(MNEMONIC)
    console.log('Dev mnemonic OK:', devMnemonic != undefined)

    return new HDWalletProvider(devMnemonic, PROVIDER[chainId])
}

// Export
module.exports = {
    CHAIN_ID,
    IS_PRODUCTION,
    getProvider
}
