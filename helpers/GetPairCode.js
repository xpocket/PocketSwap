const web3 = require('web3')
const fs = require('fs')

const rawPairCode = fs.readFileSync('build/contracts/PocketSwapPair.json')
const pairCode = JSON.parse(rawPairCode)

console.log(`Pair init code: ${web3.utils.keccak256(pairCode.bytecode)}`)
