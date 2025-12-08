// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";

/// @title HookUtils
/// @notice Utility functions for Uniswap v4 hook operations
library HookUtils {
    using PoolIdLibrary for PoolKey;

    /// @notice Get the pool ID from a pool key
    /// @param key The pool key
    /// @return id The pool ID
    function getPoolId(PoolKey memory key) internal pure returns (PoolId id) {
        return key.toId();
    }

    /// @notice Check if a currency is ETH (native token)
    /// @param currency The currency to check
    /// @return isNative True if the currency is ETH
    function isNative(Currency currency) internal pure returns (bool isNative) {
        return Currency.unwrap(currency) == address(0);
    }

    /// @notice Get the underlying address of a currency
    /// @param currency The currency
    /// @return addr The underlying token address (address(0) for ETH)
    function toAddress(Currency currency) internal pure returns (address addr) {
        return Currency.unwrap(currency);
    }

    /// @notice Create a currency from an address
    /// @param addr The token address
    /// @return currency The currency
    function toCurrency(address addr) internal pure returns (Currency currency) {
        return Currency.wrap(addr);
    }

    /// @notice Get both token addresses from a pool key
    /// @param key The pool key
    /// @return token0 Address of token0
    /// @return token1 Address of token1
    function getTokenAddresses(
        PoolKey memory key
    ) internal pure returns (address token0, address token1) {
        token0 = Currency.unwrap(key.currency0);
        token1 = Currency.unwrap(key.currency1);
    }

    /// @notice Check if a pool uses a specific token
    /// @param key The pool key
    /// @param token The token address to check
    /// @return hasToken True if the pool contains the token
    function poolContainsToken(
        PoolKey memory key,
        address token
    ) internal pure returns (bool hasToken) {
        return Currency.unwrap(key.currency0) == token || 
               Currency.unwrap(key.currency1) == token;
    }

    /// @notice Get the "other" token in a pool given one token
    /// @param key The pool key
    /// @param token One of the tokens in the pool
    /// @return other The other token in the pool
    function getOtherToken(
        PoolKey memory key,
        address token
    ) internal pure returns (address other) {
        address token0 = Currency.unwrap(key.currency0);
        address token1 = Currency.unwrap(key.currency1);
        
        if (token == token0) return token1;
        if (token == token1) return token0;
        
        revert("Token not in pool");
    }

    /// @notice Check if pool key is valid
    /// @param key The pool key to validate
    /// @return isValid True if the key is valid
    function isValidPoolKey(PoolKey memory key) internal pure returns (bool isValid) {
        // currency0 should be "less than" currency1
        return Currency.unwrap(key.currency0) < Currency.unwrap(key.currency1);
    }

    /// @notice Sort currencies to create valid pool key ordering
    /// @param currencyA First currency
    /// @param currencyB Second currency
    /// @return currency0 Lower currency (token0)
    /// @return currency1 Higher currency (token1)
    function sortCurrencies(
        Currency currencyA,
        Currency currencyB
    ) internal pure returns (Currency currency0, Currency currency1) {
        if (Currency.unwrap(currencyA) < Currency.unwrap(currencyB)) {
            return (currencyA, currencyB);
        }
        return (currencyB, currencyA);
    }

    /// @notice Calculate the sqrt price for a given price ratio
    /// @param price The price (token1/token0) scaled by 1e18
    /// @return sqrtPriceX96 The sqrt price in Q96 format
    function priceToSqrtPriceX96(uint256 price) internal pure returns (uint160 sqrtPriceX96) {
        // sqrtPrice = sqrt(price) * 2^96
        // price is in 1e18, so sqrt(price) is in 1e9
        // sqrtPriceX96 = sqrt(price * 1e18) * 2^96 / 1e9
        uint256 sqrtPrice = sqrt(price);
        return uint160((sqrtPrice << 96) / 1e9);
    }

    /// @notice Babylonian square root
    /// @param x Value to take sqrt of
    /// @return y Square root of x
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        if (x == 0) return 0;
        
        uint256 z = (x + 1) / 2;
        y = x;
        
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}
