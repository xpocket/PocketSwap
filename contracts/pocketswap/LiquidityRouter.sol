// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.6.12;
pragma abicoder v2;

import "./abstract/LiquidityProcessing.sol";
import "./abstract/PeripheryValidation.sol";
import "./libraries/TransferHelper.sol";
import "./libraries/PairAddress.sol";

abstract contract LiquidityRouter is
PeripheryImmutableState,
PeripheryValidation,
LiquidityProcessing
{
    function addLiquidity(AddLiquidityParams calldata params)
    external
    payable
    override
    checkDeadline(params.deadline)
    returns (uint amountA, uint amountB, uint liquidity) {
        (amountA, amountB) = _addLiquidity(
            params.amount0Desired,
            params.amount1Desired,
            params.amount0Min,
            params.amount1Min,
            LiquidityCallbackData(
            {path : abi.encodePacked(params.token0, params.token1), payer : msg.sender}
            )
        );

        address pair = PairAddress.computeAddress(factory, params.token0, params.token1);
        TransferHelper.safeTransferFrom(params.token0, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(params.token1, msg.sender, pair, amountB);
        liquidity = IPocketSwapPair(pair).mint(params.recipient);
    }

    function removeLiquidity(RemoveLiquidityParams calldata params)
    public
    payable
    override
    checkDeadline(params.deadline)
    returns (uint amountA, uint amountB) {
        IPocketSwapPair pair = IPocketSwapPair(
            PairAddress.computeAddress(factory, params.tokenA, params.tokenB)
        );
        pair.transferFrom(msg.sender, address(pair), params.liquidity);

        // send liquidity to pair
        (uint amount0, uint amount1) = pair.burn(params.recipient);
        (address token0,) = PocketSwapLibrary.sortTokens(params.tokenA, params.tokenB);
        (amountA, amountB) = params.tokenA == token0 ? (amount0, amount1) : (amount1, amount0);

        require(amountA >= params.amountAMin, 'PocketSwapRouter: INSUFFICIENT_A_AMOUNT');
        require(amountB >= params.amountBMin, 'PocketSwapRouter: INSUFFICIENT_B_AMOUNT');
    }
}
