// SPDX-License-Identifier: Unlicensed
pragma solidity =0.8.4;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./pocketswap/interfaces/IPocket.sol";

contract Pocket is IPocket, ERC20, Ownable {
    mapping(address => bool) public override rewardsExcluded;
    mapping(address => uint256) lastTotalDividends;
    uint256 public override rewardsPerHolding;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 supply_
    ) ERC20(name_, symbol_) {
        _mint(msg.sender, supply_);
    }

    function _calcRewards(address account) internal view virtual returns (uint256) {
        if (account == address(this) || rewardsExcluded[account]) {
            return 0;
        }

        uint256 _balance = ERC20.balanceOf(account);
        uint256 _dividends = ERC20.balanceOf(address(this));

        return (_balance * (_dividends - lastTotalDividends[account])) / totalSupply();
    }

    modifier _distribute(address account) {
        lastTotalDividends[account] = ERC20.balanceOf(address(this));
        uint256 rewards = _calcRewards(account);
        ERC20._transfer(address(this), account, rewards);
        _;
    }

    function excludeFromRewards(address account) _distribute(account) external onlyOwner {
        rewardsExcluded[account] = true;
    }

    function includeInRewards(address account) _distribute(account) external onlyOwner {
        delete rewardsExcluded[account];
    }

    function addRewards(uint256 amount) override external returns (bool) {
        return transfer(address(this), amount);
    }

    /**
     * @dev See {ERC20-_transfer}.
     */
    function _transfer(address sender, address recipient, uint256 amount) _distribute(sender)
    internal virtual override {
        super._transfer(sender, recipient, amount);
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return ERC20.balanceOf(account) + _calcRewards(account);
    }
}
