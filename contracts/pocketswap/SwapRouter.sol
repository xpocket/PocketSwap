// SPDX-License-Identifier: Unlicensed
pragma solidity =0.8.4;
pragma abicoder v2;

import "./libraries/PocketSwapLibrary.sol";
import "./libraries/CallbackValidation.sol";
import "./abstract/PeripheryValidation.sol";
import "./abstract/SwapProcessing.sol";
import "./abstract/Multicall.sol";
import "./libraries/PlainMath.sol";

abstract contract SwapRouter is
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
            SwapCallbackData({path : abi.encodePacked(params.tokenIn, params.tokenOut), payer : msg.sender})
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
                SwapCallbackData({path : params.path.getFirstPool(), payer : payer}) // only the first pool in the path is necessary
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

    /// @inheritdoc IPocketSwapCallback
    function pocketSwapCallback(
        uint256 amount0Delta,
        uint256 amount1Delta,
        bytes calldata _data
    ) external override {
        SwapCallbackData memory data = abi.decode(_data, (SwapCallbackData));
        (address tokenIn, address tokenOut) = data.path.decodeFirstPool();
        CallbackValidation.verifyCallback(factory, tokenIn, tokenOut);

        (bool isExactInput, uint256 amountToPay) = amount0Delta > 0
        ? (tokenIn < tokenOut, uint256(amount0Delta))
        : (tokenOut < tokenIn, uint256(amount1Delta));

        uint256 holdersFee = IPocketSwapFactory(factory).holdersFee();

        if (tokenIn != pocket && tokenOut != pocket) {
            // finding POCKET pair
            address token = tokenIn;
            address pocketPair = IPocketSwapFactory(factory).getPair(tokenIn, pocket);
            if (pocketPair == address(0)) {
                pocketPair = IPocketSwapFactory(factory).getPair(tokenOut, pocket);
                token = tokenOut;
                if (pocketPair == address(0)) {
                    revert("No POCKET pair");
                }
            }

            uint amount = IERC20(token).balanceOf(msg.sender) * holdersFee / 1e9;
            pay(token, msg.sender, pocketPair, amountPocket);
            (address token0,) = PocketSwapLibrary.sortTokens(token, pocket);
            (uint amount0Out, uint amount1Out) = pocket == token0 ? (uint(0), amount) : (amount, uint(0));
            IPocketSwapPair(pocketPair).swap(amount0Out, amount1Out, token, "");
        } else {
            uint256 feeAmount = IERC20(pocket).balanceOf(msg.sender) * holdersFee / 1e9;
            TransferHelper.safeTransferFrom(pocket, msg.sender, pocket, feeAmount);
        }

        if (!isExactInput && data.path.hasMultiplePools()) {
            data.path = data.path.skipToken();
            exactOutputInternal(amountToPay, msg.sender, data);
        }
    }


    function exactOutput(OutputParams calldata params) external payable override returns (uint256 amountIn) {
        amountIn = 0;
    }

    function exactOutputSingle(OutputSingleParams calldata params) external payable override returns (uint256 amountIn) {
        amountIn = 0;
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(uint amountA, uint reserveA, uint reserveB) public pure virtual /*override*/ returns (uint amountB) {
        return PocketSwapLibrary.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut)
    public
    view
    virtual
        /*override*/
    returns (uint amountOut)
    {
        return PocketSwapLibrary.getAmountOut(factory, amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut)
    public
    view
    virtual
        /*override*/
    returns (uint amountIn)
    {
        return PocketSwapLibrary.getAmountIn(factory, amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(uint amountIn, address[] memory path)
    public
    view
    virtual
        /*override*/
    returns (uint[] memory amounts)
    {
        return PocketSwapLibrary.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint amountOut, address[] memory path)
    public
    view
    virtual
        /*override*/
    returns (uint[] memory amounts)
    {
        return PocketSwapLibrary.getAmountsIn(factory, amountOut, path);
    }
}
