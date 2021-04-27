// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.12;

import "../interfaces/IPocketSwapPair.sol";
import "./PairAddress.sol";

/// @notice Provides validation for callbacks from PocketSwap Pairs
library CallbackValidation {
    /// @notice Returns the address of a valid PocketSwap Pair
    /// @param factory The contract address of the PocketSwap factory
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @return pair The pair contract address
    function verifyCallback(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (IPocketSwapPair pair) {
        pair = IPocketSwapPair(PairAddress.computeAddress(factory, tokenA, tokenB));
        require(msg.sender == address(pair));
    }
}