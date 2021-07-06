const PocketToken = artifacts.require("Pocket.sol")
const BN = require('bn.js')

contract("PocketSwap Token Rewards", accounts => {
    let pocket_token
    const total = new BN("50000000000000000000000000")
    let transferred = new BN()
    let sentTo = {}

    before(async () => {
        await PocketToken.new()
            .then(p => pocket_token = p)
    })

    it("Exclude owner from rewards", async () => {
        await pocket_token.excludeFromRewards(accounts[0])
    })

    it("Transfer 10% of tokens to account1", async () => {
        const toSend = new BN("100000000000000000000")
        transferred = toSend.add(transferred)
        sentTo[accounts[1]] = toSend

        await pocket_token.transfer(accounts[1], toSend)
        assert.equal((await pocket_token.balanceOf(accounts[0])).toString(), total.sub(transferred).toString())
        assert.equal((await pocket_token.balanceOf(accounts[1])).toString(), sentTo[accounts[1]].toString())
    })

    it("Transfer 25% of tokens to account2", async () => {
        const toSend = new BN("250000000000000000000")
        transferred = toSend.add(transferred)
        sentTo[accounts[2]] = toSend

        await pocket_token.transfer(accounts[2], toSend)
        assert.equal((await pocket_token.balanceOf(accounts[0])).toString(), total.sub(transferred).toString())
        assert.equal((await pocket_token.balanceOf(accounts[1])).toString(), sentTo[accounts[1]].toString())
        assert.equal((await pocket_token.balanceOf(accounts[2])).toString(), sentTo[accounts[2]].toString())
    })

    it("Transfer 39% of tokens to account3", async () => {
        const toSend = new BN("390000000000000000000")
        transferred = toSend.add(transferred)
        sentTo[accounts[3]] = toSend

        await pocket_token.transfer(accounts[3], toSend)
        assert.equal((await pocket_token.balanceOf(accounts[0])).toString(), total.sub(transferred).toString())
        assert.equal((await pocket_token.balanceOf(accounts[1])).toString(), sentTo[accounts[1]].toString())
        assert.equal((await pocket_token.balanceOf(accounts[2])).toString(), sentTo[accounts[2]].toString())
        assert.equal((await pocket_token.balanceOf(accounts[3])).toString(), sentTo[accounts[3]].toString())
    })

    it("Transfer 26% of tokens to account4", async () => {
        const toSend = new BN("260000000000000000000")
        transferred = toSend.add(transferred)
        sentTo[accounts[4]] = toSend

        await pocket_token.transfer(accounts[4], toSend)
        assert.equal((await pocket_token.balanceOf(accounts[0])).toString(), total.sub(transferred).toString())
        assert.equal((await pocket_token.balanceOf(accounts[1])).toString(), sentTo[accounts[1]].toString())
        assert.equal((await pocket_token.balanceOf(accounts[2])).toString(), sentTo[accounts[2]].toString())
        assert.equal((await pocket_token.balanceOf(accounts[3])).toString(), sentTo[accounts[3]].toString())
        assert.equal((await pocket_token.balanceOf(accounts[4])).toString(), sentTo[accounts[4]].toString())
    })

    it("Add rewards proportionally, excluding owner", async () => {
        const toSend = new BN("1000000000000000000000000")
        transferred = toSend.add(transferred)

        await pocket_token.addRewards(toSend)

        assert.equal((await pocket_token.balanceOf(pocket_token.address)).toString(), toSend.toString())
        assert.equal((await pocket_token.balanceOf(accounts[0])).toString(), total.sub(transferred).toString(), "No rewards")

        assert.equal((await pocket_token.balanceOf(accounts[1])).toString(), sentTo[accounts[1]].add(new BN("100000000000000000000000")).toString())
        assert.equal((await pocket_token.balanceOf(accounts[2])).toString(), sentTo[accounts[2]].add(new BN("250000000000000000000000")).toString())
        assert.equal((await pocket_token.balanceOf(accounts[3])).toString(), sentTo[accounts[3]].add(new BN("390000000000000000000000")).toString())
        assert.equal((await pocket_token.balanceOf(accounts[4])).toString(), sentTo[accounts[4]].add(new BN("260000000000000000000000")).toString())
    })
})
