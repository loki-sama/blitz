pragma solidity ^0.4.17;
/**
 * Blitz Token for the Blitz Film, cerated at the Blockstack Hackathon Berlin
 * /


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}


// NOTE: BasicToken only has partial ERC20 support
contract Blitz is BasicToken {
  address owner;
  uint256 public teamNum;
  mapping(address => bool) shareholder;

  // expose these for ERC20 tools
  string public constant name = "BLITZ";
  string public constant symbol = "BLITZ";
  uint8 public constant decimals = 17;

  // Significant digits tokenPrecision
  uint256 private constant tokenPrecision = 10e18;

  // TODO: set this final, this equates to an amount
  // in dollars.
  uint256 public constant hardCap = 1 * tokenPrecision;


  uint256 public tokenValue = 1 * tokenPrecision;

  uint256 public totalAmount = 0;
 


  // number of tokens investors will receive per eth invested
  uint256 public tokensPerEth;

  // Ico start/end timestamps, between which (inclusively) investments are accepted
  uint public icoStart;
  uint public icoEnd;

  address[] beneficiaries;
  
  // current registred change address
  address public currentSaleAddress;
  bool public funded = false;
  uint256 public distribute = 0;
  // custom events
  event Freeze(address indexed from, uint256 value);
  event Participate(address indexed from, uint256 value);
  event Reconcile(address indexed from, uint256 period, uint256 value);


  /**
   * Modifiers
   */
   modifier onlyFunded() {
     require (funded);
     _;
   }
   modifier onlyNotFunded() {
     require (!funded);
     _;
   }
  modifier onlyOwner() {
    require (msg.sender == owner);
    _;
  }

  modifier onlyBank() {
    require (msg.sender == owner);
    _;
  }
  
  /**
   * Blitz constructor
   * Define Blitz details and contribution period
   */
  //function Blitz(uint256 _icoStart, uint256 _icoEnd, uint256 _tokensPerEth) public {
  function Blitz() public {
uint256 _icoStart = 0;
uint256 _icoEnd = 999999999;
uint256 _tokensPerEth =1;
    // require (_icoStart >= now);
    require (_icoEnd >= _icoStart);
    require (_tokensPerEth > 0);

    owner = msg.sender;

    icoStart = now + _icoStart;
    icoEnd = now + _icoEnd;
    //tokensPerEth = _tokensPerEth;
    tokensPerEth = 1; //for now
    // as a safety measure tempory set the sale address to something else than 0x0
    currentSaleAddress = owner;
  }
  /**
   *
   * Function allowing investors to participate in the Blitz Token Sale.
   * Specifying the beneficiary will change who will receive the tokens.
   * Fund tokens will be distributed based on amount of ETH sent by investor, and calculated
   * using tokensPerEth value.
   */
  function buyToken(address beneficiary) public onlyNotFunded payable {
    require (beneficiary != address(0));
    require (now >= icoStart && now <= icoEnd);
    require (msg.value > 0);
    require (msg.value + totalSupply <= hardCap);

    uint256 ethAmount = msg.value;
    uint256 numTokens = ethAmount.mul(tokensPerEth);

    require(totalSupply.add(numTokens) <= hardCap);
    if( balanceOf(beneficiary) == 0) {
      beneficiaries.push(beneficiary);
    }
    balances[beneficiary] = balances[beneficiary].add(numTokens);
    totalSupply = totalSupply.add(numTokens);

    // Our own custom event to monitor ICO participation
    Participate(beneficiary, numTokens);
    // Let ERC20 tools know of token hodlers
    Transfer(0x0, beneficiary, numTokens);

    totalAmount = totalAmount.add(ethAmount);

    owner.transfer(ethAmount);
    if(totalSupply == hardCap){
      funded = true;
    }
  //check if amount payed is valid
  //check if token still can be sold
  //then give amount of token
  //transfer amount of bought token to address
  //transfer from address to bank (not implementing now)
}

function buyToken4Me(address beneficiary) public onlyNotFunded payable {
    buyToken(msg.sender);    
}


function fundBlitz() public{
  require(totalSupply >= hardCap);
  owner.transfer(totalAmount);

  //has it met threshold value?
  //yes - nothing
  //no - transfer from bank to list of _to addresses
}

function refund() public payable onlyOwner onlyNotFunded{
  require(totalAmount == msg.value);
  for (uint256 i = 0; i < beneficiaries.length; i++) {
    uint256 payout = balances[beneficiaries[i]].div(tokensPerEth);
    balances[beneficiaries[i]] = 0;
    beneficiaries[i].transfer(payout);
  }
}

function transferToken(uint256 amount, address _to) public {
  //has msg.sender amount?
  //transfer amount to _to
  
}



function pushPayin() public payable onlyBank onlyFunded{
  require (msg.value > 0);
  distribute = distribute.add(msg.value);

  //event payin
  //check if bank
//bank transfers created revenue to our smart contract
}



function pullPayout() public onlyFunded{
  require(distribute > 0);
  uint256 distributeTmp = distribute;
  distribute=0;
  for (uint256 i = 0; i < beneficiaries.length; i++) {
    beneficiaries[i].transfer(balances[beneficiaries[i]].div(totalAmount).mul(distributeTmp));
  }
//check if shareholder
//give shareholder his share of revenue (created by pushPayin)
}


/**
 *
 * We fallback to the partcipate function
 */
function () external payable {
   buyToken(msg.sender);
}

}
