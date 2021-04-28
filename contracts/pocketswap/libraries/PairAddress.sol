// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Provides functions for deriving a pair address from the factory, tokens, and the fee
library PairAddress {
    bytes32 internal constant PAIR_INIT_CODE_HASH = 0xccd9a5928307a79006651bee290ebecf5b5f3429cf6e692d8aeed239e6628a1c;

    /// @notice The identifying key of the pair
    struct PairKey {
        address token0;
        address token1;
    }

    /// @notice Returns PairKey: the ordered tokens with the matched fee levels
    /// @param tokenA The first token of a pair, unsorted
    /// @param tokenB The second token of a pair, unsorted
    /// @return PairKey The pair details with ordered token0 and token1 assignments
    function getPairKey(
        address tokenA,
        address tokenB
    ) internal pure returns (PairKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PairKey({token0: tokenA, token1: tokenB});
    }

    /// @notice Deterministically computes the pair address given the factory and PairKey
    /// @param factory The PocketSwap factory contract address
    /// @param tokenA The first token of a pair, unsorted
    /// @param tokenB The second token of a pair, unsorted
    /// @return pair The contract address of the pair
    function computeAddress(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);

        pair = address(
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
        );
    }

    function computeAddress(address factory, PairKey memory key) internal pure returns (address pair) {
        require(key.token0 < key.token1);
        pair = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex'ff',
                        factory,
                        keccak256(abi.encode(key.token0, key.token1)),
                        PAIR_INIT_CODE_HASH
                    )
                )
            )
        );
    }
}
