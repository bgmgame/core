// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBGMPool{
    function deposit(uint256 _pid, uint256 _amount,address _to) external ;
    function pidFromLPAddr(address _lpToken) external view returns(uint);
}


