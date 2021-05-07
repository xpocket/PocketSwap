// SPDX-License-Identifier: Unlicensed
pragma solidity =0.8.4;
pragma abicoder v2;

import {PocketSwapFactory, IPocketSwapFactory} from "./pocketswap/PocketSwapFactory.sol";
import {PocketSwapRouter, IPocketSwapRouter} from "./pocketswap/PocketSwapRouter.sol";
import {Pocket} from "./Pocket.sol";

contract PocketSwap {
    IPocketSwapFactory public factory;
    IPocketSwapRouter public router;
    Pocket public pocketToken;

    bool public initialized;
    address _owner;

    address public tokenHoldersFee;
    uint public rewardsPerToken;
    mapping(address => uint) public takenReward;

    modifier onlyOwner() {
        if (msg.sender == _owner) _;
    }

    constructor() {
        _owner = msg.sender;
    }

    function initialize(
        address _WETH9,
        string memory name_,
        string memory symbol_,
        uint256 supply_
    ) external onlyOwner {
        address creator = msg.sender;
        pocketToken = new Pocket(name_, symbol_, supply_);
        factory = new PocketSwapFactory(creator);
        router = new PocketSwapRouter(address(factory), _WETH9, address(pocketToken));
    }

    function swap(IPocketSwapRouter.SwapParams calldata params) external {
        router.swap(params);
    }
}
