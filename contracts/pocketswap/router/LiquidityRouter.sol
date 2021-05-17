// SPDX-License-Identifier: Unlicensed
pragma solidity =0.8.4;
pragma abicoder v2;

import {LiquidityProcessing} from "./liquidity/LiquidityProcessing.sol";

import {PeripheryValidation} from "../abstract/PeripheryValidation.sol";
import {PeripheryImmutableState} from "../abstract/PeripheryImmutableState.sol";

import {IPocketSwapLiquidityRouter} from "../interfaces/IPocketSwapLiquidityRouter.sol";
import {IPocketSwapPair} from "../interfaces/IPocketSwapPair.sol";
import {IPocketSwapFactory} from "../interfaces/IPocketSwapFactory.sol";

import {PairAddress} from "../libraries/PairAddress.sol";
import {PocketSwapLibrary} from "../libraries/PocketSwapLibrary.sol";

abstract contract LiquidityRouter is
IPocketSwapLiquidityRouter,
PeripheryImmutableState,
PeripheryValidation,
LiquidityProcessing
{
    function addLiquidity(AddLiquidityParams calldata params)
    external
    payable
    override
    checkDeadline(params.deadline)
    returns (uint amountA, uint amountB, uint amountPocket, uint liquidity) {
        uint amountAPocket;
        uint amountBPocket;

        address pair = PairAddress.computeAddress(factory, params.token0, params.token1);

        (amountA, amountB, amountAPocket, amountBPocket) = calcLiquidity(params);
        pay(params.token0, msg.sender, pair, amountA);
        pay(params.token1, msg.sender, pair, amountB);
        liquidity = IPocketSwapPair(pair).mint(params.recipient);

        amountPocket = 0;
        if (params.token0 != pocket && params.token1 != pocket) {
            require(amountAPocket > 0 || amountBPocket > 0, "Cannot calculate POCKET value");
            address pairAPocket = IPocketSwapFactory(factory).getPair(params.token0, pocket);
            address pairBPocket = IPocketSwapFactory(factory).getPair(params.token1, pocket);

            if (amountAPocket > 0) {// found price POCKET -> tokenA
                amountPocket = amountAPocket;

                uint amountPocketSwap = amountA / 2;
                amountA -= amountPocketSwap;

                address pocketPair = PairAddress.computeAddress(factory, params.token0, pocket);
                pay(pocket, msg.sender, pocketPair, amountPocket);
                (address token0,) = PocketSwapLibrary.sortTokens(params.token0, pocket);
                (uint amount0Out, uint amount1Out) = pocket == token0 ? (uint(0), amountPocketSwap) : (amountPocketSwap, uint(0));
                IPocketSwapPair(pocketPair).swap(amount0Out, amount1Out, pair, "");
            } else {// found price POCKET -> tokenB
                amountPocket = amountBPocket;

                uint amountPocketSwap = amountB / 2;
                amountB -= amountPocketSwap;

                address pocketPair = PairAddress.computeAddress(factory, params.token1, pocket);
                pay(pocket, msg.sender, pocketPair, amountPocket);
                (address token0,) = PocketSwapLibrary.sortTokens(params.token1, pocket);
                (uint amount0Out, uint amount1Out) = pocket == token0 ? (uint(0), amountPocketSwap) : (amountPocketSwap, uint(0));
                IPocketSwapPair(pocketPair).swap(amount0Out, amount1Out, pair, "");
            }
        }
    }

    function calcLiquidity(AddLiquidityParams calldata params) public override view
    returns (uint amountA, uint amountB, uint amountAPocket, uint amountBPocket) {
        (amountA, amountB, amountAPocket, amountBPocket) = _addLiquidity(
            params.amount0Desired,
            params.amount1Desired,
            params.amount0Min,
            params.amount1Min,
            LiquidityCallbackData(
            {path : abi.encodePacked(params.token0, params.token1), payer : msg.sender}
            )
        );
    }

    bool locked = false;
    modifier lock() {
        require(!locked, "LOCKED");
        locked = true;
        _;
        locked = false;
    }

    function removeLiquidity(RemoveLiquidityParams calldata params)
    public
    payable
    override
    checkDeadline(params.deadline)
    lock
    returns (uint amountA, uint amountB) {
        IPocketSwapPair pair = IPocketSwapPair(
            PairAddress.computeAddress(factory, params.tokenA, params.tokenB)
        );
        pair.transferFrom(msg.sender, address(pair), params.liquidity);

        // send liquidity to pair
        (uint amount0, uint amount1) = pair.burn(address(this));
        (address token0,) = PocketSwapLibrary.sortTokens(params.tokenA, params.tokenB);
        (amountA, amountB) = params.tokenA == token0 ? (amount0, amount1) : (amount1, amount0);

        require(amountA >= params.amountAMin, 'PocketSwapRouter: INSUFFICIENT_A_AMOUNT');
        require(amountB >= params.amountBMin, 'PocketSwapRouter: INSUFFICIENT_B_AMOUNT');

        swapRewards(params.rewards, params.tokenA, amountA, params.recipient);
        swapRewards(params.rewards, params.tokenB, amountB, params.recipient);
    }

    function swapRewards(
        address rewardsAddress,
        address tokenAddress,
        uint256 amount,
        address recipient
    ) private {
        address pair = IPocketSwapFactory(factory).getPair(rewardsAddress, tokenAddress);
        if (pair == address(0)) {
            pay(tokenAddress, address(this), recipient, amount);
            return;
        }
        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = rewardsAddress;
        uint256 amountRewards = PocketSwapLibrary.getAmountsOut(factory, amount, path)[1];

        pay(tokenAddress, address(this), pair, amount);
        (address token0,) = PocketSwapLibrary.sortTokens(rewardsAddress, tokenAddress);
        (uint amount0Out, uint amount1Out) = tokenAddress == token0 ? (uint(0), amountRewards) : (amountRewards, uint(0));
        IPocketSwapPair(pair).swap(amount0Out, amount1Out, recipient, "");
    }
}
