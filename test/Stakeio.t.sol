// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test,console} from "forge-std/Test.sol";
// import {TestToken} from "sce/sol/TestToken.sol";
import {UtitlityToken as TestToken, DiscreteStakingRewards} from "../src/Stakeio.sol";

contract DiscreteStakingRewardsTest is Test {
    TestToken private stakingToken;
    TestToken private rewardToken;
    DiscreteStakingRewards private stake;
    address[] private users = [address(11), address(12), address(13)];
    uint256[3] private STAKING_AMOUNTS = [2 * 1e6, 1 * 1e6, 0];
    uint256 private constant TOTAL_STAKED = 3 * 1e6;
    uint256[2] private REWARDS = [300 * 1e18];
    uint256 private constant TOTAL_REWARDS = 300 * 1e18;

    function setUp() public {
        stakingToken = new TestToken("stake", "STAKE", 6);
        rewardToken = new TestToken("reward", "REWARD", 18);
        stake = new DiscreteStakingRewards(
            address(stakingToken), address(rewardToken)
        );

        rewardToken.mint(address(this), TOTAL_REWARDS);
        rewardToken.approve(address(stake), TOTAL_REWARDS);
        // console.log("reward token bal==>",rewardToken.balanceOf(address(this)));


        for (uint256 i = 0; i < users.length; i++) {
            uint256 amount = STAKING_AMOUNTS[i];
            stakingToken.mint(users[i], amount);
            vm.prank(users[i]);
            stakingToken.approve(address(stake), amount);
        }

        vm.label(address(stakingToken), "StakingToken");
        vm.label(address(rewardToken), "RewardToken");
        vm.label(address(stake), "DiscreteStakingRewards");
    }

    function setUp_stake() public {
        for (uint256 i = 0; i < users.length; i++) {
            if (STAKING_AMOUNTS[i] > 0) {
                vm.prank(users[i]);
                stake.stake(STAKING_AMOUNTS[i]);
            }
        }
    }

    function setUp_updateRewardIndex() public {
        stake.updateRewardIndex(REWARDS[0]);
        console.log("the staking contract reward bal==>",rewardToken.balanceOf(address(stake)));
        console.log("the rewardIndex ==>",stake.rewardIndex());
    }

    function setUp_unstake() public {
        for (uint256 i = 0; i < users.length; i++) {
            vm.prank(users[i]);
            stake.unstake(STAKING_AMOUNTS[i]);
        }
    }

    function test_stake() public {
        for (uint256 i = 0; i < users.length; i++) {
            uint256 b0 = stake.balanceOf(users[i]);
            uint256 t0 = stake.totalSupply();
            uint256 s0 = stakingToken.balanceOf(address(stake));
            // console.log("the new reward-index before==>",stake.rewardIndex());
            // console.log("protocol reward bal before==>",rewardToken.balanceOf(address(stake)));

            vm.prank(users[i]);
            stake.stake(STAKING_AMOUNTS[i]);
            uint256 b1 = stake.balanceOf(users[i]);
            uint256 t1 = stake.totalSupply();
            uint256 s1 = stakingToken.balanceOf(address(stake));
            // console.log("the new reward-index after==>",stake.rewardIndex());

            assertEq(b1 - b0, STAKING_AMOUNTS[i], "stake balance of user");
            assertEq(t1 - t0, STAKING_AMOUNTS[i], "stake total supply");
            assertEq(s1 - s0, STAKING_AMOUNTS[i], "stake token balance");
        }
    }

    

    function test_unstake() public {
        setUp_stake();
        setUp_updateRewardIndex();

        for (uint256 i = 0; i < users.length; i++) {
            uint256 b0 = stake.balanceOf(users[i]);
            uint256 t0 = stake.totalSupply();
            uint256 s0 = stakingToken.balanceOf(users[i]);
            vm.prank(users[i]);
            stake.unstake(STAKING_AMOUNTS[i]);
            uint256 b1 = stake.balanceOf(users[i]);
            uint256 t1 = stake.totalSupply();
            uint256 s1 = stakingToken.balanceOf(users[i]);

            assertEq(b0 - b1, STAKING_AMOUNTS[i], "stake balance of user");
            assertEq(t0 - t1, STAKING_AMOUNTS[i], "stake total supply");
            assertEq(s1 - s0, STAKING_AMOUNTS[i], "stake token balance");
        }
    }

    function test_calculateRewardsEarned() public {
        setUp_stake();
        setUp_updateRewardIndex();
        setUp_unstake();

        for (uint256 i = 0; i < users.length; i++) {
            assertEq(
                stake.calculateRewardsEarned(users[i]),
                TOTAL_REWARDS * STAKING_AMOUNTS[i] / TOTAL_STAKED,
                "user rewards"
            );
        }
    }

    function test_claim() public {
        setUp_stake();
        setUp_updateRewardIndex();
        setUp_unstake();

        for (uint256 i = 0; i < users.length; i++) {
            vm.prank(users[i]);
            stake.claim();
            console.log("eser claimed reward==>",rewardToken.balanceOf(users[i]));
            assertEq(
                rewardToken.balanceOf(users[i]),
                TOTAL_REWARDS * STAKING_AMOUNTS[i] / TOTAL_STAKED,
                "rewards claimed"
            );
            assertEq(
                stake.calculateRewardsEarned(users[i]), 0, "calculated rewards"
            );
        }
    }
}
