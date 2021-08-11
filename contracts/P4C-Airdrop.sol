// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract P4CAirdrop {
    
    using SafeMath for uint256;
        
    address public tokenContract;
    address public owner;
    uint256 startTime;
    uint256 endTime;
    uint256 airdropRuntime;
    uint256 public maxSubscribers;
    uint256 public numberOfSubscribers;
    uint256 public mainWalletCoins;
    uint256 public totalAirdrop;
    uint256 public userbalance;
    uint256 public totalCoinsMinted;
    uint256 public airdropTokenAmount;
    
    struct Subscribers {
        address _walletAddress;
        uint256 _amount;
        uint256 _id;
    }
    
    mapping (address => Subscribers) private subscriber_map;
    mapping (address => uint) private subscriber_ID;
    
    event ContractMsg(string message);
    event NewSubscriber(string msg, address subscriber);
    event TokenDropped(string msg, uint256 amount, address receiver);

    modifier onlyOwner { 
        require(msg.sender == owner);
        _;
    }

    //use 604800 seconds for a week
    constructor(uint256 _airdropTokenAmount, uint256 _airdropRuntimeInSeconds, uint256 _maxAirdropSubscribers, address _tokenContractAddress) {
        require(_airdropRuntimeInSeconds > 0);
        owner = msg.sender;
        maxSubscribers = _maxAirdropSubscribers; 
        tokenContract = _tokenContractAddress; 
        airdropRuntime = _airdropRuntimeInSeconds / 1 seconds;
        startTime = block.timestamp; 
        endTime = startTime + airdropRuntime; 
        airdropTokenAmount = _airdropTokenAmount;
        mainWalletCoins = _airdropTokenAmount; 
        emit ContractMsg("Airdrop contract deployed successfully");
    }
    
    //if ether sent direct to address
    receive() external payable {
        ethRefund();
    }
    
    //automatically sends any accidently sent ether back to the user
    function ethRefund() payable public {
        require(msg.value > 0);
        payable(msg.sender).transfer(msg.value);
        // payable(msg.sender).transfer(msg.value);
        emit ContractMsg("ETH refunded, do not send eth to this contract!");
    }
    
    //get ETHER balance of contract ( should always return 0 )
    function contractEthBalance() public view returns(uint) {
        address contractAddress = address(this);
        return contractAddress.balance;
    }
    
    //in the case ETH is somehow locked in the contract after airdrop. Use it to remove
    function sweepEth() public onlyOwner {
        require(contractEthBalance() > 0);
        payable(owner).transfer(contractEthBalance());
    }
    
    //retrieve leftover tokens after airdrop
    function sweepTokens() public onlyOwner {
        require(queryERC20Balance(address(this)) > 0 && endTime < block.timestamp);
        uint256 tokenBalance = queryERC20Balance(address(this));
        IERC20(tokenContract).approve(address(this), tokenBalance);
        IERC20(tokenContract).transferFrom(address(this), msg.sender, tokenBalance);
    }

    function newSubscriber() public
    {
        require(endTime > block.timestamp && queryERC20Balance(address(this)) > 0);
        if(numberOfSubscribers > maxSubscribers){
            emit ContractMsg("Airdrop Subscription Hardcap Reached, No Tokens Left");
            revert();
        }
        else {
         //map sender address and corresponding data into Subscriber struct
        Subscribers storage _sub = subscriber_map[msg.sender];
        //stop multiple address subs
        require(_sub._walletAddress == address(0));
        _sub._walletAddress = msg.sender;
        _sub._id = subscriber_ID[msg.sender];
        numberOfSubscribers++;
        tokenDrop(msg.sender);
        }
    }
    
    //auto token drop
    function tokenDrop(address _receiverAddress) private {
        require(endTime > block.timestamp && queryERC20Balance(address(this)) > 0);
        require(subscriber_map[msg.sender]._walletAddress != address(0));
        require(userbalance > 0); //threshold check 1
        
        if(userbalance == 0)
        {
            emit ContractMsg("P4C balance is zero, buy some token first");
            revert();
        }
        
        if(userbalance >= 160000000) //threshold check 2
        {
           // UserReceivesFromAirdrop = (userWalletCoins * totalAirdrop)/ (totalCoinsMinted - mainWalletCoins)
            uint256 tokenAmount1 = userbalance.mul(totalAirdrop);
            uint256 tokenAmount2 = totalCoinsMinted.sub(mainWalletCoins);
            uint256 tokenAmount = tokenAmount1.div(tokenAmount2);
            IERC20(tokenContract).approve(address(this), tokenAmount); //approve
            IERC20(tokenContract).transferFrom(address(this), _receiverAddress, tokenAmount); //transfer
            emit TokenDropped("Token Dropped - ", tokenAmount, _receiverAddress); 
            airdropTokenAmount = airdropTokenAmount.sub(tokenAmount);
            mainWalletCoins = airdropTokenAmount.sub(tokenAmount);

            subscriber_map[msg.sender]._amount += tokenAmount;
        }
        
    }
    
    //manual token drop
    function manualTokenDrop(address _receiverAddress, uint256 tokenAmount) public onlyOwner 
    {
        require(endTime > block.timestamp && queryERC20Balance(address(this)) > 0);
        require(userbalance > 0); //threshold check 1
        if(subscriber_map[_receiverAddress]._walletAddress == address(0)) {
            //new subscriber - map sender address and corresponding data into Subscriber struct
            Subscribers storage _sub = subscriber_map[_receiverAddress];
            _sub._walletAddress = _receiverAddress;
            _sub._id = subscriber_ID[_receiverAddress];
            numberOfSubscribers++;
        }
        
        if(userbalance == 0)
        {
            emit ContractMsg("P4C balance is zero, buy some token first");
            revert();
        }
        
        if(userbalance >= 160000000) //threshold check 2
        {
            uint256 tokenAmount1 = userbalance.mul(totalAirdrop);
            uint256 tokenAmount2 = totalCoinsMinted.sub(mainWalletCoins);
            tokenAmount = tokenAmount1.div(tokenAmount2);            
            IERC20(tokenContract).approve(address(this), tokenAmount); //approve
            IERC20(tokenContract).transferFrom(address(this), _receiverAddress, tokenAmount); //transfer
            emit TokenDropped("Token Dropped - ", tokenAmount, _receiverAddress); 
            airdropTokenAmount = airdropTokenAmount.sub(tokenAmount);
            mainWalletCoins = airdropTokenAmount.sub(tokenAmount);
        }
            
        subscriber_map[_receiverAddress]._amount += tokenAmount;
    }
    
    function queryERC20Balance(address _addressToQuery) view public returns (uint) {
        return IERC20(tokenContract).balanceOf(_addressToQuery);
    }
    
    function contractTokenBalance() public returns (uint) {
        uint256 mintedcoins = queryERC20Balance(address(this));
        totalCoinsMinted = mintedcoins;
        return totalCoinsMinted;
    }
    
    function UpdateTokenBalance() public returns (uint) {
        uint256 balance = IERC20(tokenContract).balanceOf(msg.sender);
        userbalance = balance;
        return userbalance;
    }
    
    function getNowTime() public view returns (uint) {
        return block.timestamp;
    }
    
    function getEndTime() public view returns (uint) {
        return endTime;
    }
    
    function getAirdropRuntime() public view returns(uint) {
        return airdropRuntime;
    }
    
    function getTimePassed() public view returns (uint) {
        require(startTime != 0);
        return (block.timestamp - startTime)/(1 seconds);
    }
    
    function getTimeLeft() public view returns (uint) {
        require(endTime > block.timestamp);
        return (endTime - block.timestamp)/(1 seconds);
    }
    
    function getairdrop() public returns (uint){
        uint256 _totalAirdrop = airdropTokenAmount;
        totalAirdrop = _totalAirdrop; 
        return totalAirdrop;
    }
}