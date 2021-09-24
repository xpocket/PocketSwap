const Pocket = artifacts.require("Pocket.sol")

const config = require("../config.json")

module.exports = async function (deployer, network, accounts) {
    await deployer.deploy(Pocket);
    console.log(`POCKET address: ${(await Pocket.deployed()).address}`);
};
