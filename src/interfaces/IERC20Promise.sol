// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IERC20Promise {
    function factory() external view returns (address);
    function baseToken() external view returns (address);
    function isStakedPromise() external view returns (bool);
    function mint(address to, uint256 value) external;
    function burn(address from, uint256 value) external;
}
