const Pocket = artifacts.require("Pocket.sol")

module.exports = async function (deployer) {
    await deployer.deploy(Pocket);
    console.log(`POCKET address: ${(await Pocket.deployed()).address}`);
};
