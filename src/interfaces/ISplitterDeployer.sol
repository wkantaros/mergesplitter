// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ISplitterDeployer {
    /// @notice Get the parameters to be used in constructing token promises,
    /// set transiently during promise token creation.
    /// @dev Called by the ERC20Promise constructor to fetch the parameters of the promise token
    /// Returns factory The factory address
    /// Returns baseToken The underlying token address
    /// Returns isStakedPromise True if this is a PoS promise, false if PoW
    /// Returns decimals The decimals of the promise token
    /// Returns name The name of the promise token
    /// Returns symbol The symbol of the promise token
    function parameters()
        external
        view
        returns (
            address factory,
            address baseToken,
            bool isStakedPromise,
            uint8 decimals,
            string memory name,
            string memory symbol
        );
}
