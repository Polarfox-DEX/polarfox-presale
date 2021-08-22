const hre = require('hardhat')
const { CHAIN_ID } = require('../const')
const { PFX, NUMBER_OF_LEVELS } = require('../presaleConstants')
const PFX_CONTRACT = require('@polarfox/governance/artifacts/contracts/pfx/PFX.sol/PFX.json')

async function main() {
    const [admin] = await hre.ethers.getSigners()

    const chainId = await admin.getChainId()

    const apa = chainId == CHAIN_ID.AVALANCHE ? require('./json/production-addresses.json') : require('./json/test-addresses.json')

    // Run safety checks first
    if (!safetyChecks(apa.data)) return

    // #1: Deploy the VestedAirdrop contract
    const VestedAirdrop = await hre.ethers.getContractFactory('VestedAirdrop')
    const vestedAirdrop = await VestedAirdrop.deploy(PFX) // PFX address
    console.log('VestedAirdrop deployed to:', vestedAirdrop.address)

    // #2: Exclude the VestedAirdrop contract from PFX fees
    const pfx = await hre.ethers.getContractAt(PFX_CONTRACT.abi, PFX, admin)
    await pfx.excludeSrc(vestedAirdrop.address)
    await pfx.excludeDst(vestedAirdrop.address)
    console.log('VestedAirdrop excluded from PFX fees')

    // #3: Set addresses on the VestedAirdrop contract
    const array = Array.from(apa.data)
    for (var i = 0; i < array.length; i++) {
        await vestedAirdrop.setAddressesForLevel(
            array[i].amountsPerAddresses.map((obj) => obj.address), // address[] memory addresses
            array[i].amountsPerAddresses.map((obj) => obj.amount), // uint256[] memory amounts
            array[i].level // uint8 level
        )

        console.log('Set addresses for level', array[i].level)
    }

    console.log('All done!')
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })

const safetyChecks = (data) => {
    // Safety check #1: levels should only appear once, start at 0 and end at 119
    // Isolate the levels
    const levels = data.map((obj) => obj.level).sort((a, b) => a - b)

    for (var i = 0; i < NUMBER_OF_LEVELS; i++) {
        if (levels[i] != i) {
            console.error('Levels are configurated incorrectly')
            return false
        }
    }

    // Safety check #2: an address should not appear twice in one level
    // For each level
    var error = false
    data.forEach((obj) => {
        // See if there is a duplicate in the addresses
        const addresses = obj.amountsPerAddresses.map((obj_) => obj_.address)
        const uniqueAddresses = Array.from(new Set(addresses))

        if (addresses.length != uniqueAddresses.length) {
            console.error(`Some addresses in level ${obj.level} appear multiple times`)
            error = true
        }
    })
    if (error == true) return false

    console.log('Safety checks OK')
    return true
}
