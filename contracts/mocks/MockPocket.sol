// SPDX-License-Identifier: Unlicensed
pragma solidity =0.8.4;

import '../Pocket.sol';

contract MockPocket is Pocket("Pocket", "POCKET", 100500) {
    function mint(address to, uint value) external {
        _mint(to, value);
    }

    function burn(address from, uint value) external {
        _burn(from, value);
    }
}