// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Provides functions for deriving a pair address from the factory, tokens, and the fee
library PairAddress {
    bytes32 internal constant PAIR_INIT_CODE_HASH = 0x6052f97ae694c9b6af9ccaeee836a290900b9953c84efc9d02ff1e46cbd50e38;

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
