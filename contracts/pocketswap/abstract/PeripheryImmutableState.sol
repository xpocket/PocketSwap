// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.12;

import '../interfaces/IPeripheryImmutableState.sol';

/// @title Immutable state
/// @notice Immutable state used by periphery contracts
abstract contract PeripheryImmutableState is IPeripheryImmutableState {
    /// @inheritdoc IPeripheryImmutableState
    address public immutable override factory;
    /// @inheritdoc IPeripheryImmutableState
    address public immutable override WETH9;
    /// @inheritdoc IPeripheryImmutableState
    address public immutable override pocket;

    constructor(address _factory, address _WETH9, address _pocketToken) {
        factory = _factory;
        WETH9 = _WETH9;
        pocket = _pocketToken;
    }
}
