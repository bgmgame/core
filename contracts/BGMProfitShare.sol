
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import './interface/IMintableToken.sol';
import  './libraries/TransferHelper.sol';
import './interface/IReferences.sol';
import './interface/ILender.sol';
import './interface/IMasterChef.sol';
import './interface/IBGMPool.sol';

contract BGMProfitShare is Ownable,IMasterChef{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _bgmPools;

    // Info of each pool.
    struct PoolInfo {
        address poolAddr;
        uint256 allocPoint;       // How many allocation points assigned to this pool. Rewards to distribute per block.
        uint256 lastRewardBlock;  // Last block number that Rewards distribution occurs.
        uint256 accRewards; // Accumulated Rewards per share, times 1e12.
        uint256 rewardDebt; // Accumulated Rewards per share, times 1e12.
        uint256 totalAmount;    // Total amount of current pool deposit.
    }

    // The Share Token!
    address public shareToken;
    
    // Info of each pool.
    PoolInfo[] public poolInfo;

    // pid corresponding address
    mapping(address => uint256) public LpOfPid;
    mapping(address => PoolInfo) public poolMap;
        // Corresponding to the pid of the multLP pool
    mapping(uint256 => uint256) public poolCorrespond;

    // Control mining
    bool public paused = false;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when BGM mining starts.
    uint256 public startBlock;

    //last reward amount
    uint256 public reserve;
    
    constructor(
        address _shareToken,
        uint256 _startBlock
        
    ) public {
        shareToken = _shareToken;
        startBlock = _startBlock;
    }

    function setStartBlock(uint256 _startBlock) public onlyOwner {
        startBlock = _startBlock;
    }

    modifier notPause() {
        require(paused == false, "Mining has been suspended");
        _;
    }

    function massUpdatePools()override public {
        uint256 length = poolInfo.length;
        uint256 balance = IERC20(shareToken).balanceOf(address(this));
        if(reserve == balance){
            return;
        }
        uint256 newRewards = balance.sub(reserve);
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid,newRewards);
        }
        reserve = balance;
    }

    function poolLength() public view returns (uint256) {
        return poolInfo.length;
    }


    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid,uint256 newRewards) private {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 poolReward = newRewards.mul(1e12).mul(pool.allocPoint).div(totalAllocPoint);
        pool.accRewards = pool.accRewards.add(poolReward);
        pool.lastRewardBlock = block.number;
    }
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, address _pool, bool _withUpdate) public onlyOwner {
        require(address(_pool) != address(0), "_pool is the zero address");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        PoolInfo memory newPool = PoolInfo({
            poolAddr: _pool,
            allocPoint : _allocPoint,
            lastRewardBlock : lastRewardBlock,
            accRewards : 0,
            rewardDebt: 0,
            totalAmount : 0
        });
        poolInfo.push(newPool);
        poolMap[_pool] = newPool;
        LpOfPid[_pool] = poolLength() - 1;
    }

    function pending(uint256 , address _pool) external view override notPause returns (uint256 amount){
        PoolInfo storage pool = poolMap[_pool];
        amount = pool.accRewards.sub(pool.rewardDebt);
    }

    function deposit(uint256 , uint256 amount) external override notPause {
        address _poolAddr = msg.sender;
        PoolInfo storage pool = poolMap[_poolAddr];
        amount = pool.accRewards.sub(pool.rewardDebt);
        if(amount>0){
            TransferHelper.safeTransfer(shareToken,_poolAddr, amount);
            pool.rewardDebt = pool.accRewards;
        }
    }

    function withdraw(uint256 , uint256 amount) external override notPause {
        address _poolAddr = msg.sender;
        PoolInfo storage pool = poolMap[_poolAddr];
        amount = pool.accRewards.sub(pool.rewardDebt);
        if(amount>0){
            TransferHelper.safeTransfer(shareToken,_poolAddr, amount);
            pool.rewardDebt = pool.accRewards;
        }

    }

    function emergencyWithdraw(uint256 ) external override notPause{
        address _poolAddr = msg.sender;
        PoolInfo storage pool = poolMap[_poolAddr];
        uint amount = pool.accRewards.sub(pool.rewardDebt);
        if(amount>0){
            TransferHelper.safeTransfer(shareToken,_poolAddr, amount);
            pool.rewardDebt = pool.accRewards;
        }

    }

}
