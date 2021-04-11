// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {MCHToken} from "./MCHToken.sol";
import {MCFToken} from"./MCFToken.sol";
import './StakeContract.sol';


/* @title Staking Pool Contract
 * Open Zeppelin Pausable is Ownable.  contains address owner */

contract StakePool is Pausable {
 
  using SafeMath for uint;
  address private owner;
  MCHToken public mchtoken;
  MCFToken public mcftoken;
  uint public end;
  

  
  modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only owner can call this function."
        );
        _;
    }

/** @dev address of staking contract
    * this variable is set at construction, and can be changed only by owner.*/
  
  address payable private stakeContract;
  
  /** @dev staking contract object to interact with staking mechanism.
    * this is a mock contract.  */
  
  StakeContract private sc; 
  
   /** @dev track total staked amount */
  uint private totalStaked;
  
  /** @dev track total deposited to pool */
  uint private totalDeposited;
  
  /** @dev track balances of ether deposited to pool */
  mapping(address => uint) private Balances;
 
  /** @dev track balances of ether staked */
  mapping(address => uint) private stakedBalances;
  
  /** @dev track users
    * users must be tracked in this array because mapping is not iterable */
  address[] private stakers;
  
  mapping(address => bool) public hasStaked;
  mapping(address => bool) public isStaking;
  
  /** @dev trigger notification of staked amount
    * @param sender       msg.sender for the transaction
    * @param amount       msg.value for the transaction
    */
  event NotifyStaked(address sender, uint amount);
  
  
  /** @dev trigger notification of withdrawal
    * @param sender   address of msg.sender
    * @param startBal users starting balance
    * @param finalBal users final balance after withdrawal
    * @param request  users requested withdraw amount
    */
  event NotifyWithdrawal(
    address sender,
    uint startBal,
    uint finalBal,
    uint request);
    
    
    /** @dev notify when funds received from staking contract
    * @param sender       msg.sender for the transaction
    * @param amount       msg.value for the transaction
   */
  event NotifyFallback(address sender, uint amount);
  
  /** @dev trigger notification of deposits
    * @param sender  msg.sender for the transaction
    * @param amount  msg.value for the transaction
    * @param balance the users balance including this deposit
   */
  event NotifyDeposit(address sender, uint amount, uint balance);

    
    
  constructor(MCHToken _mchtoken, MCFToken _mcftoken,address payable _stakeContract)  {
        mchtoken = _mchtoken;
        mcftoken = _mcftoken;
        owner = msg.sender;
        require(_stakeContract != address(0));
        stakeContract = _stakeContract;
        sc = StakeContract(stakeContract);
     // set owner to users[0] because unknown user will return 0 from userIndex
     // this also allows owners to withdraw their own earnings using same
     // functions as regular users
        stakers.push(owner);
        end=block.timestamp+15 days;
    }
    
    
    /** @dev payable fallback
    * it is assumed that only funds received will be from stakeContract */
   receive() external payable {
    emit NotifyFallback(msg.sender, msg.value);
   }
  
   /** @dev stake funds to stakeContract
    */
  function stake(uint amount) external  {
      
    // * update mappings
    // * send total balance to stakeContract
    uint toStake;
    for (uint i = 0; i < stakers.length; i++) {
      toStake = toStake.add(amount);
      stakedBalances[stakers[i]] = stakedBalances[stakers[i]].add(amount);
    }
    
    // track total staked
    totalStaked = totalStaked.add(toStake);
    
    mchtoken.transferFrom(msg.sender,address(sc),amount);
    
  }
  
  // Issuing Tokens
    
    function issueTokens() public onlyOwner {

        // Issue tokens to all stakers
        
        for (uint i=0; i<stakers.length; i++) {
            address recipient = stakers[i];
            uint balance = stakedBalances[recipient];
            if(balance > 0) {
                mcftoken.transfer(recipient, balance);
            }
        }
    }
    
    
    /** @dev withdrawal funds out of pool
    * @param wdValue amount to withdraw
    */
  function Harvest(uint wdValue) external whenNotPaused {
    require(wdValue > 0);
    require(Balances[msg.sender] >= wdValue);
    
    uint startBalance = Balances[msg.sender];
    Balances[msg.sender] = Balances[msg.sender].sub(wdValue);

    payable(msg.sender).transfer(wdValue);

    emit NotifyWithdrawal(
      msg.sender,
      startBalance,
      Balances[msg.sender],
      wdValue
    );
  }
  
  
  /** @dev unstake funds from stakeContract
    */
  function unstake(uint amount) external  {
      
    for (uint i = 0; i < stakers.length; i++) {
      stakedBalances[stakers[i]] = stakedBalances[stakers[i]].sub(amount);
      Balances[stakers[i]] = Balances[stakers[i]].add(amount);
    
    }
   // track total staked
    totalStaked = totalStaked.sub(amount);

    sc.withdraw(amount);

 }    
 
  /** @dev deposit funds to the contract
    */
  function deposit() external payable whenNotPaused {
    Balances[msg.sender] = Balances[msg.sender].add(msg.value);
    emit NotifyDeposit(msg.sender, msg.value, Balances[msg.sender]);
  }
}
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
