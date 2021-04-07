// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.6.12;

interface IPocketSwapFactory {
    function fee() external view returns (uint256);
    function setFee(uint256) external;
}
