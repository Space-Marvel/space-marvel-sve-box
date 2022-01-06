const SpaceMarvelBox = artifacts.require('SpaceMarvelBox')

const BigNumber = require('bignumber.js')

module.exports = function (deployer) {
  deployer.then(async () => {
    const box = await deployer.deploy(
      SpaceMarvelBox
    //   new BigNumber(100000).multipliedBy(10 ** 18).integerValue(),
    )

    const heroPayment=[
        '0x498966e1bBa2f1B1673d5997EF59aca357a8b3AA',
        new BigNumber(50).multipliedBy(10 ** 18).integerValue()
    ]
    const spaceshipPayment=[
        '0x498966e1bBa2f1B1673d5997EF59aca357a8b3AA',
        new BigNumber(100).multipliedBy(10 ** 18).integerValue()
    ]

    await box.createBox(
        '0x15c7760173F6b402F1996E76d85F608403331521', //SVEHeroCore
        'Hero',
        [heroPayment],
        10, // personal limit
        1641483969, //start time
        1641829569, // end time
        6, // max random
        []
    )

    await box.createBox(
        '0xD62DD7220D9d22247D130CA46ec496dE3c97b0D2', //SVEHeroCore
        'SpaceShip',
        [spaceshipPayment],
        10, // personal limit
        1641483969, //start time
        1641829569, // end time
        6, // max random
        []
    )
  })
}
