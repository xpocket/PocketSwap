const PocketSwapSol = artifacts.require("PocketSwap.sol")

let contract

module.exports = {
    new: async (router, factory, pocket_token, WETH) => await PocketSwapSol.new(router, factory, pocket_token, WETH)
        .then(a => contract = a)
        .then(() => this),
    at: async address => await PocketSwapSol.at(address)
        .then(a => contract = a)
        .then(() => this),
    address: contract ? contract.address : "0x0000000000000000000000000000000000000000",
    owner: () => contract.owner(),
    getAmountsOut: (amountIn, path) => contract.getAmountsOut(amountIn, path),
    swapParams: (tokenIn, tokenOut, recipient, deadline, amountIn, amountOutMinimum) => ({
        tokenIn,
        tokenOut,
        recipient,
        deadline,
        amountIn,
        amountOutMinimum
    }),
    addLiquidityParams: (token0, token1, recipient, amount0Desired, amount1Desired, amount0Min, amount1Min, deadline) => ({
        token0,
        token1,
        recipient,
        amount0Desired,
        amount1Desired,
        amount0Min,
        amount1Min,
        deadline
    }),
    removeLiquidityParams: (tokenA, tokenB, liquidity, amountAMin, amountBMin, rewards, recipient, deadline) => ({
        tokenA,
        tokenB,
        liquidity,
        amountAMin,
        amountBMin,
        rewards,
        recipient,
        deadline
    }),
    swap: (swapParams, txParams) => contract.swap(swapParams, txParams),
    addLiquidity: (addLiquidityParams, txParams) => contract.swap(addLiquidityParams, txParams),
    removeLiquidity: (removeLiquidityParams, txParams) => contract.swap(removeLiquidityParams, txParams),
}
