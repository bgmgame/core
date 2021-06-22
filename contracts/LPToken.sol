// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "./interface/ILPToken.sol";

contract LPToken is ERC20,Ownable,ILPToken{

    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _minters;

    address public token;
    uint256 public reserve;
    uint private unlocked = 1;
     
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    modifier lock() {
        require(unlocked == 1, 'BLPToken: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor(address _token) public ERC20("BGM LPToken", "BLP"){
        token = _token;
    }

    event Mint(address indexed sender, uint amount);
    event Sync(uint256 reserve);
    event ShareProfit(uint256 reserve);
    event Burn(address indexed sender, uint amount, address indexed to);

    uint256 public MINIMUM_LIQUIDITY = 1000;
    
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

    function mint(address _to) external onlyMinter override lock returns (uint liquidity) {
        uint _reserve = reserve;
        uint balance = ERC20(token).balanceOf(address(this));
        uint amount = balance.sub(reserve);
        uint _totalSupply = totalSupply(); // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = balance;
            _mint(address(this), balance); // permanently lock the first MINIMUM_LIQUIDITY tokens            
        } else {
            liquidity = amount.mul(_totalSupply) / _reserve;
        }
        require(liquidity > 0, 'LPToken: INSUFFICIENT_LIQUIDITY_MINTED');

        _mint(_to, liquidity);
        _update();
        emit Mint(_to,amount);
    }

    function burn(address _to) external onlyMinter override lock returns (uint ) {
        address _token = token;                                // gas savings
        uint balance = ERC20(_token).balanceOf(address(this));
        uint liquidity = balanceOf(address(this));
        uint amount = liquidity.mul(balance) / totalSupply(); // using balances ensures pro-rata distribution
        require(liquidity > 0, 'BLPToken: INSUFFICIENT_LIQUIDITY_BURNED');
        _burn(address(this), liquidity);
        _safeTransfer(_token, _to, amount);
        _update();
        emit Burn(msg.sender, liquidity, _to);
        return amount;
    }

    function _update() private {
        reserve = ERC20(token).balanceOf(address(this));
        emit Sync(reserve);
    }

    function profit(uint256 amountOut,address _to) onlyMinter override external lock returns (uint){
        if(amountOut>0)
        {//need to transfer out
            _safeTransfer(token,_to, amountOut);
        }
        _update();        
    }
        
    //     _update();

    //     emit ShareProfit(reserve);
    // }

    // force balances to match reserves
    function skim(address to) external lock {
        address _token = token; // gas savings
       _safeTransfer(_token, to, ERC20(_token).balanceOf(address(this)).sub(reserve));
    }

    // force reserves to match balances
    function sync() external lock {
        _update();
    }
    
     function _safeTransfer(address _token, address to, uint value) private {
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'BLPToken: TRANSFER_FAILED');
    }
}
