// SPDX-License-Identifier: Unlicensed
pragma solidity =0.8.4;

interface IPocket {
    function addRewards(uint256 amount) external returns (bool);
    function rewardsExcluded(address) external view returns(bool);
}
