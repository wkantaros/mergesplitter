// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {SafeTransferLib} from "../lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "../lib/solmate/src/tokens/ERC20.sol";
import {SplitterDeployer} from "./SplitterDeployer.sol";
import {ERC20Promise} from "./ERC20Promise.sol";
import {IERC20Promise} from "./interfaces/IERC20Promise.sol";
import {ISplitter} from "./interfaces/ISplitter.sol";

contract Splitter is ISplitter, SplitterDeployer {
    mapping(address => address) public override getPosPromise;
    mapping(address => address) public override getPowPromise;

    // No need to check merge state in createSplit imo
    function createSplit(address baseToken)
        external
        returns (address posPromise, address powPromise)
    {
        require(getPowPromise[baseToken] == address(0), "Split exists");
        (posPromise, powPromise) = deploy(address(this), baseToken);
        getPosPromise[baseToken] = posPromise;
        getPowPromise[baseToken] = powPromise;
        emit SplitterCreated(baseToken, posPromise, powPromise);
    }

    enum MergeState {
        Before,
        AfterPoW,
        AfterPoS
    }

    // mint transfers underlying from msg.sender and mints them 1 or 2 promise tokens
    // Mints 1 XXXW and 1 XXXS if pre-merge
    // Mints 1 XXXS if on post-merge PoS
    // Mints 1 XXXW if on post-merge PoW
    //
    // TODO(maybe): Add some mechanism to force value of XXXW / XXXS on PoS / PoW post-merge to zero.
    //  This solves the "double airdrop" problem. Traditional infinite mint is the obvious solution.
    //  But then there is an issue with overflowing the "totalSupply" of the ERC20Promise
    function mint(address baseToken, uint256 amount) external {
        // Transfer underlying
        SafeTransferLib.safeTransferFrom(
            ERC20(baseToken), msg.sender, address(this), amount
        );

        MergeState currentMergeState = mergeState();

        if (currentMergeState == MergeState.Before) {
            address posPromise = getPosPromise[baseToken];
            require(posPromise != address(0), "Must call createSplit");
            address powPromise = getPowPromise[baseToken];

            // Mint PoW and PoS promises
            IERC20Promise(posPromise).mint(msg.sender, amount);
            IERC20Promise(powPromise).mint(msg.sender, amount);
        } else if (currentMergeState == MergeState.AfterPoS) {
            address posPromise = getPosPromise[baseToken];
            require(posPromise != address(0), "Must call createSplit");

            // Mint only PoS promise
            IERC20Promise(posPromise).mint(msg.sender, amount);
        } else {
            address posPromise = getPosPromise[baseToken];
            require(posPromise != address(0), "Must call createSplit");

            // Mint only PoW promise
            IERC20Promise(powPromise).mint(msg.sender, amount);
        }

        emit TokenSplit(baseToken, amount);
    }

    // burn burns 1 or 2 promise tokens and transfers the underlying to msg.sender
    // Burns 1 XXXW and 1 XXXS if pre-merge
    // Burns 1 XXXS if on post-merge PoS
    // Burns 1 XXXW if on post-merge PoW
    //
    // targetState enforces a deadline and prevents replay attacks
    // in case Post-merge PoW changes chain ID but not network ID
    function burn(address baseToken, uint256 amount, MergeState targetState) external {
        MergeState currentMergeState = mergeState();
        require(currentMergeState == targetState, "Incorrect merge state");

        // Optimistically transfer underlying
        SafeTransferLib.safeTransfer(ERC20(baseToken), msg.sender, amount);

        if (currentMergeState == MergeState.Before) {
            address posPromise = getPosPromise[baseToken];
            require(posPromise != address(0), "Must call createSplit");
            address powPromise = getPowPromise[baseToken];

            // Before merge, burn both PoW and PoS promises
            IERC20Promise(posPromise).burn(msg.sender, amount);
            IERC20Promise(powPromise).burn(msg.sender, amount);
        } else if (currentMergeState == MergeState.AfterPoS) {
            address posPromise = getPosPromise[baseToken];
            require(posPromise != address(0), "Must call createSplit");

            IERC20Promise(posPromise).burn(msg.sender, amount);
        } else {
            address powPromise = getPowPromise[baseToken];
            require(powPromise != address(0), "Must call createSplit");
            IERC20Promise(powPromise).burn(msg.sender, amount);
        }

        emit TokenMerged(baseToken, amount);
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

    // TODO: A more general heuristic would be ideal.
    //   Generalizing to the case where the difficulty bomb may or may not be defused
    //   and the chain ID may or may not change.
    //   Ideally, generalizing to _any_ PoW chain that is operating post-merge.
    //   This seems to be a nontrivial problem.
    function haveWeMergedYetPoW() internal view returns (bool) {
        return block.chainid != 1;
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
