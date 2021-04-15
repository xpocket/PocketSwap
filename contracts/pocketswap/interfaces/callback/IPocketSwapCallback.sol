// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls TokenSwapActions#swap must implement this interface
interface IPocketSwapCallback {
    function pocketSwapCallback(
        uint256 amount0Delta,
        uint256 amount1Delta,
        bytes calldata data
    ) external;
}
