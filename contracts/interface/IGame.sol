// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;


interface IGame{
    function wager(address _user,uint256 _uAmount,bytes calldata _data) external returns (uint) ;
    function withdraw(address _user,uint256 _uAmount,bytes calldata _data) external returns (uint ,uint) ;
}


