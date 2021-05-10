// SPDX-License-Identifier: Unlicensed
pragma solidity =0.8.4;
pragma abicoder v2;

import "../interfaces/IPocketSwapLiquidityRouter.sol";
import "../interfaces/IPocketSwapRouter.sol";
import '../interfaces/IPocketSwapFactory.sol';
import "../libraries/Path.sol";
import "../libraries/Math.sol";
import "../libraries/PocketSwapLibrary.sol";
import "./PeripheryImmutableState.sol";
import "./PeripheryPayments.sol";

abstract contract LiquidityProcessing is
IPocketSwapLiquidityRouter,
PeripheryImmutableState,
PeripheryPayments
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
        address _factory = factory;
        // gas saving
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
        if (tokenA != pocket && tokenB != pocket) {
            address[] memory path = new address[](2);
            path[0] = pocket;
            if (IPocketSwapFactory(_factory).getPair(pocket, tokenA) != address(0)) {
                path[1] = tokenA;
                amountAPocket = PocketSwapLibrary.getAmountsIn(_factory, amountA/2, path)[0];
            }
            if (IPocketSwapFactory(_factory).getPair(pocket, tokenB) != address(0)) {
                path[1] = tokenB;
                amountBPocket = PocketSwapLibrary.getAmountsIn(_factory, amountB/2, path)[0];
            }
        }
    }
}
