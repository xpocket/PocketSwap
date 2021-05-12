// SPDX-License-Identifier: Unlicensed
pragma solidity =0.8.4;
pragma abicoder v2;

import "./router/SwapRouter.sol";
import "./router/LiquidityRouter.sol";
import "./abstract/PeripheryImmutableState.sol";

contract PocketSwapRouter is
PeripheryImmutableState,
PeripheryValidation,
SwapRouter,
LiquidityRouter
{
    constructor(address _factory, address _WETH9, address _pocketToken)
    PeripheryImmutableState(_factory, _WETH9, _pocketToken) {}
}