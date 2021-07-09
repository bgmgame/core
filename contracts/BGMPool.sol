
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import './interface/IMintableToken.sol';
import  './libraries/TransferHelper.sol';
import './interface/IBGMPool.sol';
import './interface/IReferences.sol';

contract BGMPool is Ownable ,IBGMPool{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. Rewards to distribute per block.
        uint256 lastRewardBlock;  // Last block number that Rewards distribution occurs.
        uint256 accRewardPerShare; // Accumulated Rewards per share, times 1e12.
        uint256 totalAmount;    // Total amount of current pool deposit.
        address investPool;     // token direct to invest Pool
    }

    // The BGM Token!
    IMintableToken public BGM;
    
    uint256 public blockRewards;
    // Info of each pool.
    PoolInfo[] public poolInfo;


    //refs
    IReferences public refs;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // pid corresponding address
    mapping(address => uint256) public LpOfPid;

    // Control mining
    bool public paused = false;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when BGM mining starts.
    uint256 public startBlock;

    
    event Deposit(address indexed user,address indexed touser, uint256 indexed pid, uint256 amount);

    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount,address indexed _to);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount,address indexed _to);

    constructor(
        address _BGM,
        address _refs,
        uint256 _blockRewards, //110
        uint256 _startBlock
        
    ) public {
        BGM = IMintableToken(_BGM);
        refs = IReferences(_refs);
        blockRewards = _blockRewards;
        startBlock = _startBlock;
    }

    function setStartBlock(uint256 _startBlock) public onlyOwner {
        startBlock = _startBlock;
    }

    function setBlockRewards(uint256 _blockRewards) public onlyOwner {
        blockRewards = _blockRewards;
    }
    function setRefs(address _refs) public onlyOwner{
        refs = IReferences(_refs);
    }

    function poolLength() public view returns (uint256) {
        return poolInfo.length;
    }

    function setPause() public onlyOwner {
        paused = !paused;
    }
    
      function pidFromLPAddr(address _token)external override view returns(uint256 pid){
        return LpOfPid[_token];
    }


    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate,address _investPool) public onlyOwner {
        require(address(_lpToken) != address(0), "_lpToken is the zero address");
        require(LpOfPid[address(_lpToken)]==0,'_lpToken already exist');

        require(!(poolLength()>0&& address(poolInfo[0].lpToken) == address(_lpToken)),'_lpToken already exist in 0');
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken : _lpToken,
            allocPoint : _allocPoint,
            lastRewardBlock : lastRewardBlock,
            accRewardPerShare : 0,
            totalAmount : 0,
            investPool: _investPool
        }));
        LpOfPid[address(_lpToken)] = poolLength() - 1;
    }

    // Update the given pool's BGM allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    function reward(uint256 blockNumber) public view returns (uint256 ) {
        return  (blockNumber.sub(startBlock).sub(1)).mul(blockRewards);
    }

    function getBlockRewards(uint256 _lastRewardBlock) public view returns (uint256) {
        if(block.number>startBlock){
            if(_lastRewardBlock<=startBlock)
            {
                return  (block.number.sub(startBlock).sub(1)).mul(blockRewards);
            }else{
                return  (block.number.sub(_lastRewardBlock).sub(1)).mul(blockRewards);
            }
        }
        else{
            return 0;
        }
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.totalAmount;
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 blockReward = getBlockRewards(pool.lastRewardBlock);
        if (blockReward <= 0) {
            return;
        }
        uint256 poolReward = blockReward.mul(pool.allocPoint).div(totalAllocPoint);
        bool minRet = BGM.mint(address(this), poolReward);
        if (minRet) {
            pool.accRewardPerShare = pool.accRewardPerShare.add(poolReward.mul(1e12).div(lpSupply));
        }
        pool.lastRewardBlock = block.number;
    }

    function allPending( address _user) external view returns (uint256 totalRewardAmount){
        uint256 length = poolInfo.length;
        for (uint256 _pid = 0; _pid < length; ++_pid) {
            uint256 rewardAmount = pending(_pid, _user);
            totalRewardAmount = totalRewardAmount.add(rewardAmount);
            // totalTokenAmount = totalTokenAmount.add(tokenAmount);
        }
    }

      // View function to see pending rewards on frontend.
    function pending(uint256 _pid,address _user) public view returns  (uint256){
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        // uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        uint256 lpSupply = pool.totalAmount;
        if (user.amount > 0) {
            if (block.number > pool.lastRewardBlock) {
                uint256 blockReward = getBlockRewards(pool.lastRewardBlock);
                uint256 poolReward = blockReward.mul(pool.allocPoint).div(totalAllocPoint);
                accRewardPerShare = accRewardPerShare.add(poolReward.mul(1e12).div(lpSupply));
                return user.amount.mul(accRewardPerShare).div(1e12).sub(user.rewardDebt);
            }
            if (block.number == pool.lastRewardBlock) {
                return user.amount.mul(accRewardPerShare).div(1e12).sub(user.rewardDebt);
            }
        }
        return 0;
    }

     // Deposit LP tokens to Pool for DDX allocation.
    function deposit(uint256 _pid, uint256 _amount,address _to) public override notPause {
        address _user = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pendingAmount = user.amount.mul(pool.accRewardPerShare).div(1e12).sub(user.rewardDebt);
            if (pendingAmount > 0) {
                safeRewardTransfer(_to, pendingAmount);
            }
        }
        if (_amount > 0) {
            // pool.lpToken.safeTransferFrom(_user, address(this), _amount);
            if(pool.investPool==address(0x0))
            {
                pool.lpToken.safeTransferFrom(_user, address(this), _amount);
            }else{
                pool.lpToken.safeTransferFrom(_user, pool.investPool, _amount);
            }
            
            user.amount = user.amount.add(_amount);
            pool.totalAmount = pool.totalAmount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);
        emit Deposit(_user,_to, _pid, _amount);
    }


  

    // Withdraw LP tokens from Pool.
    function withdraw(uint256 _pid, uint256 _amount,address _to) public  {
        address _user = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);

        uint256 pendingAmount = user.amount.mul(pool.accRewardPerShare).div(1e12).sub(user.rewardDebt);
        if (pendingAmount > 0) {
            safeRewardTransfer(_to, pendingAmount);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.totalAmount = pool.totalAmount.sub(_amount);
            pool.lpToken.safeTransfer(_to, _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);
        emit Withdraw(_user, _pid, _amount,_to);
    }

     // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyNative(uint256 amount) public onlyOwner {
        TransferHelper.safeTransferNative(msg.sender,amount)  ;
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid,address _to) public {
        address _user = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(_to, amount);
        pool.totalAmount = pool.totalAmount.sub(amount);
        emit EmergencyWithdraw(_user, _pid, amount,_to);

    }
    // Safe BGM transfer function, just in case if rounding error causes pool to not have enough BGMs.
    function safeRewardTransfer(address _to, uint256 _amount) internal {
        uint256 BGMBal = BGM.balanceOf(address(this));
        if (_amount > BGMBal) {
            _amount = BGMBal;
        }
        //reward to referer.
        if(address(refs)!=address(0x0)){
            refs.rewardUpper(_to,_amount);
        }
        BGM.transfer(_to, _amount);
    }

    modifier notPause() {
        require(paused == false, "Mining has been suspended");
        _;
    }

}
