// SPDX-License-Identifier: Unlicensed
pragma solidity =0.8.4;
pragma abicoder v2;

import {PeripheryPayments} from "./pocketswap/abstract/PeripheryPayments.sol";
import {PeripheryImmutableState} from "./pocketswap/abstract/PeripheryImmutableState.sol";

import {IPocketSwapFactory} from "./pocketswap/interfaces/IPocketSwapFactory.sol";
import {IPocketSwapLiquidityRouter} from "./pocketswap/interfaces/IPocketSwapLiquidityRouter.sol";
import {IPocketSwapRouter} from "./pocketswap/interfaces/IPocketSwapRouter.sol";

import {PairAddress} from "./pocketswap/libraries/PairAddress.sol";

import {Pocket} from "./Pocket.sol";


contract PocketSwap is PeripheryImmutableState, PeripheryPayments {
    struct PocketSwapInitializeParams {
        address router;
        address factory;
        address pocket;
        address WETH9;
    }

    address public _owner;
    address public router;

    modifier onlyOwner() {
        if (msg.sender == _owner) _;
    }

    constructor(address router_, address factory_, address pocket_, address WETH9_)
    PeripheryImmutableState(factory_, WETH9_, pocket_) {
        _owner = msg.sender;
        router = router_;
    }

    function owner() external view returns (address) {
        return _owner;
    }

    function swap(IPocketSwapRouter.SwapParams calldata params)
    payable external {
        pay(params.tokenIn, msg.sender, address(this), params.amountIn);
        approve(params.tokenIn, router, params.amountIn);
        try IPocketSwapRouter(router).swap(params) {}
        catch Error(string memory reason) {
            revert(string(abi.encodePacked("NOK: ", reason)));
        }
    }

    function addLiquidity(IPocketSwapLiquidityRouter.AddLiquidityParams calldata params)
    payable external {
        // create the pair if it doesn't exist yet
        if (IPocketSwapFactory(factory).getPair(params.token0, params.token1) == address(0)) {
            IPocketSwapFactory(factory).createPair(params.token0, params.token1);
        }

        (uint amountA, uint amountB, uint amountAPocket, uint amountBPocket) =
        IPocketSwapLiquidityRouter(router).calcLiquidity(params);

        // sending tokens to router
        pay(params.token0, msg.sender, address(this), amountA);
        approve(params.token0, router, amountA);
        pay(params.token1, msg.sender, address(this), amountB);
        approve(params.token1, router, amountB);

        // if needed, send pocket token to router
        if (params.token0 != pocket && params.token1 != pocket) {
            require(amountAPocket > 0 || amountBPocket > 0, "Cannot calculate POCKET value");
            if (amountAPocket > 0) {
                pay(pocket, msg.sender, address(this), amountAPocket);
                approve(pocket, router, amountAPocket);
            } else {
                pay(pocket, msg.sender, address(this), amountBPocket);
                approve(pocket, router, amountBPocket);
            }
        }

        try IPocketSwapLiquidityRouter(router).addLiquidity(params) {}
        catch Error(string memory reason) {
            revert(string(abi.encodePacked("NOK: ", reason)));
        }
    }

    function removeLiquidity(IPocketSwapLiquidityRouter.RemoveLiquidityParams calldata params) external {
        // sending LP to router
        address pair = PairAddress.computeAddress(factory, params.tokenA, params.tokenB);
        pay(pair, msg.sender, address(this), params.liquidity);
        approve(pair, router, params.liquidity);

        try IPocketSwapLiquidityRouter(router).removeLiquidity(params) {}
        catch Error(string memory reason) {
            revert(string(abi.encodePacked("NOK: ", reason)));
        }
    }

    function getAmountsIn(uint amountOut, address[] memory path) external view returns (uint[] memory) {
        return IPocketSwapRouter(router).getAmountsIn(amountOut, path);
    }

    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory) {
        return IPocketSwapRouter(router).getAmountsOut(amountIn, path);
    }
}
