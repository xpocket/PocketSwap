const {BigNumber, constants, Contract, ContractTransaction} = require("ethers");

const swap = async (
    tokenIn,
    tokenOut,
    amountIn,
    amountOutMinimum,
    t
) => {
    const inputIsWETH = weth9.address === tokenIn
    const outputIsWETH9 = tokenOut === weth9.address

    const value = inputIsWETH ? amountIn : 0

    const params = {
        tokenIn,
        tokenOut,
        recipient: outputIsWETH9 ? t.router.address : t.trader.address,
        deadline: 1,
        amountIn,
        amountOutMinimum,
    }

    const data = [t.router.interface.encodeFunctionData('swap', [params])]
    if (outputIsWETH9)
        data.push(t.router.interface.encodeFunctionData('unwrapWETH9', [amountOutMinimum, t.trader.address]))

    // ensure that the swap fails if the limit is any tighter
    params.amountOutMinimum += 1
    await expect(t.router.connect(t.trader).swap(params, {value})).to.be.revertedWith(
        'Too little received'
    )
    params.amountOutMinimum -= 1

    // optimized for the gas test
    return data.length === 1
        ? t.router.connect(t.trader).swap(params, {value})
        : t.router.connect(t.trader).multicall(data, {value})
};

const addLiquidity = async (
    token0,
    token1,
    recipient,
    amount0Desired,
    amount1Desired,
    amount0Min,
    amount1Min,
    deadline,
) => {

};

module.exports = {
    swap: swap,
    addLiquidity: addLiquidity,
}
