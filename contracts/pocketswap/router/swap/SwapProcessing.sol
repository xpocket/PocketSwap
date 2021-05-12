// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.4;
pragma abicoder v2;

import {PocketSwapLibrary} from '../../libraries/PocketSwapLibrary.sol';
import {Path} from '../../libraries/Path.sol';
import {PairAddress} from '../../libraries/PairAddress.sol';
import {TransferHelper} from '../../libraries/TransferHelper.sol';
import {IPocketSwapPair} from "../../interfaces/IPocketSwapPair.sol";
import {IPocketSwapRouter} from "../../interfaces/IPocketSwapRouter.sol";
import {PeripheryImmutableState} from "../../abstract/PeripheryImmutableState.sol";
import {PeripheryPayments} from "../../abstract/PeripheryPayments.sol";

/// @title Processing routing functions
abstract contract SwapProcessing is
IPocketSwapRouter,
PeripheryImmutableState,
PeripheryPayments
{
    using Path for bytes;

    struct SwapCallbackData {
        bytes path;
        address payer;
    }

    function pairFor(
        address tokenA,
        address tokenB
    ) public view override returns (IPocketSwapPair) {
        return IPocketSwapPair(PairAddress.computeAddress(factory, tokenA, tokenB));
    }

    function exactInputInternal(
        uint256 amountIn,
        address recipient,
        SwapCallbackData memory data
    ) internal returns (uint256 amountOut) {
        (address tokenIn, address tokenOut) = data.path.decodeFirstPool();

        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        amountOut = PocketSwapLibrary.getAmountsOut(factory, amountIn, path)[1];

        _swap(recipient, amountIn, amountOut, data);
    }

    /// @dev Performs a single exact output swap
    function exactOutputInternal(
        uint256 amountOut,
        address recipient,
        SwapCallbackData memory data
    ) internal returns (uint256 amountIn) {
        (address tokenOut, address tokenIn) = data.path.decodeFirstPool();

        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        amountIn = PocketSwapLibrary.getAmountsIn(factory, amountOut, path)[0];

        _swap(recipient, amountIn, amountOut, data);
    }

    function _swap(
        address recipient,
        uint256 amountIn,
        uint256 amountOut,
        SwapCallbackData memory data
    ) private {
        (address tokenIn, address tokenOut) = data.path.decodeFirstPool();
        IPocketSwapPair pair = pairFor(tokenIn, tokenOut);

        pay(tokenIn, msg.sender, address(pair), amountIn);

        (address token0,) = PocketSwapLibrary.sortTokens(tokenIn, tokenOut);
        (uint amount0Out, uint amount1Out) = tokenIn == token0 ? (uint(0), amountOut) : (amountOut, uint(0));

        pair.swap(amount0Out, amount1Out, recipient, abi.encode(data));
    }
}
