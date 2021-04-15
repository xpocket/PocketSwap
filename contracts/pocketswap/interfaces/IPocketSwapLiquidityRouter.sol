// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.6.12;
pragma abicoder v2;

interface IPocketSwapLiquidityRouter {
    struct AddLiquidityParams {
        address token0;
        address token1;
        address recipient;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    function addLiquidity(AddLiquidityParams calldata params)
    external
    payable
    returns (uint amountA, uint amountB, uint liquidity);

    struct RemoveLiquidityParams {
        address tokenA;
        address tokenB;
        uint liquidity;
        uint amountAMin;
        uint amountBMin;
        address recipient;
        uint deadline;
    }

    function removeLiquidity(RemoveLiquidityParams calldata params)
    external
    payable
    returns (uint amountA, uint amountB);
}
