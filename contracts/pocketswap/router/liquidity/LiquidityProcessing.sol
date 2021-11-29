// SPDX-License-Identifier: Unlicensed
pragma solidity =0.8.4;
pragma abicoder v2;

import {IPocketSwapLiquidityRouter} from "../../interfaces/IPocketSwapLiquidityRouter.sol";
import {IPocketSwapRouter} from "../../interfaces/IPocketSwapRouter.sol";
import {IPocketSwapFactory} from '../../interfaces/IPocketSwapFactory.sol';
import {Path} from "../../libraries/Path.sol";
import {Math} from "../../libraries/Math.sol";
import {PocketSwapLibrary} from "../../libraries/PocketSwapLibrary.sol";
import {PeripheryImmutableState} from "../../abstract/PeripheryImmutableState.sol";
import {PeripheryPayments} from "../../abstract/PeripheryPayments.sol";

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
    internal view
    returns (uint amountA, uint amountB) {
        // gas saving
        address _factory = factory;

        (address tokenA, address tokenB) = data.path.decodeFirstPool();
        (uint reserveA, uint reserveB) = PocketSwapLibrary.getReserves(_factory, tokenA, tokenB);

        if (reserveA == 0 && reserveB == 0) {
            return (amountADesired, amountBDesired);
        }

        uint amountBOptimal = PocketSwapLibrary.quote(amountADesired, reserveA, reserveB);
        if (amountBOptimal <= amountBDesired) {
            require(amountBOptimal >= amountBMin, 'PocketSwapRouter: INSUFFICIENT_B_AMOUNT');
            return (amountADesired, amountBOptimal);
        }

        uint amountAOptimal = PocketSwapLibrary.quote(amountBDesired, reserveB, reserveA);
        assert(amountAOptimal <= amountADesired);
        require(amountAOptimal >= amountAMin, 'PocketSwapRouter: INSUFFICIENT_A_AMOUNT');
        (amountA, amountB) = (amountAOptimal, amountBDesired);
    }
}
