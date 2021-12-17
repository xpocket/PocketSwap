// SPDX-License-Identifier: Unlicensed
pragma solidity =0.8.4;


import './PocketSwapPair.sol';
import './interfaces/IPocketSwapFactory.sol';
import './libraries/PairAddress.sol';

contract PocketSwapFactory is IPocketSwapFactory {
    address public override feeSetter;
    uint256 public override fee = 3e6; // 1e9 = 100%; 1e8 = 10%; 1e7 = 1%; 1e6 = 0.1% ....

    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;

    constructor() {
        feeSetter = msg.sender;
    }

    function PAIR_INIT_CODE_HASH() external override pure returns (bytes32) {
        return keccak256(abi.encodePacked(type(PocketSwapPair).creationCode));
    }

    function allPairsLength() external override view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external override returns (address pair) {
        require(tokenA != tokenB, 'PocketSwap:IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'PocketSwap:ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'PocketSwap:PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(PocketSwapPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        PocketSwapPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);

        require(pair == PairAddress.computeAddress(address(this), token0, token1), "WWZ");
        require(pair == PairAddress.computeAddress(address(this), token1, token0), "WWZ");

        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFee(uint256 _fee) external override {
        require(msg.sender == feeSetter, 'PocketSwap:FORBIDDEN');
        require(_fee < 1e18, 'PocketSwap:BIG_FEE');
        fee = _fee;
    }

    function setFeeSetter(address _feeSetter) external override {
        require(msg.sender == feeSetter, 'PocketSwap:FORBIDDEN');
        feeSetter = _feeSetter;
    }

    function holdersFee() external view override returns(uint256) {
        return fee * 5 / 30; // POCKET holders are getting 5/30 of the fees
    }
}
