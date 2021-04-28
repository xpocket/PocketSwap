// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.6.12;
pragma abicoder v2;

import "../interfaces/IPocketSwapLiquidityRouter.sol";
import "../interfaces/IPocketSwapRouter.sol";
import '../interfaces/IPocketSwapFactory.sol';
import "../libraries/Path.sol";
import "../libraries/Math.sol";
import "../libraries/PocketSwapLibrary.sol";
import "./PeripheryImmutableState.sol";

abstract contract LiquidityProcessing is
PeripheryImmutableState,
IPocketSwapLiquidityRouter
{
    using Path for bytes;

    struct LiquidityCallbackData {
        bytes path;
        address payer;
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        LiquidityCallbackData memory data
    )
    internal
    returns (uint amountA, uint amountB, uint amountAPocket, uint amountBPocket) {
        address _factory = factory; // gas saving
        (address tokenA, address tokenB) = data.path.decodeFirstPool();

        // create the pair if it doesn't exist yet
        if (IPocketSwapFactory(_factory).getPair(tokenA, tokenB) == address(0)) {
            IPocketSwapFactory(_factory).createPair(tokenA, tokenB);
        }
        (uint reserveA, uint reserveB) = PocketSwapLibrary.getReserves(_factory, tokenA, tokenB);

        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = PocketSwapLibrary.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'PocketSwapRouter: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = PocketSwapLibrary.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'PocketSwapRouter: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }

        amountAPocket = 0;
        amountBPocket = 0;
        if (tokenA != address(pocket) && tokenB != address(pocket)) {
            address[] memory path = new address[](2);
            path[0] = pocket;
            path[1] = tokenA;
            if (IPocketSwapFactory(_factory).getPair(tokenA, pocket) != address(0)) {
                amountAPocket = PocketSwapLibrary.getAmountsIn(address(this), amountA, path)[0];
            }
            path[1] = tokenB;
            if (IPocketSwapFactory(_factory).getPair(tokenB, pocket) != address(0)) {
                amountBPocket = PocketSwapLibrary.getAmountsIn(address(this), amountB, path)[0];
            }
        }
    }
}
