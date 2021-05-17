const PocketToken = artifacts.require("Pocket.sol")

contract("PocketSwap Token Rewards", accounts => {
    let pocket_token

    before(async () => {
        await PocketToken.new()
            .then(p => pocket_token = p)
    })

    it("Transfer 10% of tokens to account1", async () => {
        await pocket_token.transfer(accounts[1], "10050")
        assert.equal((await pocket_token.balanceOf(accounts[0])).toString(), "90450")
        assert.equal((await pocket_token.balanceOf(accounts[1])).toString(), "10050")
    })

    it("Transfer 25% of tokens to account2", async () => {
        await pocket_token.transfer(accounts[2], "25125")
        assert.equal((await pocket_token.balanceOf(accounts[0])).toString(), "65325")
        assert.equal((await pocket_token.balanceOf(accounts[1])).toString(), "10050")
        assert.equal((await pocket_token.balanceOf(accounts[2])).toString(), "25125")
    })

    it("Transfer 39% of tokens to account3", async () => {
        await pocket_token.transfer(accounts[3], "39195")
        assert.equal((await pocket_token.balanceOf(accounts[0])).toString(), "26130")
        assert.equal((await pocket_token.balanceOf(accounts[1])).toString(), "10050")
        assert.equal((await pocket_token.balanceOf(accounts[2])).toString(), "25125")
        assert.equal((await pocket_token.balanceOf(accounts[3])).toString(), "39195")
    })

    it("Add rewards proportionally", async () => {
        await pocket_token.addRewards("10050")
        assert.equal((await pocket_token.balanceOf(pocket_token.address)).toString(), "10050")
        assert.equal((await pocket_token.balanceOf(accounts[0])).toString(), "17688")
        assert.equal((await pocket_token.balanceOf(accounts[1])).toString(), "11055")
        assert.equal((await pocket_token.balanceOf(accounts[2])).toString(), "27637")
        assert.equal((await pocket_token.balanceOf(accounts[3])).toString(), "43114")
    })
})
