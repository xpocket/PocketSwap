// SPDX-License-Identifier: Unlicensed
pragma solidity =0.8.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import './libraries/Math.sol';
import './libraries/UQ112x112.sol';

import './PocketSwapERC20.sol';
import './interfaces/IPocketSwapFactory.sol';
import "./interfaces/IPocketSwapPair.sol";
import "./interfaces/callback/IPocketSwapCallback.sol";
import "./pair/StorageData.sol";
import "./libraries/PlainMath.sol";

contract PocketSwapPair is
PocketSwapERC20,
StorageData
{
    using PlainMath  for uint;
    using UQ112x112 for uint224;

    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));
    bytes4 private constant ASELECTOR = bytes4(keccak256(bytes('approve(address,uint256)')));

    uint112 private reserve0;           // uses single storage slot, accessible via getReserves
    uint112 private reserve1;           // uses single storage slot, accessible via getReserves
    uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint private unlocked = 1;

    modifier lock() {
        require(unlocked == 1, 'PocketSwap: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function getReserves() public override view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'PocketSwap: TRANSFER_FAILED');
    }

    function _safeApprove(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(ASELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'PocketSwap: APPROVE_FAILED');
    }

    constructor() {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1) external override {
        require(msg.sender == factory, 'PocketSwap: FORBIDDEN');
        // sufficient check
        token0 = _token0;
        token1 = _token1;
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 <= type(uint112).max && balance1 <= type(uint112).max, 'PocketSwap: OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2 ** 32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast;
        // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external override lock returns (uint liquidity) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        // gas savings
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        uint amount0 = balance0.sub(_reserve0);
        uint amount1 = balance1.sub(_reserve1);
        uint _totalSupply = totalSupply;

        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
            _mint(address(0), MINIMUM_LIQUIDITY);
            // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
        }
        require(liquidity > 0, 'PocketSwap: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);

        // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external override lock returns (uint amount0, uint amount1) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        // gas savings
        address _token0 = token0;
        // gas savings
        address _token1 = token1;
        // gas savings
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];
        uint _totalSupply = totalSupply;

        amount0 = liquidity.mul(balance0) / _totalSupply;
        // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(balance1) / _totalSupply;
        // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, 'PocketSwap: INSUFFICIENT_LIQUIDITY_BURNED');
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);

        // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external override lock {
        require(amount0Out > 0 || amount1Out > 0, 'PocketSwap: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'PocketSwap: INSUFFICIENT_LIQUIDITY');

        uint balance0;
        uint balance1;
        {// scope for _token{0,1}, avoids stack too deep errors
            address _token0 = token0;
            address _token1 = token1;
            require(to != _token0 && to != _token1, 'PocketSwap: INVALID_TO');
            // optimistically transfer tokens
            if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out);
            // optimistically transfer tokens
            if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out);

            balance0 = IERC20(_token0).balanceOf(address(this));
            balance1 = IERC20(_token1).balanceOf(address(this));
        }
        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'PocketSwap: INSUFFICIENT_INPUT_AMOUNT');
        {// scope for reserve{0,1}Adjusted, avoids stack too deep errors
            uint fee = IPocketSwapFactory(factory).fee();
            uint balance0Adjusted = balance0.mul(1e9).sub(amount0In.mul(fee));
            uint balance1Adjusted = balance1.mul(1e9).sub(amount1In.mul(fee));
            require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1e9 ** 2), "PocketSwap: K");
        }

        if (data.length > 0) {
            takePocketHoldersFee(amount0In, amount1In, amount0Out, amount1Out);
            balance0 = IERC20(token0).balanceOf(address(this));
            balance1 = IERC20(token1).balanceOf(address(this));
        }

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    function takePocketHoldersFee(uint amount0In, uint amount1In, uint amount0Out, uint amount1Out)
    private {
        address pocket = IPocketSwapFactory(factory).pocketAddress();

        if (isPocketToken()) {
            uint256 holdersFee = IPocketSwapFactory(factory).holdersFee();
            uint feeAmount = IERC20(pocket).balanceOf(address(this)) * holdersFee / 1e9;
            _safeTransfer(pocket, pocket, feeAmount);
            return;
        }

        (address pocketPair, address tokenToSwap, uint256 feeTokenAmount) =
            findPocketPair(amount0In, amount1In, amount0Out, amount1Out, pocket);
        _safeTransfer(tokenToSwap, pocketPair, feeTokenAmount);

        bool token0Pocket = pocket < tokenToSwap;
        uint feeAmount = getOutAmount(feeTokenAmount, pocketPair, token0Pocket);
        (uint amount0OutT, uint amount1OutT) = token0Pocket ? (feeAmount, uint(0)) : (uint(0), feeAmount);
        IPocketSwapPair(pocketPair).swap(amount0OutT, amount1OutT, address(this), "");

        feeAmount = IERC20(pocket).balanceOf(address(this));
        _safeTransfer(pocket, pocket, feeAmount);

        emit PocketHoldersFeeTaken(feeAmount);
    }

    function getOutAmount(uint amountIn, address pocketPair, bool token0Pocket)
    private view returns (uint amountOut) {
        uint fee = IPocketSwapFactory(factory).fee();
        (uint _reserve0, uint _reserve1,) = IPocketSwapPair(pocketPair).getReserves();
        (uint reserveIn, uint reserveOut) = token0Pocket ? (_reserve1, _reserve0) : (_reserve0, _reserve1);

        uint amountInWithFee = amountIn.mul(1e9 - fee);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1e9).add(amountInWithFee);

        amountOut = numerator / denominator;
    }

    function findPocketPair(uint amount0In, uint amount1In, uint amount0Out, uint amount1Out, address pocket) private view
    returns (address pocketPair, address tokenToSwap, uint256 feeAmount) {
        tokenToSwap = token0;
        pocketPair = IPocketSwapFactory(factory).getPair(tokenToSwap, pocket);
        uint amountToFee;

        if (pocketPair != address(0)) {
            amountToFee = amount0In > amount0Out ? amount0In : amount0Out;
        } else {
            tokenToSwap = token1;
            pocketPair = IPocketSwapFactory(factory).getPair(tokenToSwap, pocket);
            amountToFee = amount1In > amount1Out ? amount1In : amount1Out;

            if (pocketPair == address(0)) {
                revert("No POCKET pair");
            }
        }

        uint256 holdersFee = IPocketSwapFactory(factory).holdersFee();
        feeAmount = amountToFee * holdersFee / 1e9;
    }

    function isPocketToken() private view returns (bool) {
        address pocket = IPocketSwapFactory(factory).pocketAddress();
        return token0 == pocket || token1 == pocket;
    }

    // force balances to match reserves
    function skim(address to) external override lock {
        address _token0 = token0;
        // gas savings
        address _token1 = token1;
        // gas savings
        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)).sub(reserve0));
        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)).sub(reserve1));
    }

    // force reserves to match balances
    function sync() external override lock {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);
    }
}
