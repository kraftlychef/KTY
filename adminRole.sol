pragma solidity ^0.5.5;

import "./roles.sol";
import "./context.sol";
// import "./safeMath.sol";


contract AdminRole is Context{

    using Admins for Admins.Role;

    event AdminAdded(address indexed account);
    event AdminRemoved(address indexed account);
    event OwnershipTransfer(address indexed account);

    Admins.Role private _admins;
    address private ownerAddr;
    bool public currentState;


    constructor () internal {
        _addAdmin(_msgSender());
        _changeOwner(_msgSender());
        currentState = true;
    }

    modifier onlyOwner() {
        require(_msgSender() == Owner(),"AdminRole: caller is not owner");
        _;
      }

    modifier onlyAdmin() {
        require(isAdmin(_msgSender()) || _msgSender() == Owner(),"AdminRole: caller does not have the Admin role");
        _;
    }
    modifier isNotPaused() {
        require(currentState,"ContractAdmin : paused contract for action");
        _;
    }

    function changeState(bool _state) public onlyAdmin returns(bool){
        require(_state != currentState,"ContractAdmin : same state");
        currentState = _state;
        return _state;
    }

    function Owner() public view returns (address) {
        return ownerAddr;
    }

    function changeOwner(address account) external onlyOwner {
      _changeOwner(account);
    }

    function _changeOwner(address account)internal{
      require(account != address(0) && account != ownerAddr ,"AdminRole: Address is Owner or zero address");
       ownerAddr = account;
       emit OwnershipTransfer(account);
    }


    function isAdmin(address account) public view returns (bool) {
        return _admins.has(account);
    }

    function addAdmin(address account) public onlyAdmin {

        _addAdmin(account);
    }
    function removeAdmin(address account) public onlyAdmin {
        _removeAdmin(account);
    }

    function renounceAdmin() public{
        _removeAdmin(_msgSender());
    }

    function _addAdmin(address account) internal {
        _admins.add(account);
        emit AdminAdded(account);
    }

    function _removeAdmin(address account) internal {
        _admins.remove(account);
        emit AdminRemoved(account);
    }
}





contract BlockRole is Context,AdminRole{

  using blocks for blocks.Role;

  event BlockAdded(address indexed account);
  event BlockRemoved(address indexed account);

  blocks.Role private _blockedUser;


  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  constructor () internal { }

    modifier isNotBlackListed(address account){
       require(!getBlackListStatus(account),"ContractAdmin : Address restricted");
        _;
    }
    modifier callerNotBlackListed(){
       require(!getBlackListStatus(_msgSender()),"ContractAdmin : Address restricted");
        _;
    }

    function addBlackList(address account) public onlyAdmin {
      _addBlackList(account);
    }

    function removeBlackList(address account) public onlyAdmin {
      _removeBlackList(account);
    }

    function getBlackListStatus(address account) public view returns (bool) {
      return _blockedUser.has(account);
    }

    function _addBlackList(address account) internal {
      _blockedUser.add(account);
      emit BlockAdded(account);
    }

    function _removeBlackList(address account) internal {
      _blockedUser.remove(account);
      emit BlockRemoved(account);

    }

}


contract FundController is Context,AdminRole{

constructor() internal {}

  /*
  * @title claimTRX
  * @dev it can let admin withdraw trx from contract
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  */
  function claimTRX(address payable to, uint256 value)
  external
  onlyAdmin
  returns (bool)
  {
    require(address(this).balance >= value, "FundController: insufficient balance");

    (bool success, ) = to.call.value(value)("");
    require(success, "FundController: unable to send value, accepter may have reverted");
    return true;
  }
  /*
  * @title claimTRC10
  * @dev it can let admin withdraw any trc10 from contract
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  * @param token The tokenId of token to be transferred.

  */
   function claimTRC10(address payable to, uint256 value, uint256 token)
   external
   onlyAdmin
   returns (bool)
  {
    require(value <=  address(this).tokenBalance(token), "FundController: Not enought Token Available");
    to.transferToken(value, token);
    return true;
  }
  /*
  * @title claimTRC20
  * @dev it can let admin withdraw any trc20 from contract
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  * @param token The contract address of token to be transferred.

  */
  function claimTRC20(address to, uint256 value, address token)
  external
  onlyAdmin
  returns (bool)
  {
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
    bool result = success && (data.length == 0 || abi.decode(data, (bool)));
    require(result, "FundController: unable to transfer value, recipient or token may have reverted");
    return true;
  }

    //Fallback
    function() external payable { }

    function kill() public onlyOwner {
      selfdestruct(_msgSender());
    }

}
contract AdminControl is AdminRole,BlockRole,FundController{
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.

  constructor () internal { }

}
