// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.6.12;
pragma abicoder v2;

import "./SwapRouter.sol";
import "./LiquidityRouter.sol";
import "./abstract/PeripheryImmutableState.sol";

contract PocketSwapRouter is
PeripheryImmutableState,
PeripheryValidation,
SwapRouter,
LiquidityRouter
{
    constructor(address _factory, address _WETH9)
    PeripheryImmutableState(_factory, _WETH9) {}
}