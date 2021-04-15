pragma solidity >=0.6.12;
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
        address tokenIn;
        address tokenOut;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
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

    struct OutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }
    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `OutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(OutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct OutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }
    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `OutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(OutputParams calldata params) external payable returns (uint256 amountIn);
}
