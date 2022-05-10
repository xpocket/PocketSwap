const helper = require("./helper");
const ERC20 = artifacts.require("mocks/MockERC20.sol")
const Pocket = artifacts.require("mocks/MockPocket.sol")
const WETH9 = artifacts.require("mocks/WETH9.sol")
const PocketSwapFactory = artifacts.require("pocketswap/PocketSwapFactory.sol")
const PocketSwapRouter = artifacts.require("pocketswap/PocketSwapRouter.sol")
const PocketSwapPair = artifacts.require("pocketswap/PocketSwapPair.sol")
const PocketSwap = artifacts.require("PocketSwap.sol")

contract("PocketSwap WETH", accounts => {
    const burnedLiquidity = BigInt(1000)
    let token
    let pocket_token
    let WETH
    let pair
    let pocketSwap
    let factory
    let token2pocket_liq1 = "10000000000000000000000000";
    let token2pocket_liq2 = "10000000000000000000000";

    const deadline = () => {
        return parseInt(Date.now() / 1000) + 15 * 60
    }

    beforeEach(async () => {
        let router

        await Promise.all([
            ERC20.new(),
            Pocket.new(),
            WETH9.new(),
        ]).then(([a, b, c]) => [token, pocket_token, WETH] = [a, b, c])
            .then(() => PocketSwapFactory.new(pocket_token.address))
            .then(a => factory = a)
            .then(() => PocketSwapRouter.new(factory.address, WETH.address, pocket_token.address))
            .then(a => router = a)
            .then(() => PocketSwap.new(router.address, factory.address, pocket_token.address, WETH.address))
            .then(a => pocketSwap = a)
            .then(() => factory.createPair(token.address, WETH.address))
            .then(() => factory.getPair(token.address, WETH.address))
            .then(a => PocketSwapPair.at(a))
            .then(p => pair = p)
            .then(async () => {
                const acc = accounts[9]
                await factory.createPair(WETH.address, pocket_token.address)
                await pocket_token.excludeFromRewards(acc);
                await AddLiquidity(acc, [pocket_token], [token2pocket_liq1, token2pocket_liq2])
            })
    })

    it("0.3% fees to LP", async () => {
        await checkFees(0.3)
    })

    async function AddLiquidity(liqAcc, tokens, liq) {
        const [token_1] = tokens
        const [token_1_liq, token_2_liq] = liq
        await token_1.mint(liqAcc, token_1_liq.toString(), {from: liqAcc})
        await token_1.approve(pocketSwap.address, token_1_liq.toString(), {from: liqAcc})

        await pocketSwap.addLiquidity({
            token0: token_1.address,
            token1: WETH.address,
            recipient: liqAcc,
            amount0Desired: token_1_liq.toString(),
            amount1Desired: token_2_liq.toString(),
            amount0Min: token_1_liq.toString(),
            amount1Min: token_2_liq.toString(),
            deadline: deadline(),
        }, {from: liqAcc, value: token_2_liq.toString()})
    }

    const checkFees = async (feePercent) => {
        await factory.setFee(feePercent * 1e7)
        const token_liq = BigInt("1000000000000000")
        const eth_liq = BigInt("10000000000000000000")
        const tokenIn = BigInt("100000000000")
        const totalLiq = BigInt(Math.floor(Math.sqrt(parseInt(token_liq * eth_liq))))

        const liqAcc = accounts[0]
        await AddLiquidity(liqAcc, [token], [token_liq, eth_liq])

        let acc0LiquidityBalance = await pair.balanceOf(liqAcc)
        assert.isTrue(Math.abs(parseInt(BigInt(acc0LiquidityBalance) - totalLiq - burnedLiquidity)) < 1e7, 'Liquidity Balance')

        const out = await pocketSwap.getAmountsOut(tokenIn.toString(), [token.address, WETH.address])
        const outRef = out[1]

        let expectedOut = helper.expectOutput(tokenIn, feePercent * 1e7, [token_liq, eth_liq])
        assert.equal(outRef.toString(), expectedOut.toString(), `correct exchange - ${feePercent}%`)

        await token.mint(accounts[1], tokenIn.toString(), {from: accounts[1]})
        await token.approve(pocketSwap.address, tokenIn.toString(), {from: accounts[1]})

        await pocketSwap.swap({
            tokenIn: token.address,
            tokenOut: WETH.address,
            recipient: accounts[2],
            deadline: deadline(),
            amountIn: tokenIn.toString(),
            amountOutMinimum: expectedOut.toString(),
        }, {from: accounts[1]})

        let pairBalance1 = await token.balanceOf(pair.address)
        let pairBalance2 = await WETH.balanceOf(pair.address)

        acc0LiquidityBalance = await pair.balanceOf(liqAcc)

        let token1BalanceExpected = BigInt(pairBalance1) * BigInt(acc0LiquidityBalance) / totalLiq
        let token2BalanceExpected = BigInt(pairBalance2) * BigInt(acc0LiquidityBalance) / totalLiq
        let pocketRewardsBalanceExpected = helper.expectOutput(token2BalanceExpected, feePercent * 1e7, [
            BigInt(token2pocket_liq1), BigInt(token2pocket_liq2)
        ])

        let was_acc0PocketBalance = await pocket_token.balanceOf(liqAcc);
        await pair.approve(pocketSwap.address, acc0LiquidityBalance.toString(), {from: liqAcc})
        await pocketSwap.removeLiquidity({
            tokenA: token.address,
            tokenB: WETH.address,
            liquidity: acc0LiquidityBalance.toString(), // liq
            amountAMin: token1BalanceExpected.toString(),
            amountBMin: token2BalanceExpected.toString(),
            rewards: pocket_token.address,
            recipient: liqAcc,
            deadline: deadline(),
        }, {from: liqAcc})

        let acc0Balance1 = await token.balanceOf(liqAcc)
        let now_acc0PocketBalance = await pocket_token.balanceOf(liqAcc);

        assert.equal(acc0Balance1.toString(), token1BalanceExpected.toString(), `Token1: ${feePercent}% Fee to LP`)
        assert.isAbove(parseInt(now_acc0PocketBalance), parseInt(was_acc0PocketBalance), `Pocket: ${feePercent}% Fee to LP`)
    }
})
