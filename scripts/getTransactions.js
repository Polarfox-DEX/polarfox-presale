const Web3 = require('web3')
const fs = require('fs')

const { CHAIN_ID, IS_PRODUCTION, getProvider } = require('./const')
const polarfoxTokenSale = require('../build/PolarfoxTokenSale.json')

const chainId = IS_PRODUCTION ? CHAIN_ID.ETHEREUM : CHAIN_ID.ROPSTEN
const ptsAddress = IS_PRODUCTION ? '' : '0xEd28365a51e4b645AE405fb1274297012fE92C76'
const targetFile = 'transactions.json'

const provider = getProvider(chainId)
const web3 = new Web3(provider)

const getTransactions = async () => {
    const accounts = await web3.eth.getAccounts()

    console.log('Attempting to get transactions from the account', accounts[0])

    const dataList = []

    const pts = new web3.eth.Contract(polarfoxTokenSale.abi, ptsAddress)

    try {
        const numberOfBuyers = await pts.methods.numberOfBuyers().call()
        console.log('Number of buyers:', numberOfBuyers)

        for (i = 0; i < numberOfBuyers; i++) {
            console.log(`Sending calls for buyer #${i}...`)
            const buyer = await pts.methods.buyers(i).call()
            const transaction = await pts.methods.transactions(buyer).call()

            console.log(
                `[Transaction ${i}]`,
                'Buyer:', buyer,
                'Amount:', transaction.boughtAmount,
                'Recipient:', transaction.receivingAddress,
                'Block:', transaction.dateBought
            )

            const data = {
                id: i,
                buyer: buyer,
                amount: transaction.boughtAmount,
                recipient: transaction.receivingAddress,
                block: transaction.dateBought
            }

            dataList.push(data)
        }

        // write JSON string to a file
        fs.writeFile(targetFile, JSON.stringify(dataList), (error) => {
            if (error) {
                throw error
            }
            console.log('Wrote transactions to', targetFile)
        })

        console.log('Done sending calls!')
    } catch (error) {
        console.log('An error occurred in getTransactions():', error)
    }
}

getTransactions()
