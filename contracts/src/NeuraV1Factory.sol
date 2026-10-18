// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {NeuraV1Pool} from "./NeuraV1Pool.sol";

/// @title Neura V1 Factory
/// @notice Permissionless pool creation. One pool per (pair, curve, fee tier).
///         Fee tiers are fixed at deploy time — governance cannot change the fee
///         of a pool after it exists.
/// @dev    UNAUDITED. Not deployed.
contract NeuraV1Factory {
    struct Parameters { address token0; address token1; bool stable; uint24 baseFee; uint24 surgeFee; }

    /// fee tier (pips) => enabled / surge fee (pips)
    mapping(uint24 => bool) public feeEnabled;
    mapping(uint24 => uint24) public surgeForFee;
    mapping(bytes32 => address) internal pools;
    address[] public allPools;
    Parameters public parameters;
    bool private creating;

    event PoolCreated(address indexed token0, address indexed token1, bool stable, uint24 baseFee, address pool, uint256 index);

    constructor() {
        _enable(100, 400);       // 0.01% stable tier, +0.04% surge
        _enable(500, 1_000);     // 0.05%, +0.10% surge
        _enable(3_000, 2_500);   // 0.30%, +0.25% surge
        _enable(10_000, 0);      // 1.00% exotic tier (already at the 1% cap)
    }

    function _enable(uint24 fee, uint24 surge) private {
        feeEnabled[fee] = true;
        surgeForFee[fee] = surge;
    }

    function _key(address a, address b, bool stable, uint24 fee) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(a, b, stable, fee));
    }

    function getPool(address tokenA, address tokenB, bool stable, uint24 fee) external view returns (address) {
        (address t0, address t1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        return pools[_key(t0, t1, stable, fee)];
    }

    function allPoolsLength() external view returns (uint256) {
        return allPools.length;
    }

    function createPool(address tokenA, address tokenB, bool stable, uint24 fee) external returns (address pool) {
        require(!creating, "creating");
        creating = true;
        require(tokenA != tokenB, "identical");
        (address t0, address t1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(t0 != address(0), "zero");
        require(t0.code.length > 0 && t1.code.length > 0, "token code");
        require(feeEnabled[fee], "fee tier");
        uint24 surge = surgeForFee[fee];
        bytes32 key = _key(t0, t1, stable, fee);
        require(pools[key] == address(0), "exists");

        parameters = Parameters(t0, t1, stable, fee, surge);
        pool = address(new NeuraV1Pool{salt: key}()); // CREATE2: address is predictable
        delete parameters;

        pools[key] = pool;
        allPools.push(pool);
        creating = false;
        emit PoolCreated(t0, t1, stable, fee, pool, allPools.length - 1);
    }
}
