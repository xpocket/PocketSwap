// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.6.12;

import "../interfaces/IPocketSwapPair.sol";

abstract contract StorageData is IPocketSwapPair {
    uint public override constant MINIMUM_LIQUIDITY = 1e3;

    address public override factory;
    address public override token0;
    address public override token1;

    uint public override price0CumulativeLast;
    uint public override price1CumulativeLast;
    uint public override kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event
}
