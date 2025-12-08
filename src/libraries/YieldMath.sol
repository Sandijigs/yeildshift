// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title YieldMath
/// @notice Library for APY calculations and yield-related math
library YieldMath {
    uint256 internal constant WAD = 1e18;
    uint256 internal constant RAY = 1e27;
    uint256 internal constant BPS = 10000;
    uint256 internal constant SECONDS_PER_YEAR = 365 days;

    /// @notice Convert ray (1e27) to basis points (1e4)
    /// @param ray Value in ray precision
    /// @return bps Value in basis points
    function rayToBps(uint256 ray) internal pure returns (uint256 bps) {
        return ray / 1e23;
    }

    /// @notice Convert wad (1e18) to basis points (1e4)
    /// @param wad Value in wad precision
    /// @return bps Value in basis points
    function wadToBps(uint256 wad) internal pure returns (uint256 bps) {
        return wad / 1e14;
    }

    /// @notice Convert basis points to wad
    /// @param bps Value in basis points
    /// @return wad Value in wad precision
    function bpsToWad(uint256 bps) internal pure returns (uint256 wad) {
        return bps * 1e14;
    }

    /// @notice Convert per-second rate to annual APY (in basis points)
    /// @param ratePerSecond Rate per second in wad precision
    /// @return apy Annual APY in basis points
    function rateToAPY(uint256 ratePerSecond) internal pure returns (uint256 apy) {
        // Simple linear approximation: APY ≈ rate * seconds_per_year
        // For small rates, this is accurate enough
        return (ratePerSecond * SECONDS_PER_YEAR) / 1e14;
    }

    /// @notice Calculate risk-adjusted APY score
    /// @param apy APY in basis points
    /// @param riskScore Risk score 1-10 (1 = safest)
    /// @return score Risk-adjusted score (higher is better)
    function calculateRiskAdjustedScore(
        uint256 apy,
        uint256 riskScore
    ) internal pure returns (uint256 score) {
        require(riskScore >= 1 && riskScore <= 10, "Invalid risk score");
        // Invert risk score: 10 becomes 1, 1 becomes 10
        uint256 riskWeight = 11 - riskScore;
        return (apy * riskWeight) / 10;
    }

    /// @notice Clamp APY within reasonable bounds
    /// @param apy APY to clamp
    /// @param minAPY Minimum APY (in basis points)
    /// @param maxAPY Maximum APY (in basis points)
    /// @return clamped Clamped APY
    function clampAPY(
        uint256 apy,
        uint256 minAPY,
        uint256 maxAPY
    ) internal pure returns (uint256 clamped) {
        if (apy < minAPY) return minAPY;
        if (apy > maxAPY) return maxAPY;
        return apy;
    }

    /// @notice Calculate amount to shift based on percentage
    /// @param totalAmount Total available amount
    /// @param percentage Percentage to shift (0-100)
    /// @return shiftAmount Amount to shift
    function calculateShiftAmount(
        uint256 totalAmount,
        uint256 percentage
    ) internal pure returns (uint256 shiftAmount) {
        require(percentage <= 100, "Percentage exceeds 100");
        return (totalAmount * percentage) / 100;
    }

    /// @notice Calculate extra yield earned compared to base yield
    /// @param principal Principal amount
    /// @param baseAPY Base APY in basis points
    /// @param actualAPY Actual APY achieved in basis points
    /// @param timeElapsed Time elapsed in seconds
    /// @return extraYield Extra yield earned
    function calculateExtraYield(
        uint256 principal,
        uint256 baseAPY,
        uint256 actualAPY,
        uint256 timeElapsed
    ) internal pure returns (uint256 extraYield) {
        if (actualAPY <= baseAPY) return 0;
        uint256 extraAPY = actualAPY - baseAPY;
        // extraYield = principal * (extraAPY / BPS) * (timeElapsed / SECONDS_PER_YEAR)
        return (principal * extraAPY * timeElapsed) / (BPS * SECONDS_PER_YEAR);
    }

    /// @notice Safe multiplication with overflow check
    /// @param a First operand
    /// @param b Second operand
    /// @return c Result
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) return 0;
        c = a * b;
        require(c / a == b, "Multiplication overflow");
        return c;
    }

    /// @notice Safe division with zero check
    /// @param a Numerator
    /// @param b Denominator
    /// @return c Result
    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0, "Division by zero");
        return a / b;
    }
}
