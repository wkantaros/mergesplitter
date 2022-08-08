// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ISplitter {
    event SplitterCreated(
        address indexed baseToken, address posPromise, address powPromise
    );

    event TokenSplit(address indexed baseToken, uint256 amount);

    event TokenMerged(address indexed baseToken, uint256 amount);

    function getS(address baseToken) external view returns (address sPromise);
    function getW(address baseToken) external view returns (address wPromise);
}
