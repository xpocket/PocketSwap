pragma solidity =0.8.4;
pragma abicoder v2;

import './callback/IPocketSwapCallback.sol';
import "./IPocketSwapPair.sol";

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface IPocketSwapRouter is IPocketSwapCallback {
    function pairFor(
        address tokenA,
        address tokenB
    ) external view returns (IPocketSwapPair);

    struct SwapParams {
        address tokenIn; // Address of the token you're sending for a SWAP
        address tokenOut; // Address of the token you're going to receive
        address recipient; // Address which will receive tokenOut
        uint256 deadline; // will revert if transaction was confirmed too late
        uint256 amountIn; // amount of the tokenIn to be swapped
        uint256 amountOutMinimum; // minimum amount you're expecting to receive
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `SwapParams` in calldata
    /// @return amountOut The amount of the received token
    function swap(SwapParams calldata params) external payable returns (uint256 amountOut);

    struct SwapMultiParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }
    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `SwapMultiParams` in calldata
    /// @return amountOut The amount of the received token
    function swapMulti(SwapMultiParams calldata params) external payable returns (uint256 amountOut);

    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] memory path) external view returns (uint[] memory amounts);
}
