const hre = require('hardhat')
const { CHAIN_ID } = require('../const')
const { PFX } = require('../presaleConstants')
const PFX_CONTRACT = require('@polarfox/governance/artifacts/contracts/pfx/PFX.sol/PFX.json')

async function main() {
    const [admin] = await hre.ethers.getSigners()

    const chainId = await admin.getChainId()

    const apa = chainId == CHAIN_ID.AVALANCHE ? require('./json/production-addresses.json') : require('./json/test-addresses.json')

    // Run safety checks first
    if (!safetyChecks(apa.data)) return

    // #1: Deploy the InitialAirdrop contract
    const InitialAirdrop = await hre.ethers.getContractFactory('InitialAirdrop')
    const initialAirdrop = await InitialAirdrop.deploy(PFX) // PFX address
    console.log('InitialAirdrop deployed to:', initialAirdrop.address)

    // #2: Exclude the InitialAirdrop contract from PFX fees
    const pfx = await hre.ethers.getContractAt(PFX_CONTRACT.abi, PFX, admin)
    await pfx.excludeSrc(initialAirdrop.address)
    await pfx.excludeDst(initialAirdrop.address)
    console.log('InitialAirdrop excluded from PFX fees')

    // #3: Set addresses on the InitialAirdrop contract
    const array = Array.from(apa.data)
    await initialAirdrop.whitelistAddresses(
        array.map(element => element.address), // address[] memory addrs
        array.map(element => element.amount) // uint96[] memory pfxOuts
    )
    console.log('Set addresses on InitialAirdrop')

    console.log('All done!')
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })

const safetyChecks = (data) => {
    // Safety check: an address should not appear twice

    // See if there is a duplicate in the addresses
    const addresses = data.map((element) => element.address)
    const uniqueAddresses = Array.from(new Set(addresses))

    if (addresses.length != uniqueAddresses.length) {
        console.error(`Some addresses appear multiple times`)
        return false
    }

    console.log('Safety checks OK')
    return true
}
