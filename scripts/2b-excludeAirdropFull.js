const Web3 = require('web3')

const { CHAIN_ID, IS_PRODUCTION, getProvider } = require('./const')
const { PFX, AIRDROP } = require('./presaleConstants')
const pfxContract = require('./build-external/Pfx.json')

const chainId = IS_PRODUCTION ? CHAIN_ID.AVALANCHE : CHAIN_ID.FUJI

const provider = getProvider(chainId)
const web3 = new Web3(provider)

const excludeAirdropFull = async () => {
    const accounts = await web3.eth.getAccounts()

    console.log('Attempting to exclude airdrop in full from the account', accounts[0])
    
    const pfx = new web3.eth.Contract(pfxContract.abi, PFX)

    try {
        const accounts = await web3.eth.getAccounts()

        console.log('Excluding', AIRDROP, 'in full')

        await pfx.methods
            .excludeSrc(
                AIRDROP // The account to exclude from fees as source
            )
            .send({
                from: accounts[0]
            })

        console.log('excludeSrc() OK')

        await pfx.methods
            .excludeDst(
                AIRDROP // The account to exclude from fees as recipient
            )
            .send({
                from: accounts[0]
            })

        console.log('excludeDst() OK')

        console.log('Done!')
    } catch (error) {
        console.log('An error occurred in excludeAirdropFull():', error)
    }
}

excludeAirdropFull()


async function excludeFull(target) {
    }
