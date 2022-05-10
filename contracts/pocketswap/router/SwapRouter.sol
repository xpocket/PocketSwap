// SPDX-License-Identifier: Unlicensed
pragma solidity =0.8.4;
pragma abicoder v2;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import {SwapProcessing} from "./swap/SwapProcessing.sol";

import {PeripheryValidation} from "../abstract/PeripheryValidation.sol";
import {PeripheryImmutableState} from "../abstract/PeripheryImmutableState.sol";
import {Multicall} from "../abstract/Multicall.sol";

import {IPocketSwapRouter} from "../interfaces/IPocketSwapRouter.sol";
import {IPocketSwapPair} from "../interfaces/IPocketSwapPair.sol";
import {IPocketSwapFactory} from "../interfaces/IPocketSwapFactory.sol";
import {IPocket} from "../interfaces/IPocket.sol";

import {PocketSwapLibrary} from "../libraries/PocketSwapLibrary.sol";
import {CallbackValidation} from "../libraries/CallbackValidation.sol";
import {PlainMath} from "../libraries/PlainMath.sol";
import {Path} from "../libraries/Path.sol";
import {TransferHelper} from "../libraries/TransferHelper.sol";

abstract contract SwapRouter is
IPocketSwapRouter,
PeripheryImmutableState,
PeripheryValidation,
Multicall,
SwapProcessing
{
    using PlainMath for uint;
    using Path for bytes;

    /// @dev Used as the placeholder value for amountInCached, because the computed amount in for an exact output swap
    /// can never actually be this value
    uint256 private constant DEFAULT_AMOUNT_IN_CACHED = type(uint256).max;

    /// @dev Transient storage variable used for returning the computed amount in for an exact output swap.
    uint256 private amountInCached = DEFAULT_AMOUNT_IN_CACHED;

    /// @inheritdoc IPocketSwapRouter
    function swap(SwapParams calldata params)
    external
    payable
    override
    checkDeadline(params.deadline)
    returns (uint256 amountOut)
    {
        amountOut = exactInputInternal(
            params.amountIn,
            params.recipient,
            SwapCallbackData({
                path: abi.encodePacked(params.tokenIn, params.tokenOut),
                payer: msg.sender
            })
        );
        require(amountOut >= params.amountOutMinimum, 'Too little received');
    }

    /// @inheritdoc IPocketSwapRouter
    function swapMulti(SwapMultiParams memory params)
    external
    payable
    override
    checkDeadline(params.deadline)
    returns (uint256 amountOut)
    {
        amountOut = 0;

        // msg.sender pays for the first hop
        address payer = msg.sender;

        while (true) {
            bool hasMultiplePools = params.path.hasMultiplePools();

            // the outputs of prior swaps become the inputs to subsequent ones
            params.amountIn = exactInputInternal(
                params.amountIn,
                hasMultiplePools ? address(this) : params.recipient, // for intermediate swaps, this contract custodies
                SwapCallbackData({
                    path: params.path.getFirstPool(),
                    payer: payer
                }) // only the first pool in the path is necessary
            );

            // decide whether to continue or terminate
            if (hasMultiplePools) {
                payer = address(this);
                // at this point, the caller has paid
                params.path = params.path.skipToken();
            } else {
                amountOut = params.amountIn;
                break;
            }
        }

        require(amountOut >= params.amountOutMinimum, 'Too little received');
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(uint amountA, uint reserveA, uint reserveB) external pure virtual /*override*/ returns (uint amountB) {
        return PocketSwapLibrary.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut)
    external
    view
    virtual
        /*override*/
    returns (uint amountOut)
    {
        return PocketSwapLibrary.getAmountOut(factory, amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut)
    external
    view
    virtual
        /*override*/
    returns (uint amountIn)
    {
        return PocketSwapLibrary.getAmountIn(factory, amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(uint amountIn, address[] memory path)
    external
    view
    virtual
    override
    returns (uint[] memory amounts)
    {
        return PocketSwapLibrary.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint amountOut, address[] memory path)
    external
    view
    virtual
    override
    returns (uint[] memory amounts)
    {
        return PocketSwapLibrary.getAmountsIn(factory, amountOut, path);
    }
}
