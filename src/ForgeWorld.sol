// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import "./ResourceToken.sol";
import {console} from "forge-std/Script.sol";

contract ForgeWorld {
    // Global game state
    uint256 public epoch;
    uint256 public lastEpochTimestamp;
    uint256 public worldCounter;

    // Cumulative collection mapping for user awarded emissions.
    // epoch => resource => amount
    mapping(uint256 => mapping(address => uint256))
        public cumulativeResourceCollectedPerEpoch;

    // User state
    mapping(address => uint256) public userCurrentWorld;
    mapping(address => uint256) public userLastEpochClaimed;

    // World mappings
    mapping(uint256 => address) public worldToTokenResource;
    mapping(uint256 => uint256) public worldPopulation;
    // World to token rate, etc etc.

    // Resources
    address public woodToken;
    address public copperToken;
    address public ironToken;

    uint256[] public worlds;

    modifier tryIncreaseEpoch() {
        increaseEpoch();
        _;
    }

    modifier requireUserExists(address user) {
        require(userCurrentWorld[user] != 0, "User does not exist");
        _;
    }

    modifier validateWorld(uint256 world) {
        require(world != 0, "Cannot join the 0 start world");
        require(world <= worldCounter, "World does not exist.");
        _;
    }

    constructor() {
        console.log("somethings happening");

        _deployWorld("Wood Token", "WOOD");
        _deployWorld("Copper Token", "COPPER");
        _deployWorld("Iron Token", "IRON");

        lastEpochTimestamp = block.timestamp;
        // Adjust lastEpochTimestamp to the start of the current hour
        lastEpochTimestamp -= lastEpochTimestamp % 3600;

        // start at epoch 1
        epoch++;
    }

    function _deployWorld(string memory name, string memory symbol) internal {
        worldCounter++;

        address token = address(new ResourceToken(name, symbol));
        worldToTokenResource[worldCounter] = token;
        worlds.push(worldCounter);
    }

    function userJoinWorld(
        uint256 world
    ) public tryIncreaseEpoch validateWorld(world) {
        require(userCurrentWorld[msg.sender] == 0, "User already joined");
        console.log("somethings happening");

        userCurrentWorld[msg.sender] = world;
        worldPopulation[world]++;
        userLastEpochClaimed[msg.sender] = epoch;
    }

    // function to move worlds. Moving worlds will forfeit all resources you are collecting this epoch
    function userMoveWorld(uint256 world) public validateWorld(world) {
        userClaimRewards(); // this function also checks user already exists

        // Could impose cost on user for moving worlds.
        uint256 currentWorld = userCurrentWorld[msg.sender];
        worldPopulation[currentWorld]--;

        userCurrentWorld[msg.sender] = world;
        worldPopulation[world]++;
        userLastEpochClaimed[msg.sender] = epoch;
    }

    function userClaimRewards()
        public
        tryIncreaseEpoch
        requireUserExists(msg.sender)
    {
        uint256 lastEpochClaimed = userLastEpochClaimed[msg.sender];
        if (lastEpochClaimed < epoch) {
            address resourceAddress = worldToTokenResource[
                userCurrentWorld[msg.sender]
            ];

            uint256 reward = cumulativeResourceCollectedPerEpoch[epoch][
                resourceAddress
            ] -
                cumulativeResourceCollectedPerEpoch[lastEpochClaimed][
                    resourceAddress
                ];

            _mintToken(resourceAddress, msg.sender, reward);

            userLastEpochClaimed[msg.sender] = epoch;
        }
    }

    function increaseEpoch() public {
        // Use simple gelato cron job to make sure this is called every hour.
        if (block.timestamp >= lastEpochTimestamp + 3600) {
            lastEpochTimestamp = block.timestamp;
            lastEpochTimestamp -= lastEpochTimestamp % 3600; // quantize to the start of the hour

            uint256 incrementAmount = 10000e18; // 10k tokens mined per resource per world.

            epoch++;

            for (uint i = 0; i < worlds.length; i++) {
                uint256 world = worlds[i];

                address resourceAddress = worldToTokenResource[world];
                uint256 population = worldPopulation[world];
                if (population == 0) {
                    population = 1; // avoid division by 0
                }

                cumulativeResourceCollectedPerEpoch[epoch][resourceAddress] =
                    cumulativeResourceCollectedPerEpoch[epoch - 1][
                        resourceAddress
                    ] +
                    (incrementAmount / population);
            }
        }
    }

    function _mintToken(address token, address to, uint256 amount) internal {
        ResourceToken(token).mint(to, amount);
    }
}
