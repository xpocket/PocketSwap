// SPDX-License-Identifier: Unlicensed
pragma solidity =0.8.4;

import "../interfaces/IPocketSwapPair.sol";

abstract contract StorageData is IPocketSwapPair {
    uint public constant override MINIMUM_LIQUIDITY = 1e3;

    address public override factory;
    address public override token0;
    address public override token1;

    uint public override price0CumulativeLast;
    uint public override price1CumulativeLast;
}
