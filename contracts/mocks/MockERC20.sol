// SPDX-License-Identifier: Unlicensed
pragma solidity =0.8.4;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract MockERC20 is ERC20 {
    constructor() ERC20("ERC20", "ERC20") {}

    function mint(address to, uint value) external {
        _mint(to, value);
    }

    function burn(address from, uint value) external {
        _burn(from, value);
    }
}