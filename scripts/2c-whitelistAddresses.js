const Web3 = require('web3')

const { CHAIN_ID, IS_PRODUCTION, getProvider } = require('./const')
const { AIRDROP } = require('./presaleConstants')
const airdropContract = require('../build/Airdrop.json')

const chainId = IS_PRODUCTION ? CHAIN_ID.AVALANCHE : CHAIN_ID.FUJI
const recipients = ['0x211550Ac42f0E8E82dda7CBC7B0CfCB0C710f954', '0x54e478fe12699206BD5a7a70725847eFe9A540a9']
const amounts = ['1000000000000000000000', '1000000000000000000000']

const provider = getProvider(chainId)
const web3 = new Web3(provider)

const whitelistAddresses = async () => {
    const accounts = await web3.eth.getAccounts()

    console.log('Attempting to whitelist addresses from the account', accounts[0])
    
    const airdrop = new web3.eth.Contract(airdropContract.abi, AIRDROP)

    try {
        await airdrop.methods.whitelistAddresses(
            recipients, // address[] memory addrs
            amounts // uint96[] memory pfxOuts
        ).send({
            from: accounts[0]
        })

        console.log('Done!')
    } catch (error) {
        console.log('An error occurred in whitelistAddresses():', error)
    }
}

whitelistAddresses()
