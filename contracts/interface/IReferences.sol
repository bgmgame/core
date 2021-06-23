// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";

interface IReferences {
    function rewardUpper(address ref,uint256 amount) external  returns (uint256) ;
    function withdraw() external ;
}

interface IReferenceStore{
    function setUpper(address user,address upper,address distributor) external returns(bool);
    function getUpper(address _user) external  view returns (address);
}
