// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import './interface/IReferences.sol';
import './libraries/SafeMath.sol';


contract ReferencesStore is Ownable,IReferenceStore{
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _callers;

    event ReferenceUpdate(
        address user,
        address lastReference,
        address changeReference
    );

    struct UserInfo {
        address upper;
        uint256 joinTimeStamp;
    }


    mapping(address => UserInfo) public userInfo;
    constructor( ) public {
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

    function setUpper(address _user,address upper) public override onlyCaller returns (bool) {
        UserInfo storage user = userInfo[_user];
        if(user.upper!=address(0x0)){
            return false;
        }
        else{
            if(upper!=address(0x0)){
                if(checkLoop(upper,_user)){
                    UserInfo storage upperUser = userInfo[upper];
                    if(upperUser.joinTimeStamp==0){
                        upperUser.joinTimeStamp = block.timestamp;
                    }
                }
            }
            emit ReferenceUpdate(_user,user.upper,upper); 
            user.upper = upper;
            user.joinTimeStamp = block.timestamp;
            return true;
        }
       
        
    }
    function checkLoop(address ref,address check) public view returns (bool){
        UserInfo storage user = userInfo[ref];
        if(user.upper==check){
            //,'referee loop');
            return false;
        }
        else {
            if(user.upper!=address(0x0))
            {
                return checkLoop(user.upper,check);
            }
            return true;
        }
    }
    
    function changeUpper(address ref,address upper) public onlyOwner {
        UserInfo storage user = userInfo[ref];
        if(upper!=address(0x0)){
            checkLoop(upper,ref);
            UserInfo storage upperUser = userInfo[upper];
            if(upperUser.joinTimeStamp==0){
                upperUser.joinTimeStamp = block.timestamp;
            }
        }
        emit ReferenceUpdate(ref,user.upper,upper);
        user.upper = upper;
        user.joinTimeStamp = block.timestamp;
    }

    function getUpper(address _user) public override view returns (address){
        return userInfo[_user].upper;
    }
}
