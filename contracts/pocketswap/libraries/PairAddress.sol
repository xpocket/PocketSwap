// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Provides functions for deriving a pair address from the factory, tokens, and the fee
library PairAddress {
    bytes32 internal constant PAIR_INIT_CODE_HASH = 0xe28fa7bf5fb2d35a8f7e8c92c9a7ce8c68d700393825d6eb56728888754f488b;

    /// @notice Deterministically computes the pair address given the factory and PairKey
    /// @param factory The PocketSwap factory contract address
    /// @param tokenA The first token of a pair, unsorted
    /// @param tokenB The second token of a pair, unsorted
    /// @return pair The contract address of the pair
    function computeAddress(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);

        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex'ff',
                            factory,
                            keccak256(abi.encodePacked(tokenA, tokenB)),
                            PAIR_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }
}
