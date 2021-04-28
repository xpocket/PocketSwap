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
    returns (uint amountA, uint amountB, uint amountPocket, uint liquidity) {
        uint amountAPocket;
        uint amountBPocket;

        (amountA, amountB, amountAPocket, amountBPocket) = _addLiquidity(
            params.amount0Desired,
            params.amount1Desired,
            params.amount0Min,
            params.amount1Min,
            LiquidityCallbackData(
            {path : abi.encodePacked(params.token0, params.token1), payer : msg.sender}
            )
        );

        address pair = PairAddress.computeAddress(factory, params.token0, params.token1);

        if (params.token1 != address(pocket) && params.token0 == address(pocket)) {
            require(amountAPocket > 0 || amountBPocket > 0, "Cannot calculate POCKET value");
            address pairAPocket = IPocketSwapFactory(factory).getPair(params.token0, pocket);
            address pairBPocket = IPocketSwapFactory(factory).getPair(params.token1, pocket);

            if (amountAPocket > 0) {// found price POCKET -> tokenA
                if (pairBPocket == address(0)) {// create pair POCKET -> tokenB if doesn't exists
                    pairBPocket = IPocketSwapFactory(factory).createPair(params.token1, pocket);
                }
                // Additing Liquidity to POCKET->tokenB
                amountPocket = amountAPocket;
                uint amountB2PocketPair = amountB / 2;
                amountB -= amountB2PocketPair;
                TransferHelper.safeTransferFrom(params.token1, msg.sender, pairBPocket, amountB2PocketPair);
                IPocketSwapPair(pairBPocket).mint(params.recipient);
            } else {// found price POCKET -> tokenB
                if (pairAPocket == address(0)) {// create pair POCKET -> tokenA if doesn't exists
                    pairAPocket = IPocketSwapFactory(factory).createPair(params.token0, pocket);
                }
                // Additing Liquidity to POCKET->tokenA
                amountPocket = amountBPocket;
                uint amountA2PocketPair = amountA / 2;
                amountA -= amountA2PocketPair;
                TransferHelper.safeTransferFrom(params.token0, msg.sender, pairAPocket, amountA2PocketPair);
                IPocketSwapPair(pairAPocket).mint(params.recipient);
            }
        }

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
