// SPDX-License-Identifier: Unlicensed
pragma solidity =0.8.4;
pragma abicoder v2;

import {IPocketSwapFactory} from "./pocketswap/interfaces/IPocketSwapFactory.sol";
import {IPocketSwapRouter} from "./pocketswap/interfaces/IPocketSwapRouter.sol";
import {Pocket} from "./Pocket.sol";

contract PocketSwap {
    struct PocketSwapInitializeParams {
        address router;
        address factory;
        address pocket;
    }

    address public factory;
    address public router;
    address public pocketToken;

    uint public initialized = 2;
    address _owner;

    modifier onlyOwner() {
        if (msg.sender == _owner) _;
    }

    constructor() {
        _owner = msg.sender;
    }

    function owner() external returns (address) {
        return _owner;
    }

    function initialize(PocketSwapInitializeParams calldata params) external onlyOwner {
        require(initialized == 2);
        initialized = 1;

        pocketToken = params.pocket;
        factory = params.factory;
        router = params.router;
    }

    function swap(IPocketSwapRouter.SwapParams calldata params) external {
        IPocketSwapRouter(router).swap(params);
    }
}
