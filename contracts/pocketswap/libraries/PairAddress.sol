// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import '../interfaces/IPocketSwapFactory.sol';

/// @title Provides functions for deriving a pair address from the factory, tokens, and the fee
library PairAddress {
    /// @notice Deterministically computes the pair address given the factory and PairKey
    /// @param factory The PocketSwap factory contract address
    /// @param tokenA The first token of a pair, unsorted
    /// @param tokenB The second token of a pair, unsorted
    /// @return pair The contract address of the pair
    function computeAddress(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex'ff',
                            factory,
                            keccak256(abi.encodePacked(token0, token1)),
                            IPocketSwapFactory(factory).PAIR_INIT_CODE_HASH()
                        )
                    )
                )
            )
        );
    }
}
