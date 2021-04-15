// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.6.12;

import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract MockERC20 is ERC20 {
    using SafeMath for uint;

    constructor() ERC20("ERC20", "ERC20") {}

    function mint(address to, uint value) external {
        _mint(to, value);
    }

    function burn(address from, uint value) external {
        _burn(from, value);
    }
}