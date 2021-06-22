// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import './interface/IMintableToken.sol';
import './interface/ILPToken.sol';
import './libraries/TransferHelper.sol';
import './interface/IGame.sol';
import './interface/IBGMPool.sol';
import './interface/IBGMBackup.sol';
import './UTToken.sol';
import './ReferencesStore.sol';
import './interface/IMasterChef.sol';
import './interface/IBGMRouter.sol';
import './interface/ILender.sol';



contract BGMRouter is Ownable,IBGMRouter {
    using SafeMath for uint256;
    address public bgmPool;
    address public bgmBackup;
    address public tokenU;
    address public lptoken;
    address public feeTo;
    address public sweeper;
    address public refStore;
    address public bgmRefs;
    address public bgmProfitShare;


    mapping(address => IGame)  public games;
    
    constructor() public {
        // tokenU = _tokenU;
        // bgmPool = _bgmPool;
        // lptoken = _lptoken;
        // feeTo = _feeTo;
        // sweeper= _sweeper;
    }
    function setTokenU (address _tokenU) public onlyOwner{
        tokenU = _tokenU;
    }
    function setBGMPool (address _bgmPool) public onlyOwner{
        bgmPool = _bgmPool;
    }
    function setBGMBackup(address _bgmBackup) public onlyOwner{
        bgmBackup = _bgmBackup;
    }
    function setLPToken (address _lptoken) public onlyOwner{
        lptoken = _lptoken;
    }
    function setFeeTo (address _feeTo) public onlyOwner{
        feeTo = _feeTo;
    }
    function setSweeper (address _sweeper) public onlyOwner{
        sweeper = _sweeper;
    }
    function setRefStore(address _refStore) public onlyOwner{
        refStore = _refStore;
    }

    function setBGMRefs(address _bgmRefs) public onlyOwner{
        bgmRefs = _bgmRefs;
    }
    function setBGMProfitShare(address _bgmProfitShare) public onlyOwner{
        bgmProfitShare = _bgmProfitShare;
    }
    


    //注册绑定用户
    function registerUser(address upper) external override{
        ReferencesStore(refStore).setUpper(msg.sender, upper);
    }
    
    //添加游戏
    function addGame(address _game) public onlyOwner{
        games[_game] = IGame(_game);
    }
 
    function swapTokenForUT(address _token,uint256 amountToken,address to) external override returns(uint256 amountU){
        TransferHelper.safeTransferFrom(_token, msg.sender, address(this), amountToken);
        TransferHelper.safeApprove(_token, tokenU, amountToken);
        amountU = UTToken(tokenU).deposit(_token,amountToken,to);
    }

    function swapUTForToken(address _token,uint256 amountU,address to) external override returns(uint256 amountToken){
        TransferHelper.safeTransferFrom(tokenU, msg.sender, address(this), amountU);
        amountToken = UTToken(tokenU).withdraw(_token, amountU, to);
    }
    

    function addBonusPool(address _token,uint256 amountToken,address to,bool topool) external override returns(uint256 amountU,uint256 liqudity) {

        TransferHelper.safeTransferFrom(_token, msg.sender, address(this), amountToken);
        TransferHelper.safeApprove(_token, tokenU, amountToken);
        amountU = UTToken(tokenU).deposit(_token,amountToken,lptoken);
        // // IMintableToken(tokenU).mint(lptoken,amountU);
        if(topool){
            liqudity = ILPToken(lptoken).mint(address(this));
            uint pid=IBGMPool(bgmPool).pidFromLPAddr(lptoken);
            TransferHelper.safeApprove(lptoken, bgmPool, liqudity);
            IBGMPool(bgmPool).deposit(pid,liqudity,to);
        }else{
            liqudity = ILPToken(lptoken).mint(to);
        }
    }

    function removeBonusPool(address _token,uint256 liquidity,address to) external override returns(uint256 amountToken,uint256 amountU) {
        // uint256 decimals = usdTokensDecimal[_token];
        TransferHelper.safeTransferFrom(lptoken, msg.sender, lptoken, liquidity); // send liquidity to lptoken
        amountU = ILPToken(lptoken).burn(address(this));
        amountToken = UTToken(tokenU).withdraw(_token, amountU, to);
    }

    function wager(address _token,address _game,uint256 amountToken,bytes calldata _data) external override returns (uint amountU){
        // amountU = amountUFromToken(_token,amountToken);
        address _user = msg.sender;
        TransferHelper.safeTransferFrom(_token, _user, address(this), amountToken);
        amountU = UTToken(tokenU).deposit(_token,amountToken,address(this));
        IERC20(tokenU).approve(_game,amountU);
        games[_game].wager(_user,amountU,_data);
        uint256 amountNotUsed = IERC20(tokenU).balanceOf(address(this));
        if(amountNotUsed>0){
            TransferHelper.safeTransfer(tokenU,sweeper,amountNotUsed);
        }
        
    }

    function withdraw(address _token,address _game,uint256 amountToken,address _to,bytes calldata _data) external override returns (uint amountU,uint realAmountU,uint realAmountToken){
        address _user = msg.sender;
        // uint256 beforeUBalance = IERC20(tokenU).balanceOf(address(this));
        amountU = UTToken(tokenU).amountUFromToken(_token,amountToken);
        games[_game].withdraw(_user,amountU,_data);
        realAmountU = IERC20(tokenU).balanceOf(address(this));
        // realAmountU = afterUBalance.sub(beforeUBalance);
        realAmountToken = UTToken(tokenU).withdraw(_token,realAmountU,_to);
    }
    
    function profitShare(uint256 amountU) external override {
        require(bgmProfitShare!=address(0x0),'profit share is zero addr');
        TransferHelper.safeTransferFrom(tokenU, msg.sender, bgmProfitShare, amountU);
        IMasterChef(bgmProfitShare).massUpdatePools();
    }


    function userLend(uint256 _pid,uint256 _lockAmount,address _lender) external override {
        require(bgmPool!=address(0x0),'bgmPool is zero addr');
        IBGMPool(bgmPool).userLockFromRouter(msg.sender,_pid,_lockAmount,_lender);
    }
    function userPayFromRouter(address _lender,address _lpToken,uint256 _utAmount) external override {
        require(_lender!=address(0x0),'_lender share is zero addr');
        ILender(_lender).userPayFromRouter(msg.sender,_lpToken,_utAmount);
    }
    

    function fillGamePool(uint256 amountUIn) external override returns (uint256 amountOut,uint256 amountIn,uint256 amountU){
        address _game = msg.sender;
        require(address(games[_game])==msg.sender,'not game controller');
        if(amountUIn>0){
            TransferHelper.safeTransferFrom(tokenU, _game, bgmBackup, amountUIn);
        }
        uint256 beforeUBalance = IERC20(tokenU).balanceOf(address(this));
        (amountOut,amountIn) = IBGMBackup(bgmBackup).profit();
        uint256 afterUBalance = IERC20(tokenU).balanceOf(address(this));
        amountU = afterUBalance.sub(beforeUBalance);
        if(amountU>0){
            TransferHelper.safeTransfer(tokenU, bgmBackup, amountU);
        }

    }

}
