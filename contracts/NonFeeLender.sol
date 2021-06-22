
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
import './interface/IBGMPool.sol';

contract NoneFeeLender is Ownable ,ILender{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 lockAmount;     // How many LP tokens the user has provided.
        uint256 utAmount;       //already charge fee, charging = feeAccumulated
    }

    // The UT Token!
    IMintableToken public UT;
    address public bgmPool;
    
    mapping(address  => mapping(address=>UserInfo)) public userInfos;
    uint256 public lendUTRatio;
    event UserLend(address indexed user,address indexed lpToken,uint256 lockAmount,uint256 utAmount,address pool);
    event Repayment(address indexed user, uint256 utAmount,uint256 unlockAmount);

    constructor(
        address _ut,
        address _bgmPool,
        uint256 _lendUTRatio//7000

    ) public {
        UT = IMintableToken(_ut);
        bgmPool = _bgmPool;
        lendUTRatio = _lendUTRatio;
    }

    function setLendUTRatio(uint256 _lendUTRatio) public onlyOwner {
        lendUTRatio = _lendUTRatio;
    }

    address public bgmRouter;
    function setBGMRouter(address _bgmRouter) public onlyOwner{
        bgmRouter=_bgmRouter;
    }

    function setBGMPool(address _bgmPool) public onlyOwner{
        bgmPool=_bgmPool;
    }

    function setUTToken(address _ut) public onlyOwner{
        UT = IMintableToken(_ut);
    }

    function userLockForLend(address _user,address _lpToken,uint256 _lockAmount,address _investpool) external override returns (uint utAmount){
        require(msg.sender==bgmPool,'only call from pool');
        UserInfo storage user = userInfos[_user][_lpToken];
        utAmount = _lockAmount.mul(lendUTRatio).div(10000);//70%
        require(utAmount>0,'ut amount zero');
        user.lockAmount = user.lockAmount.add(_lockAmount);
        user.utAmount = user.utAmount.add(utAmount);
        UT.mint(_user, utAmount);
        emit UserLend(_user,_lpToken,_lockAmount,utAmount,_investpool);
    }

    function userPayFromRouter(address _user ,address _lpToken,uint256 _utAmount) external override {
        require(msg.sender==bgmRouter,'only call from router');
        _userRepay(_user,_lpToken,_utAmount);
    }

    function userRepay(address _lpToken,uint256 _utAmount) external returns (uint unlockAmount){
        return _userRepay(msg.sender,_lpToken,_utAmount);
    }
    // function lenderUnlock(address _lpToken,uint256 _unlockAmount,uint256 _feeAmount,address _unlockuser) external ;
    function _userRepay(address _user ,address _lpToken,uint256 _utAmount) internal returns (uint unlockAmount){
        require(_utAmount>0,'user utAmount error');
        
        UserInfo storage user = userInfos[_user][_lpToken];
        require(user.utAmount>=_utAmount,'user repay to large');
        unlockAmount = _utAmount.mul(10000).div(lendUTRatio);
        if(unlockAmount>user.lockAmount){
            unlockAmount = user.lockAmount;
        }
        UT.burn(_user,_utAmount);
        user.lockAmount = user.lockAmount.sub(unlockAmount);
        user.utAmount = user.utAmount.sub(_utAmount);
        IERC20(_lpToken).approve(bgmPool, unlockAmount);
        IBGMPool(bgmPool).lenderUnlock(_lpToken,unlockAmount,0,_user);
    }

    

}
