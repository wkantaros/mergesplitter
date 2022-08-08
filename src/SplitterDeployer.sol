// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "../lib/solmate/src/tokens/ERC20.sol";
import {ERC20Promise} from "./ERC20Promise.sol";
import {ISplitterDeployer} from "./interfaces/ISplitterDeployer.sol";

contract SplitterDeployer is ISplitterDeployer {
    struct Parameters {
        address factory;
        address baseToken;
        bool isStakedPromise;
        uint8 decimals;
        string name;
        string symbol;
    }

    Parameters public override parameters;

    /// @dev Deploys token promises with the given parameters by transiently setting the parameters
    /// storage slot and then clearing it after deploying the tokens.
    /// @param factory The contract address of the Uniswap V3 factory
    /// @param baseToken The token we are creating promises for
    function deploy(address factory, address baseToken)
        internal
        returns (address tokenS, address tokenW)
    {
        string memory baseName = ERC20(baseToken).name();
        string memory baseSymbol = ERC20(baseToken).symbol();
        uint8 decimals = ERC20(baseToken).decimals();

        parameters = Parameters({
            factory: factory,
            baseToken: baseToken,
            isStakedPromise: true,
            decimals: decimals,
            name: string.concat(baseName, "S"),
            symbol: string.concat(baseSymbol, "S")
        });

        tokenS = address(
            new ERC20Promise{salt: keccak256(abi.encode(baseToken, true))}()
        );

        parameters = Parameters({
            factory: factory,
            baseToken: baseToken,
            isStakedPromise: false,
            decimals: decimals,
            name: string.concat(baseName, "W"),
            symbol: string.concat(baseSymbol, "W")
        });

        tokenW = address(
            new ERC20Promise{salt: keccak256(abi.encode(baseToken, false))}()
        );

        delete parameters;
    }
}
