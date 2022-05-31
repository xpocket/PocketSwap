const Pocket = artifacts.require("Pocket.sol")
const PocketOKC = artifacts.require("PocketOKC.sol")

module.exports = async function (deployer, network) {
    const PocketContract = network === 'okc' ? PocketOKC : Pocket;
    await deployer.deploy(PocketContract);
    console.log(`POCKET address: ${(await PocketContract.deployed()).address}`);
};
