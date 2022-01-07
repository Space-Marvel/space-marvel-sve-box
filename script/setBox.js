const abi = require('./box.abi.json')

const privateKey =
  '0xa1793ba6240d5e36685e322bc3eb9247ca394721cd9af6871894a12a06000b42'

const BigNumber = require('bignumber.js')
const web3 = require('web3')
const rpc_node_mainnet = 'https://api.avax.network/ext/bc/C/rpc'
const rpc_node_testnet = 'https://api.avax-test.network/ext/bc/C/rpc'
const bscWeb3 = new web3(rpc_node_testnet)
const boxAddress = '0x77dFe53E226807Be7F6C9C52A1cF37fdcD60a2F4'
const boxContract = new bscWeb3.eth.Contract(abi, boxAddress)

async function createBox() {
  let gasPrice = await bscWeb3.eth.getGasPrice()
  const heroPayment = [
    '0x498966e1bBa2f1B1673d5997EF59aca357a8b3AA',
    new BigNumber(50).multipliedBy(10 ** 18).integerValue().toString()
  ]
  // const spaceshipPayment = [
  //   '0x498966e1bBa2f1B1673d5997EF59aca357a8b3AA',
  //   new BigNumber(100).multipliedBy(10 ** 18).integerValue(),
  // ]
  const method = boxContract.methods.createBox(
    '0x15c7760173F6b402F1996E76d85F608403331521', //SVEHeroCore
    'Hero',
    [heroPayment],
    10, // personal limit
    1641483969, //start time
    1641829569, // end time
    6, // max random
    [],
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
