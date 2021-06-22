// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import './interface/ILPToken.sol';
import  './uniswapv2/libraries/TransferHelper.sol';
import './interface/IMasterChef.sol';


contract BGMBackup is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IMasterChef  public masterChef;

    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _caller;

    address public emergencyAddress;
    address public lpToken;
    address public UToken;
    uint256 public MINIMAL_AMOUNT;
    event ProfitShare(uint256 amountIn,uint256 amountOut);

    constructor (uint256 minimal_amount,address _lpToken,address _UToken,address _emergencyAddress,address _masterChef) public {
        require(_emergencyAddress != address(0), "Is zero address");
        lpToken = _lpToken;
        UToken = _UToken;
        MINIMAL_AMOUNT = minimal_amount;
        emergencyAddress = _emergencyAddress;
        masterChef = IMasterChef(_masterChef);

    }


    function setMinimal(uint256 minimal_amount) public onlyOwner{
        MINIMAL_AMOUNT = minimal_amount;
    }
    
    function setMasterChef(address _masterChef) public onlyOwner{
        masterChef = IMasterChef(_masterChef);
    }
    
    
    function setEmergencyAddress(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "Is zero address");
        emergencyAddress = _newAddress;
    }

    function addCaller(address _newCaller) public onlyOwner returns (bool) {
        require(_newCaller != address(0), "NewCaller is the zero address");
        return EnumerableSet.add(_caller, _newCaller);
    }

    function delCaller(address _delCaller) public onlyOwner returns (bool) {
        require(_delCaller != address(0), "DelCaller is the zero address");
        return EnumerableSet.remove(_caller, _delCaller);
    }

    function getCallerLength() public view returns (uint256) {
        return EnumerableSet.length(_caller);
    }

    function isCaller(address _call) public view returns (bool) {
        return EnumerableSet.contains(_caller, _call);
    }

    function getCaller(uint256 _index) public view returns (address){
        require(_index <= getCallerLength() - 1, "index out of bounds");
        return EnumerableSet.at(_caller, _index);
    }
    
     function profitV() public view returns (uint256 amountOut,uint256 amountIn){
        uint256 afterToken = IERC20(UToken).balanceOf(address(this));
        
        if(afterToken<MINIMAL_AMOUNT){
            amountOut = MINIMAL_AMOUNT.sub(afterToken);
        }else{
            amountIn = afterToken.sub(MINIMAL_AMOUNT);
        }


     }
    function profit() external onlyCaller returns (uint256 amountOut,uint256 amountIn){
        masterChef.withdraw(0,0);
        uint256 afterToken = IERC20(UToken).balanceOf(address(this));
        if(afterToken<MINIMAL_AMOUNT){
            amountOut = MINIMAL_AMOUNT.sub(afterToken);
        }else{
            amountIn = afterToken.sub(MINIMAL_AMOUNT);
        }
        if(amountIn>0){
            TransferHelper.safeTransfer(UToken, lpToken, amountIn);
        }
        ILPToken(lpToken).profit(amountOut,address(this));

        emit ProfitShare(amountIn,amountOut);
    
    }

    modifier onlyCaller() {
        require(isCaller(msg.sender), "Not the caller");
        _;
    }



    function emergencyWithdraw(address _token) public onlyOwner {
        require(IERC20(_token).balanceOf(address(this)) > 0, "Insufficient contract balance");
        IERC20(_token).transfer(emergencyAddress, IERC20(_token).balanceOf(address(this)));
    }

      // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyNative(uint256 amount) public onlyOwner {
        TransferHelper.safeTransferNative(msg.sender,amount)  ;
    }
}

