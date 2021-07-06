// SPDX-License-Identifier: Unlicensed
pragma solidity =0.8.4;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./pocketswap/interfaces/IPocket.sol";

contract Pocket is IPocket, ERC20("XPocket", "POCKET"), Ownable {
    mapping(address => bool) public override rewardsExcluded;
    mapping(address => uint256) public lastTotalDividends;
    uint256 public rewardsIncludedSupply;

    constructor() {
        _mint(msg.sender, 50e6 ether);
        rewardsIncludedSupply = totalSupply();
        rewardsExcluded[address(this)] = true;
    }

    function _calcRewards(address account) internal view virtual returns (uint256) {
        if (account == address(this) || rewardsExcluded[account]) {
            return 0;
        }

        uint256 _balance = ERC20.balanceOf(account);
        uint256 _dividends = ERC20.balanceOf(address(this));

        return (_balance * (_dividends - lastTotalDividends[account])) / rewardsIncludedSupply;
    }

    modifier _distribute(address account) {
        lastTotalDividends[account] = ERC20.balanceOf(address(this));
        uint256 rewards = _calcRewards(account);
        ERC20._transfer(address(this), account, rewards);
        _;
    }

    modifier _notExcluded(address account) {
        require(!rewardsExcluded[account], "Pocket: Already excluded from rewards");
        _;
    }

    modifier _excluded(address account) {
        require(rewardsExcluded[account], "Pocket: Not excluded from rewards");
        _;
    }

    function excludeFromRewards(address account)
    _notExcluded(account)
    _distribute(account)
    external onlyOwner {
        rewardsExcluded[account] = true;
        rewardsIncludedSupply -= ERC20.balanceOf(account);
    }

    function includeInRewards(address account)
    _excluded(account)
    _distribute(account)
    external onlyOwner {
        delete rewardsExcluded[account];
        rewardsIncludedSupply += ERC20.balanceOf(account);
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
        if (rewardsExcluded[sender] && !rewardsExcluded[recipient]) {
            rewardsIncludedSupply += amount;
        } else if (!rewardsExcluded[sender] && rewardsExcluded[recipient]) {
            rewardsIncludedSupply -= amount;
        }
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return ERC20.balanceOf(account) + _calcRewards(account);
    }
}
