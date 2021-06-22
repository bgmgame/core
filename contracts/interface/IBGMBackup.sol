// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBGMBackup{
    function profit() external returns(uint256 amountOut,uint256 amountIn);
}


