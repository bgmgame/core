// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;




interface IBGMRouter  {
    
    //注册绑定用户
    function registerUser(address upper) external ;
    
    //交换USDT/BUSD/DAI到UT
    function swapTokenForUT(address _token,uint256 amountToken,address to) external returns(uint256 amountU);

    //交换UT到USDT/BUSD/DAI
    function swapUTForToken(address _token,uint256 amountU,address to) external returns(uint256 amountToken);
    
    //添加稳定币到池子，topool是否将流动性直接到BGMPool挖矿
    function addBonusPool(address _token,uint256 amountToken,address to,bool topool) external returns(uint256 amountU,uint256 liqudity) ;

    //从池子里面移出流动性
    function removeBonusPool(address _token,uint256 liquidity,address to) external returns(uint256 amountToken,uint256 amountU);
    //游戏投注接口，直接通过稳定币投
    function wager(address _token,address _game,uint256 amountToken,bytes calldata _data) external returns (uint amountU);

    //游戏提现接口，直接返回稳定币
    function withdraw(address _token,address _game,uint256 amountToken,address _to,bytes calldata _data) external returns (uint amountU,uint realAmountU,uint realAmountToken);
    
    //从bgm池子里借出UT
    function userLend(uint256 _pid,uint256 _lockAmount,address _lender) external ;

    //归还UT给lender    
    function userPayFromRouter(address _lender,address _lpToken,uint256 _utAmount) external;
    
    //游戏奖池控制，amountUIn收益多少
    function fillGamePool(uint256 amountUIn) external  returns (uint256 amountOut,uint256 amountIn,uint256 amountU) ;

    //利润分配
    function profitShare(uint256 amountU) external;

}
