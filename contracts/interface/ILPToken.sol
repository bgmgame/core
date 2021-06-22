// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface ILPToken is  IERC20{
    function mint(address _to) external  returns (uint) ;
    function burn(address _to) external  returns (uint) ;
    function profit(uint256 amountOut,address _to) external  returns (uint);
}

