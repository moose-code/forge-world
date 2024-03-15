// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract ForgeWorld {
    // Global game state
    uint256 public epoch;
    mapping(uint256 => uint256) woodEmission;
    mapping(uint256 => uint256) copperEmission;
    mapping(uint256 => uint256) ironEmission;

    // Cumulative amount.
    mapping(uint256 => uint256) cumulativeWoodPerUser;
    mapping(uint256 => uint256) cumulativeCopperPerUser;
    mapping(uint256 => uint256) cumulativeIronPerUser;

    // User state
    mapping(address => uint256) userCurrentWorld;
    mapping(address => uint256) userLastEpochClaimed;
    //
}
