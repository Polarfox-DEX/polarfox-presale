const Web3 = require('web3')

const { CHAIN_ID, IS_PRODUCTION, getProvider } = require('./const')
const { AIRDROP } = require('./presaleConstants')
const airdropContract = require('../build/Airdrop.json')

const chainId = IS_PRODUCTION ? CHAIN_ID.AVALANCHE : CHAIN_ID.FUJI

const provider = getProvider(chainId)
const web3 = new Web3(provider)

// !! Before using this script, send 9,250,000 PFX to the Airdrop contract

const allowClaiming = async () => {
    const accounts = await web3.eth.getAccounts()

    console.log('Attempting to allow claiming from the account', accounts[0])
    
    const airdrop = new web3.eth.Contract(airdropContract.abi, AIRDROP)

    try {
        await airdrop.methods.allowClaiming().send({
            from: accounts[0]
        })

        console.log('Done!')
    } catch (error) {
        console.log('An error occurred in allowClaiming():', error)
    }
}

allowClaiming()
