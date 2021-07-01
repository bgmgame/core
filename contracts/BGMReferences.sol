// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";

import './libraries/TransferHelper.sol';
import './interface/IReferences.sol';
import './interface/IMintableToken.sol';
import './libraries/SafeMath.sol';


contract BGMReferences is Ownable,ReentrancyGuard,IReferences{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    // using TransferHelper for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _callers;

    struct UserInfo {
        uint256 rewardDebt;
        uint256 rewardAmount;
    }

    event RewardLayers(
        address ref,
        uint256 layer,
        uint256 rewardAmount,
        uint256 transferAmount
    );


    IReferenceStore public refStore;
    IMintableToken  public rewardToken;

    uint256 public totalRewardAmount;
    uint256 public totalRewardDebt;
    uint256 public MaxRewardAmount;

    // Info of each user that tokens.
    mapping(address => UserInfo) public userInfo;


    event Withdraw(address indexed user, uint256 amount);
    event RequestWithdraw(address indexed user, uint256 amount);

    event EmergencyWithdraw(address indexed user, uint256 amount);

    uint256 public  rewardBase = 10000;

    constructor(
        address _refStore,
        address _rewardToken,
        uint256 _MaxRewardAmount

    ) public {
        refStore=IReferenceStore(_refStore);
        rewardToken = IMintableToken(_rewardToken);
        MaxRewardAmount = _MaxRewardAmount;
    }

    function setRewardToken(address _rewardToken) public onlyOwner{
        rewardToken = IMintableToken(_rewardToken);
    }
    
    
    function setMaxRewardAmount(uint256 _MaxRewardAmount) public onlyOwner{
        MaxRewardAmount = _MaxRewardAmount;
    }
    function setStore(address _refStore) public onlyOwner{
        refStore=IReferenceStore(_refStore);
    }
    
    function setRewardBase(uint256 _rewardBase) public onlyOwner{
        rewardBase = _rewardBase;
    }

    function addCaller(address _addCaller) public onlyOwner returns (bool) {
        require(_addCaller != address(0), "References: _addCaller is the zero address");
        return EnumerableSet.add(_callers, _addCaller);
    }

    function delCaller(address _delCaller) public onlyOwner returns (bool) {
        require(_delCaller != address(0), "References: _delCaller is the zero address");
        return EnumerableSet.remove(_callers, _delCaller);
    }

    function getCallerLength() public view returns (uint256) {
        return EnumerableSet.length(_callers);
    }

    function isCaller(address account) public view returns (bool) {
        return EnumerableSet.contains(_callers, account);
    }

    function getCaller(uint256 _index) public view onlyOwner returns (address){
        require(_index <= getCallerLength() - 1, "References: index out of bounds");
        return EnumerableSet.at(_callers, _index);
    }

    // modifier for mint function
    modifier onlyCaller() {
        require(isCaller(msg.sender), "caller is not the Caller");
        _;
    }

    function setUpper(address upper,address distributor,bytes memory extdata) public {
        refStore.setUpper(msg.sender,upper, distributor,extdata);
        
    }
    uint256 public MaxRewardLayer = 2;
    function initRewardTable (uint256 []memory rewards) public onlyOwner{
        require(rewards.length == MaxRewardLayer ,'must be 2 layers');
        uint length = rewards.length;
        for(uint i=0;i<length;i++){
            rewardFeeRatio[i] = rewards[i];
        }
        // MaxRewardLayer = length;
    }
        
    mapping(uint256=>uint256) public rewardFeeRatio;


    function rewardUpper(address ref,uint256 amount) public override onlyCaller nonReentrant returns (uint256 mintAmount) {
        address upper = refStore.getUpper(ref);
        // uint256 leftAmount = amount;
        if(upper!=address(0x0)){
            // (uint256 rewardAmount,) =
             (,mintAmount)=rewardLayers(ref,amount,0);
            // leftAmount = leftAmount.sub(rewardAmount);
        }
        // if(leftAmount>0){
        //     if(_sweeper==address(0x0))
        //     {
        //         rewardUser(sweeper,leftAmount,0);
        //     }else{
        //         rewardUser(_sweeper,leftAmount,0);
        //     }
        // }
    }

    function rewardLayers(address ref,uint256 amount,uint256 layer) internal returns (uint256 rewardAmount,uint256 mintAmount) {
        rewardAmount = amount.mul(rewardFeeRatio[layer]).div(rewardBase);
        if(rewardAmount>0){
            mintAmount = rewardUser(ref,rewardAmount,layer);
        }
        layer = layer.add(1);
        if(layer < MaxRewardLayer){
            address upper = refStore.getUpper(ref);
            if(upper!=address(0x0)){
                (uint nextRewardAmount,uint nextMintAmount) = rewardLayers(upper,amount,layer);
                rewardAmount = rewardAmount.add(nextRewardAmount);
                mintAmount = mintAmount.add(nextMintAmount);
            }
        }
        

    }

    function pendingWithdraw(address _user) public view returns(uint256){
        UserInfo storage user = userInfo[_user];
        return user.rewardAmount.sub(user.rewardDebt);        

    }
    function withdraw() public nonReentrant override {
        UserInfo storage user = userInfo[msg.sender];
        uint256 amount = user.rewardAmount.sub(user.rewardDebt);
        require(amount>0,"No more bonus");
        
        uint256 balance = rewardToken.balanceOf(address(this));
        if(balance < amount){
            amount = balance;
        }
        require(amount.add(totalRewardDebt)<=totalRewardAmount,'token reward ?');
        totalRewardDebt = totalRewardDebt.add(amount);
        user.rewardDebt = user.rewardDebt.add(amount);
        // rewardToken.transfer(msg.sender,amount);
        // TransferHelper.safeTransfer(address(rewardToken),msg.sender,amount);
        rewardToken.mint(msg.sender,amount);
        emit Withdraw(msg.sender, amount);
    }

    function rewardUser(address ref,uint256 rewardAmount,uint256 layer) private returns(uint256 realRewardAmount) {
        UserInfo storage user = userInfo[ref];
        
        realRewardAmount = rewardAmount;

        if(totalRewardAmount.add(rewardAmount) > MaxRewardAmount){
            realRewardAmount = MaxRewardAmount.sub(totalRewardAmount);
        }

        if(realRewardAmount>0){
            totalRewardAmount = totalRewardAmount.add(realRewardAmount);
            // require(totalRewardAmount<=MaxRewardAmount,'reward amount excced max amount');
            user.rewardAmount = user.rewardAmount.add(realRewardAmount);
            totalRewardDebt = totalRewardDebt.add(realRewardAmount);
            user.rewardDebt = user.rewardDebt.add(realRewardAmount);
            rewardToken.mint(ref,realRewardAmount);
            emit RewardLayers(ref,layer,rewardAmount,realRewardAmount);
        }


    }

}
