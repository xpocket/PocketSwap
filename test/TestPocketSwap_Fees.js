const ERC20 = artifacts.require("mocks/MockERC20.sol")
const PocketSwapFactory = artifacts.require("pocketswap/PocketSwapFactory.sol")
const PocketSwapRouter = artifacts.require("pocketswap/PocketSwapRouter.sol")
const PocketSwapPair = artifacts.require("pocketswap/PocketSwapPair.sol")

contract("PocketSwap Fees", accounts => {
    const burnedLiquidity = BigInt(1000);
    let token_1
    let token_2
    let pocket_token
    let WETH
    let factory
    let router
    let pair

    const deadline = () => {
        return parseInt(Date.now() / 1000) + 15 * 60
    }

    beforeEach(async () => {
        await Promise.all([
            ERC20.new(),
            ERC20.new(),
            ERC20.new(),
            ERC20.new(),
            PocketSwapFactory.new(accounts[0])
        ]).then(([a, b, c, d, e]) => [token_1, token_2, pocket_token, WETH, factory] = [a, b, c, d, e])
            .then(() => PocketSwapRouter.new(factory.address, WETH.address, pocket_token.address))
            .then(a => router = a)
            .then(() => factory.createPair(token_1.address, token_2.address))
            .then(() => factory.getPair(token_1.address, token_2.address))
            .then(a => PocketSwapPair.at(a))
            .then(p => pair = p)
            .then(async () => {
                const acc = accounts[9]
                await factory.createPair(token_2.address, pocket_token.address)
                await AddLiquidity(acc, [token_2, pocket_token], [BigInt(1e40), BigInt(1e40)])
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
    it("50% fees to LP", async () => {
        await checkFees(1.9)
    })

    async function AddLiquidity(liqAcc, tokens, liq, pocket_liq) {
        const [token_1, token_2] = tokens
        const [token_1_liq, token_2_liq] = liq
        await token_1.mint(liqAcc, token_1_liq.toString(), {from: liqAcc})
        await token_1.approve(router.address, token_1_liq.toString(), {from: liqAcc})
        await token_2.mint(liqAcc, token_2_liq.toString(), {from: liqAcc})
        await token_2.approve(router.address, token_2_liq.toString(), {from: liqAcc})

        if (pocket_liq) {
            await pocket_token.mint(liqAcc, pocket_liq.toString(), {from: liqAcc})
            await pocket_token.approve(router.address, pocket_liq.toString(), {from: liqAcc})
        }

        await router.addLiquidity({
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
        const token_1_liq = BigInt(1e24)
        const token_2_liq = BigInt(1e12)
        const pocket_liq = BigInt(1e12)
        const tokenIn = BigInt(1e20)
        const totalLiq = BigInt(Math.sqrt(parseInt(token_1_liq * token_2_liq)))

        const liqAcc = accounts[0];
        { // adding liqudity
            await AddLiquidity(liqAcc, [token_1, token_2], [token_1_liq, token_2_liq], pocket_liq);
        }

        let acc0LiquidityBalance = await pair.balanceOf(liqAcc)
        assert.equal(acc0LiquidityBalance, token_1_liq - burnedLiquidity, 'Liquidity Balance')

        const out = await router.getAmountsOut(tokenIn.toString(), [token_1.address, token_2.address]);
        const outRef = out[1]

        let [expectedOut, fee] = outputAndFee(tokenIn, feePercent * 1e7, [token_1_liq, token_2_liq])
        assert.equal(outRef.toString(), expectedOut.toString(), `correct exchange - ${feePercent}%`)

        await token_1.mint(accounts[1], tokenIn.toString(), {from: accounts[1]})
        await token_1.approve(router.address, tokenIn.toString(), {from: accounts[1]})
        await router.swap({
            tokenIn: token_1.address,
            tokenOut: token_2.address,
            recipient: accounts[1],
            deadline: deadline(),
            amountIn: tokenIn.toString(),
            amountOutMinimum: expectedOut.toString(),
        }, {from: accounts[1]})

        const nowToken2 = await token_2.balanceOf(accounts[1])
        const feeTaken = tokenIn - BigInt(nowToken2)

        console.assert(feeTaken.toString(), fee.toString(), `fee taken ${feePercent}%`)

        let pairBalance1 = await token_1.balanceOf(pair.address);
        let pairBalance2 = await token_2.balanceOf(pair.address);

        acc0LiquidityBalance = await pair.balanceOf(liqAcc)

        let token1BalanceExpected = BigInt(pairBalance1) * BigInt(acc0LiquidityBalance) / totalLiq
        let token2BalanceExpected = BigInt(pairBalance2) * BigInt(acc0LiquidityBalance) / totalLiq

        pair.approve(router.address, acc0LiquidityBalance.toString(), {from: liqAcc})
        await router.removeLiquidity({
            tokenA: token_1.address,
            tokenB: token_2.address,
            liquidity: acc0LiquidityBalance.toString(), // liq
            amountAMin: token1BalanceExpected.toString(),
            amountBMin: token2BalanceExpected.toString(),
            recipient: liqAcc,
            deadline: deadline(),
        }, {from: liqAcc})

        let acc0Balance1 = await token_1.balanceOf(liqAcc);
        let acc0Balance2 = await token_2.balanceOf(liqAcc);

        assert.equal(acc0Balance1.toString(), token1BalanceExpected.toString(), `Token1: ${feePercent}% Fee to LP`)
        assert.equal(acc0Balance2.toString(), token2BalanceExpected.toString(), `Token2: ${feePercent}% Fee to LP`)
    }

    const outputAndFee = (input, fee, liq) => {
        const inputWithFee = input * BigInt(1e9 - fee)
        const numerator = inputWithFee * liq[1]
        const denominator = liq[0] * BigInt(1e9) + inputWithFee
        const expectedOut = numerator / denominator

        if (fee === 0) {
            return [expectedOut, expectedOut]
        }

        return [expectedOut, outputAndFee(input, 0, liq)[0] - expectedOut]
    }
})
