// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {SafeTransferLib} from "../lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "../lib/solmate/src/tokens/ERC20.sol";
import {SplitterDeployer} from "./SplitterDeployer.sol";
import {ERC20Promise} from "./ERC20Promise.sol";
import {IERC20Promise} from "./interfaces/IERC20Promise.sol";
import {ISplitter} from "./interfaces/ISplitter.sol";

contract Splitter is ISplitter, SplitterDeployer {
    mapping(address => address) public override getS;
    mapping(address => address) public override getW;

    // No need to check merge state in createSplit imo
    function createSplit(address token)
        external
        returns (address tokenS, address tokenW)
    {
        // TODO: why does UniswapV3Factory.createPool use noDelegateCall?
        require(getW[token] == address(0));
        (tokenS, tokenW) = deploy(address(this), token);
        getS[token] = tokenS;
        getW[token] = tokenW;
        emit SplitterCreated(token, tokenS, tokenW);
    }

    enum MergeState {
        Before,
        AfterPoW,
        AfterPoS
    }

    // mint mints a promise token
    function mint(address baseToken, uint256 amount) external {
        // TODO: Do we want to allow minting post merge? Probably imo for "arbitrage" reasons
        //  But we should then only mint the correct promise token, not both.
        require(mergeState() == MergeState.Before, "Must be before merge");

        address sPromise = getS[baseToken];
        require(sPromise != address(0), "Must call createSplit");
        address wPromise = getW[baseToken];

        // Transfer underlying
        SafeTransferLib.safeTransferFrom(
            ERC20(baseToken), msg.sender, address(this), amount
        );

        // Mint PoW and PoS promises
        IERC20Promise(sPromise).mint(msg.sender, amount);
        IERC20Promise(wPromise).mint(msg.sender, amount);
    }

    // burn burns promise tokens and transfers the underlying to msg.sender
    function burn(address baseToken, uint256 amount, MergeState _ms) external {
        MergeState currentMergeState = mergeState();
        require(currentMergeState == _ms, "Incorrect merge state");

        // Optimistically transfer underlying
        SafeTransferLib.safeTransfer(ERC20(baseToken), msg.sender, amount);

        // Burn promise token
        if (currentMergeState == MergeState.Before) {
            address sPromise = getS[baseToken];
            require(sPromise != address(0), "Must call createSplit");
            address wPromise = getW[baseToken];

            // Before merge, burn both PoW and PoS promises
            IERC20Promise(sPromise).burn(msg.sender, amount);
            IERC20Promise(wPromise).burn(msg.sender, amount);
        } else if (currentMergeState == MergeState.AfterPoS) {
            address sPromise = getS[baseToken];
            require(sPromise != address(0), "Must call createSplit");

            IERC20Promise(sPromise).burn(msg.sender, amount);
        } else {
            address wPromise = getW[baseToken];
            require(wPromise != address(0), "Must call createSplit");
            IERC20Promise(wPromise).burn(msg.sender, amount);
        }
    }

    /**
     * @notice Determine whether we're running in Proof of Work or Proof of Stake
     * @dev Post-merge, the DIFFICULTY opcode gets renamed to PREVRANDAO,
     * and stores the prevRandao field from the beacon chain state if EIP-4399 is finalized.
     * If not the difficulty must be be 0 according to EIP-3675, so both possibilities are checked here.
     */
    function haveWeMergedYetPoS() internal view returns (bool) {
        return block.difficulty > 2 ** 64 || block.difficulty == 0;
    }

    function haveWeMergedYetPoW() internal view returns (bool) {
        // TODO
        return false;
    }

    function mergeState() internal view returns (MergeState) {
        if (haveWeMergedYetPoS()) {
            return MergeState.AfterPoS;
        } else if (haveWeMergedYetPoW()) {
            return MergeState.AfterPoW;
        } else {
            return MergeState.Before;
        }
    }
}
