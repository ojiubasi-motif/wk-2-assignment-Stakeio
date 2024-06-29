// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {UtitlityToken as TestToken, DiscreteStakingRewards} from "../src/Stakeio.sol";

contract StakeioTest is Test {
    TestToken private stakingToken;
    TestToken private rewardToken;
    DiscreteStakingRewards private stake;
    address[] private users = [address(11), address(12), address(13)];
    uint256[3] private STAKING_AMOUNTS = [2 * 1e6, 1 * 1e6, 0];
    uint256 private constant TOTAL_STAKED = 3 * 1e6;
    uint256[2] private REWARDS = [300 * 1e18];
    uint256 private constant TOTAL_REWARDS = 300 * 1e18;

    // setup user accounts for fuzzing
    // address private user1 = users[0];


    function setUp() public {
        stakingToken = new TestToken("stake", "STAKE", 6);
        rewardToken = new TestToken("reward", "REWARD", 18);
        stake = new DiscreteStakingRewards(
            address(stakingToken), address(rewardToken)
        );

        rewardToken.mint(address(this), TOTAL_REWARDS);
        rewardToken.approve(address(stake), TOTAL_REWARDS);


        for (uint256 i = 0; i < users.length; i++) {
            // uint256 amount = ;
            stakingToken.mint(users[i], STAKING_AMOUNTS[i]);
            vm.prank(users[i]);
            stakingToken.approve(address(stake), STAKING_AMOUNTS[i]);
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
    }

    function setUp_unstake() public {
        for (uint256 i = 0; i < users.length; i++) {
            uint amount = STAKING_AMOUNTS[i] / 2;
            vm.prank(users[i]);
            stake.unstake(amount);
        }
    }

    // ---------------------
    // FUZZZZZZZZ Beginnnsss
    // ---------------------
    function test_fuzz_stake(uint _stakeAmount) public {
            _stakeAmount = bound(_stakeAmount,1,STAKING_AMOUNTS[0]);
            // console.log("++++++>>>>>",_stakeAmount);
            address user1 = users[0];
            vm.deal(address(user1), _stakeAmount);
            uint256 b0 = stakingToken.balanceOf(user1);
            uint256 t0 = stake.totalSupply();
            uint256 s0 = stakingToken.balanceOf(address(stake));
            // console.log("the staketoken balance before==>",s0);
            // console.log("the balance before==>",b0);
            // console.log("protocol reward bal before==>",rewardToken.balanceOf(address(stake)));

            vm.prank(user1);
            stake.stake(_stakeAmount);

            uint256 b1 = stakingToken.balanceOf(user1);
            uint256 t1 = stake.totalSupply();
            uint256 s1 = stakingToken.balanceOf(address(stake));
            // console.log("the new reward-index after==>",stake.rewardIndex());

            assertEq(b0 - b1, _stakeAmount, "stake balance of user");
            assertEq(t1 - t0, _stakeAmount, "stake total supply");
            assertEq(s1 - s0, _stakeAmount, "stake token balance");
        
    }

    function test_fuzz_unstake(uint _stakeAmount) public {
            setUp_stake();
            setUp_updateRewardIndex();

            _stakeAmount = bound(_stakeAmount,1,STAKING_AMOUNTS[0]);

            address user1 = users[0];
            // vm.deal(address(user1), _stakeAmount);
            // uint256 stakeB0 = stakingToken.balanceOf(user1);//wallet balance
            // uint256 b0 = stake.balanceOf(user1);//user1's stake in the contract
            uint256 t0 = stake.totalSupply();//total stakes in the contract
            uint256 s0 = stakingToken.balanceOf(address(stake));

            vm.prank(user1);
            stake.unstake(_stakeAmount);

            uint256 stakeB1 = stakingToken.balanceOf(user1);//wallet balance
            uint256 b1 = stake.balanceOf(user1);//user1's stake in the contract
            uint256 t1 = stake.totalSupply();//total stakes in the contract
            uint256 s1 = stakingToken.balanceOf(address(stake));
            // console.log("the new reward-index after==>",stake.rewardIndex());

            assertEq(stakeB1, _stakeAmount, "stakeToken balance of user");
            assertEq(b1 + _stakeAmount, STAKING_AMOUNTS[0], "user1 stake balance in the contract");
            assertEq(t0, t1 + _stakeAmount, "stake pool total supply");
            assertEq(s0 -_stakeAmount, s1, "stakeToken balance of the contract");
    }

    function test_fuzz_claim(uint _stakeAmount) public {
            setUp_stake();
            setUp_updateRewardIndex();
            setUp_unstake();
            
            _stakeAmount = bound(_stakeAmount,1,STAKING_AMOUNTS[0]);
            // console.log("++++++>>>>>",_stakeAmount);
            address user1 = users[0];
            vm.deal(address(user1), _stakeAmount);
            uint256 b0 = stakingToken.balanceOf(user1);
            uint256 t0 = stake.totalSupply();
            uint256 s0 = stakingToken.balanceOf(address(stake));
            
            vm.prank(user1);
            stake.stake(_stakeAmount);

            uint256 b1 = stakingToken.balanceOf(user1);
            uint256 t1 = stake.totalSupply();
            uint256 s1 = stakingToken.balanceOf(address(stake));
            // console.log("the new reward-index after==>",stake.rewardIndex());

            assertEq(b0 - b1, _stakeAmount, "stake balance of user");
            assertEq(t1 - t0, _stakeAmount, "stake total supply");
            assertEq(s1 - s0, _stakeAmount, "stake token balance");
        
    }

}