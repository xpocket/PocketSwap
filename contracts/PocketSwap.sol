// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.6.12;
pragma abicoder v2;

import "./pocketswap/interfaces/IPocketSwapRouter.sol";

contract PocketSwap {
    IPocketSwapRouter public router;
    address public tokenHoldersFee;
    uint public rewardsPerToken;
    mapping(address => uint) public takenReward;

    function swap(IPocketSwapRouter.SwapParams calldata params) external {
        router.swap(params);
    }
}
