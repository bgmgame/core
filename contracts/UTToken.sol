// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import './libraries/TransferHelper.sol';

contract UTToken is ERC20, Ownable {

    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _minters;
    uint256 public MINIMAL_U = 10*1e18;
    uint256 public chargeInFee = 0;
    uint256 public chargeOutFee = 0;
    address public feeTo;
    mapping(address => uint256) public usdTokensDecimal;

    event Deposit(address indexed user,address indexed to,uint256 amount,uint256 fee);
    event Withdraw(address indexed user,address indexed to,uint256 amount,uint256 fee);
    constructor(string memory name,string memory symbol,uint256 _chargeInFee,uint256 _chargeOutFee,address _feeTo) public ERC20(name, symbol){
        chargeInFee = _chargeInFee;
        chargeOutFee = _chargeOutFee;
        feeTo = _feeTo;
    }

    function addUSDToken(address _token)  external onlyOwner returns (uint256 decimals){
        decimals = ERC20(_token).decimals();
        usdTokensDecimal[_token] = decimals;
    }
    function setChargeFee(uint256 _chargeInFee,uint256 _chargeOutFee,address _feeTo) external onlyOwner{
        chargeInFee = _chargeInFee;
        chargeOutFee = _chargeOutFee;
        feeTo=_feeTo;
    }
    function amountUFromToken(address _token,uint256 amountToken) public view returns(uint amountU){
        uint256 decimalsU = usdTokensDecimal[_token];
        require(decimalsU>0,'not register USD token');
        //处理精度问题
        uint256 _decimalUT = decimals();
        if(decimalsU < _decimalUT){
            amountU = amountToken.mul(10**(_decimalUT.sub(decimalsU)));
        }else if(decimalsU > _decimalUT){
            amountU = amountToken.div(10**(decimalsU.sub(_decimalUT)));
        }else{
            amountU = amountToken;
        }
    }

    function amountTokenForU(address _token,uint256 amountU) public view returns(uint amountToken){
        uint256 decimalsU = usdTokensDecimal[_token];
        require(decimalsU>0,'not register USD token');
        //处理精度问题
        uint256 _decimalUT = decimals();
        if(decimalsU < _decimalUT){
            amountToken = amountU.div(10**(_decimalUT.sub(decimalsU)));
        }else if(decimalsU > _decimalUT){
            amountToken = amountU.mul(10**(decimalsU.sub(_decimalUT)));
        }else{
            amountToken = amountU;
        }
    }

    function deposit(address _token,uint amountToken,address _to) external returns(uint256 amountU){
        amountU = amountUFromToken(_token,amountToken);
        require(amountU>MINIMAL_U,'amount to low');
        TransferHelper.safeTransferFrom(_token, msg.sender, address(this), amountToken);
        uint256 fee = 0;
        if(chargeInFee>0){    
            fee =  amountToken.mul(chargeInFee).div(1e8);        
            amountU = amountUFromToken(_token,amountToken.sub(fee));
            if(fee>0)
            {
                TransferHelper.safeTransfer(_token,feeTo,fee);
            }
        }
        emit Deposit(msg.sender,_to, amountToken, fee);
        _mint(_to,amountU);
    }

    function withdraw(address _token,uint256 amountU,address _to) external returns(uint256 amountToken) {
        require(amountU>MINIMAL_U,'amount to low');
        amountToken = amountTokenForU(_token, amountU);
        _burn(msg.sender,amountU);
        uint256 fee = 0;
        if(chargeOutFee>0){
            fee = amountToken.mul(chargeOutFee).div(1e8);
            amountToken = amountToken.sub(fee);
        }
        emit Withdraw(msg.sender,_to, amountToken, fee);
        TransferHelper.safeTransfer(_token,_to,amountToken);
        if(fee>0)
        {
            TransferHelper.safeTransfer(_token,feeTo,fee);
        }
    }

    // mint with max supply
    function mint(address _to, uint256 _amount) external onlyMinter returns (bool) {
        _mint(_to, _amount);
        return true;
    }
    function burn(address _from ,uint256 _amount) external onlyMinter  returns (bool) {
        _burn(_from, _amount);
        return true;
    }

    function addMinter(address _addMinter) public onlyOwner returns (bool) {
        require(_addMinter != address(0), "BGMToken: _addMinter is the zero address");
        return EnumerableSet.add(_minters, _addMinter);
    }

    function delMinter(address _delMinter) public onlyOwner returns (bool) {
        require(_delMinter != address(0), "BGMToken: _delMinter is the zero address");
        return EnumerableSet.remove(_minters, _delMinter);
    }

    function getMinterLength() public view returns (uint256) {
        return EnumerableSet.length(_minters);
    }

    function isMinter(address account) public view returns (bool) {
        return EnumerableSet.contains(_minters, account);
    }

    function getMinter(uint256 _index) public view onlyOwner returns (address){
        require(_index <= getMinterLength() - 1, "BGMToken: index out of bounds");
        return EnumerableSet.at(_minters, _index);
    }

    // modifier for mint function
    modifier onlyMinter() {
        require(isMinter(msg.sender), "caller is not the minter");
        _;
    }

}
