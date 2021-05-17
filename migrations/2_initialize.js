const PocketSwapFactory = artifacts.require("pocketswap/PocketSwapFactory.sol")
const PocketSwapRouter = artifacts.require("pocketswap/PocketSwapRouter.sol")
const PocketSwap = artifacts.require("PocketSwap.sol")
const Pocket = artifacts.require("Pocket.sol")

const config = require("../config.json")

module.exports = async function (deployer, network, accounts) {
    let pocket;
    let factory;
    let router;

    await Promise.all([
        Pocket.new(),
        PocketSwapFactory.new()
    ])
        .then(([p, f]) => [pocket, factory] = [p, f])
        .then(() => console.log('POCKET address: ', pocket.address))
        .then(() => console.log('Factory address: ', factory.address))
        .then(() => PocketSwapRouter.new(factory.address, config.WETH_ADDRESS, pocket.address))
        .then(a => router = a)
        .then(() => console.log('Router address: ', router.address))
        .then(() => PocketSwap.new(router.address, factory.address, pocket.address, config.WETH_ADDRESS))
        .then(ps => console.log('PocketSwap address: ', ps.address))
};
