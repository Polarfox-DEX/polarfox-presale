const Web3 = require('web3')

const { CHAIN_ID, IS_PRODUCTION, getProvider } = require('./const')
const { PFX } = require('./presaleConstants')
const airdropContract = require('../build/Airdrop.json')

const chainId = IS_PRODUCTION ? CHAIN_ID.AVALANCHE : CHAIN_ID.FUJI
const owner = '0x211550Ac42f0E8E82dda7CBC7B0CfCB0C710f954'

const provider = getProvider(chainId)
const web3 = new Web3(provider)

const deployAirdrop = async () => {
    const accounts = await web3.eth.getAccounts()

    console.log('Attempting to deploy Airdrop contract from the account', accounts[0])

    try {
        const airdrop = await new web3.eth.Contract(airdropContract.abi)
            .deploy({
                data: '0x' + airdropContract.evm.bytecode.object,
                arguments: [
                    PFX, // PFX address
                    owner // Contract owner
                ]
            })
            .send({
                from: accounts[0]
            })

        console.log('Airdrop contract deployed to', airdrop.options.address)
    } catch (error) {
        console.log('An error occurred in deployAirdrop():', error)
    }
}

deployAirdrop()
