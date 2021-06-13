const Web3 = require('web3')

const { CHAIN_ID, IS_PRODUCTION, getProvider } = require('./const')
const polarfoxTokenSale = require('../build/PolarfoxTokenSale.json')

const chainId = IS_PRODUCTION ? CHAIN_ID.ETHEREUM : CHAIN_ID.ROPSTEN
const akitaAddress = IS_PRODUCTION ? '0x3301ee63fb29f863f2333bd4466acb46cd8323e6' : '0x8f2f9A8A35C5cC90085A68Fe0ACA42D0c9Ce80dd'

const provider = getProvider(chainId)
const web3 = new Web3(provider)

const deployPTS = async () => {
    const accounts = await web3.eth.getAccounts()

    console.log('Attempting to deploy Polarfox token sale from the account', accounts[0])

    try {
        const deployedPTS = await new web3.eth.Contract(polarfoxTokenSale.abi)
            .deploy({
                data: '0x' + polarfoxTokenSale.evm.bytecode.object,
                arguments: [
                    '0x211550Ac42f0E8E82dda7CBC7B0CfCB0C710f954', // The recipient of the sell
                    akitaAddress // Akita address
                ]
            })
            .send({
                from: accounts[0]
            })

        console.log('Polarfox token sale deployed to', deployedPTS.options.address)
    } catch (error) {
        console.log('An error occurred in deployPTS():', error)
    }
}

deployPTS()
