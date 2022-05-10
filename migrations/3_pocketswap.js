const PocketSwapFactory = artifacts.require("pocketswap/PocketSwapFactory.sol")
const PocketSwapRouter = artifacts.require("pocketswap/PocketSwapRouter.sol")
const PocketSwap = artifacts.require("PocketSwap.sol")
const Pocket = artifacts.require("Pocket.sol")

const config = require("../config.json")

module.exports = async function (deployer) {
    let factory;
    let router;

    const pocket = await Pocket.deployed();

    await deployer.deploy(PocketSwapFactory, pocket.address);
    await PocketSwapFactory.deployed()
        .then(f => factory = f)
        .then(() => console.log('POCKET address: ', pocket.address))
        .then(() => console.log('Factory address: ', factory.address))
        .then(() => deployer.deploy(PocketSwapRouter, factory.address, config.WETH_ADDRESS, pocket.address))
        .then(() => PocketSwapRouter.deployed())
        .then(a => router = a)
        .then(() => console.log('Router address: ', router.address))
        .then(() => deployer.deploy(PocketSwap, router.address, factory.address, pocket.address, config.WETH_ADDRESS))
        .then(() => PocketSwap.deployed())
        .then(ps => console.log('PocketSwap address: ', ps.address))
};
