// SPDX-License-Identifier: Unlicensed
pragma solidity =0.8.4;
pragma abicoder v2;

interface IPocketSwapLiquidityRouter {
    struct AddLiquidityParams {
        address token0; // Address of the First token in Pair
        address token1; // Address of the Second token in Pair
        address recipient; // address which will receive LP tokens
        uint256 amount0Desired; // Amount of the First token in Pair
        uint256 amount1Desired;// Amount of the Second token in Pair
        uint256 amount0Min; // mininum amount of the first token in pair
        uint256 amount1Min;// mininum amount of the second token in pair
        uint256 deadline; // reverts in case of transaction confirmed too late
    }

    function addLiquidity(AddLiquidityParams calldata params)
    external
    payable
    returns (uint amountA, uint amountB, uint amountPocket, uint liquidity);

    struct RemoveLiquidityParams {
        address tokenA; // Address of the First token in Pair
        address tokenB; // Address of the Second token in Pair
        uint liquidity; // Amount of the LP tokens you want to remove
        uint amountAMin; // Minimum amount you're expecting to receive of the First token
        uint amountBMin;// Minimum amount you're expecting to receive of the Second token
        address rewards; // Address of the rewards token (USDT, WETH, POCKET)
        address recipient; // Address which will receive tokens and rewards
        uint deadline;// Reverts in case of transaction confirmed too late
    }

    function removeLiquidity(RemoveLiquidityParams calldata params)
    external
    payable
    returns (uint amountA, uint amountB);
}
