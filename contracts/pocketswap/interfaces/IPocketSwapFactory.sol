// SPDX-License-Identifier: Unlicensed
pragma solidity =0.8.4;

interface IPocketSwapFactory {
    event FeeUpdated(uint256 oldFee, uint256 newFee);
    event FeeSetterUpdated(address oldFeeSetter, address newFeeSetter);

    function fee() external view returns (uint256);

    function holdersFee() external view returns (uint256);

    function pocketAddress() external view returns (address);

    function setFee(uint256) external;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeSetter(address) external;

    function PAIR_INIT_CODE_HASH() external pure returns(bytes32);
}
