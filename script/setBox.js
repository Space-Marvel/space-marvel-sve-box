const abi = require('./box.abi.json')

const privateKey =
  '0xa1793ba6240d5e36685e322bc3eb9247ca394721cd9af6871894a12a06000b42'

  const BigNumber = require("bignumber.js");
const web3 = require('web3')
const rpc_node_mainnet = 'https://api.avax.network/ext/bc/C/rpc'
const rpc_node_testnet = 'https://data-seed-prebsc-1-s1.binance.org:8545/'
const bscWeb3 = new web3(rpc_node_testnet)
const boxAddress = '0xc44252FBb0e62B662Db59e3036e465B441f0F0bA'
const boxContract = new bscWeb3.eth.Contract(abi, boxAddress)

async function createBox() {
  let gasPrice = await bscWeb3.eth.getGasPrice()

  const heroPayment = ['0xb04Eb81A8c1Dc123315d19B945feCff186503d87', 500000000]

  let idList=   [
    2604, 2694,2572,2695,2603,2673,2607,2696,2576
  ]

  const method = boxContract.methods.createBox(
    '0x2d844811FC8f5023B215ddF0f3643Ce27764F7D1', //SEVHeroCore
    'BOX HERO TEST',
    [heroPayment],
    10,
    1641483969,
    1655497499,
    idList,
    [0, 10, 50, 90, 97, 99, 100]
  )

  const txData = method.encodeABI()
  let tx = {
    to: boxAddress,
    value: 0,
    gas: 3000000,
    gasPrice: gasPrice * 2,
    data: txData,
  }

  const signed = await bscWeb3.eth.accounts.signTransaction(tx, privateKey)
  const receipt = await bscWeb3.eth.sendSignedTransaction(signed.rawTransaction)
  console.log(
    '[',
    Date(),
    ']',
    'META RECEIPT - tx:',
    receipt.transactionHash,
    ' - block: ',
    receipt.blockNumber,
    ' - blockHash: ',
    receipt.blockHash,
  )
}

createBox()
