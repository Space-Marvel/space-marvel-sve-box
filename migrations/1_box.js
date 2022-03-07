const SpaceMarvelBox = artifacts.require('SpaceMarvelBox')

const BigNumber = require('bignumber.js')

module.exports = function (deployer) {
  deployer.then(async () => {
    const box = await deployer.deploy(
      SpaceMarvelBox
    //   new BigNumber(100000).multipliedBy(10 ** 18).integerValue(),
    )

    const heroPayment=[
        '0xb04Eb81A8c1Dc123315d19B945feCff186503d87', //SVE
        new BigNumber(50).multipliedBy(10 ** 18).integerValue()
    ]
    const spaceshipPayment=[
        '0xb04Eb81A8c1Dc123315d19B945feCff186503d87', //SVE
        new BigNumber(100).multipliedBy(10 ** 18).integerValue()
    ]

    // await box.createBox(
    //     '0x2d844811FC8f5023B215ddF0f3643Ce27764F7D1', //SVEHeroCore
    //     'Hero',
    //     [heroPayment],
    //     10, // personal limit
    //     1641483969, //start time
    //     1641829569, // end time
    //     []
    // )

    // await box.createBox(
    //     '0xD62DD7220D9d22247D130CA46ec496dE3c97b0D2', //SVEHeroCore
    //     'SpaceShip',
    //     [spaceshipPayment],
    //     10, // personal limit
    //     1641483969, //start time
    //     1641829569, // end time
    //     6, // max random
    //     []
    // )
  })
}
