const helper = require("./helper");
const ERC20 = artifacts.require("mocks/MockERC20.sol")
const Pocket = artifacts.require("mocks/MockPocket.sol")
const PocketSwapFactory = artifacts.require("pocketswap/PocketSwapFactory.sol")
const PocketSwapRouter = artifacts.require("pocketswap/PocketSwapRouter.sol")
const PocketSwapPair = artifacts.require("pocketswap/PocketSwapPair.sol")
const PocketSwap = artifacts.require("PocketSwap.sol")

contract("PocketSwap Fees", accounts => {
    const burnedLiquidity = 1000;
    let token_1
    let token_2
    let pocket_token
    let WETH
    let factory
    let pair
    let pocketSwap
    let token2pocket_liq1 = "10000000000000000000000000";
    let token2pocket_liq2 = "10000000000000000000000000";

    const deadline = () => {
        return parseInt(Date.now() / 1000) + 15 * 60
    }

    beforeEach(async () => {
        let router
        await Promise.all([
            ERC20.new(),
            ERC20.new(),
            Pocket.new(),
            ERC20.new(),
        ]).then(([a, b, c, d]) => [token_1, token_2, pocket_token, WETH] = [a, b, c, d])
            .then(() => PocketSwapFactory.new(pocket_token.address))
            .then(a => factory = a)
            .then(() => PocketSwapRouter.new(factory.address, WETH.address, pocket_token.address))
            .then(a => router = a)
            .then(() => PocketSwap.new(router.address, factory.address, pocket_token.address, WETH.address))
            .then(a => pocketSwap = a)
            .then(() => factory.createPair(token_1.address, token_2.address))
            .then(() => factory.getPair(token_1.address, token_2.address))
            .then(a => PocketSwapPair.at(a))
            .then(p => pair = p)
            // .then(p => {
            //     console.log(`Factory: ${factory.address}`)
            //     console.log(`Router: ${router.address}`)
            //     console.log(`PocketSwap: ${pocketSwap.address}`)
            //     console.log(`Pocket: ${pocket_token.address}`)
            //     console.log(`Token1: ${token_1.address}`)
            //     console.log(`Token2: ${token_2.address}`)
            //     console.log(`Token1:Token2 pair: ${p.address}`)
            // })
            .then(async () => {
                const acc = accounts[9]
                await factory.createPair(token_2.address, pocket_token.address)
                await pocket_token.excludeFromRewards(acc);
                await AddLiquidity(acc, [token_2, pocket_token], [token2pocket_liq1, token2pocket_liq2])
            })
    })

    it("0.3% fees to LP", async () => {
        await checkFees(0.3)
    })
    it("0.5% fees to LP", async () => {
        await checkFees(0.5)
    })
    it("1.9% fees to LP", async () => {
        await checkFees(1.9)
    })
    it("35% fees to LP", async () => {
        await checkFees(35)
    })

    async function AddLiquidity(liqAcc, tokens, liq) {
        const [token_1, token_2] = tokens
        const [token_1_liq, token_2_liq] = liq
        await token_1.mint(liqAcc, token_1_liq.toString(), {from: liqAcc})
        await token_1.approve(pocketSwap.address, token_1_liq.toString(), {from: liqAcc})
        await token_2.mint(liqAcc, token_2_liq.toString(), {from: liqAcc})
        await token_2.approve(pocketSwap.address, token_2_liq.toString(), {from: liqAcc})

        await pocketSwap.addLiquidity({
            token0: token_1.address,
            token1: token_2.address,
            recipient: liqAcc,
            amount0Desired: token_1_liq.toString(),
            amount1Desired: token_2_liq.toString(),
            amount0Min: token_1_liq.toString(),
            amount1Min: token_2_liq.toString(),
            deadline: deadline(),
        }, {from: liqAcc})
    }

    const checkFees = async (feePercent) => {
        await factory.setFee(feePercent * 1e7)
        const token_1_liq = web3.utils.toWei("1000000")
        const token_2_liq = web3.utils.toWei("1000")
        const tokenIn = web3.utils.toWei("100")
        const totalLiq = Math.sqrt(parseInt(token_1_liq) * parseInt(token_2_liq))

        const liqAcc = accounts[0];
        await AddLiquidity(liqAcc, [token_1, token_2], [token_1_liq, token_2_liq]);

        let acc0LiquidityBalance = await pair.balanceOf(liqAcc)
        assert.equal(acc0LiquidityBalance, totalLiq - burnedLiquidity, 'Liquidity Balance')

        const out = await pocketSwap.getAmountsOut(tokenIn.toString(), [token_1.address, token_2.address]);
        const outRef = out[1]

        let expectedOut = helper.expectOutput(tokenIn, feePercent * 1e7, [token_1_liq, token_2_liq])
        assert.equal(outRef.toString(), expectedOut.toString(), `correct exchange - ${feePercent}%`)

        await token_1.mint(accounts[1], tokenIn.toString(), {from: accounts[1]})
        await token_1.approve(pocketSwap.address, tokenIn.toString(), {from: accounts[1]})
        await pocketSwap.swap({
            tokenIn: token_1.address,
            tokenOut: token_2.address,
            recipient: accounts[1],
            deadline: deadline(),
            amountIn: tokenIn.toString(),
            amountOutMinimum: expectedOut.toString(),
        }, {from: accounts[1]})

        let pairBalance1 = await token_1.balanceOf(pair.address);
        let pairBalance2 = await token_2.balanceOf(pair.address);

        assert.equal(pairBalance1.toString(), web3.utils.toWei((1000000 + 100).toString()), `Incorrect pair token1 balance`)

        let totalLiq1 = await pair.totalSupply();
        let token1BalanceExpected = BigInt(pairBalance1) * BigInt(acc0LiquidityBalance) / BigInt(totalLiq1)
        let token2BalanceExpected = BigInt(pairBalance2) * BigInt(acc0LiquidityBalance) / BigInt(totalLiq1)

        let was_acc0PocketBalance = await pocket_token.balanceOf(liqAcc);
        await pair.approve(pocketSwap.address, acc0LiquidityBalance.toString(), {from: liqAcc})
        await pocketSwap.removeLiquidity({
            tokenA: token_1.address,
            tokenB: token_2.address,
            liquidity: acc0LiquidityBalance.toString(), // liq
            amountAMin: token1BalanceExpected,
            amountBMin: token2BalanceExpected,
            rewards: pocket_token.address,
            recipient: liqAcc,
            deadline: deadline(),
        }, {from: liqAcc})

        let now_acc0PocketBalance = await pocket_token.balanceOf(liqAcc)

        assert.isAbove(parseInt(now_acc0PocketBalance), parseInt(was_acc0PocketBalance), `Pocket: ${feePercent}% Fee to LP`)
    }
})
