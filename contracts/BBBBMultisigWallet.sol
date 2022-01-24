// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract BBBBMultisigWallet is 
  Context, 
  Pausable, 
  AccessControlEnumerable, 
  ReentrancyGuard 
{
  //custom roles
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
  bytes32 public constant APPROVER_ROLE = keccak256("APPROVER_ROLE");
  bytes32 public constant REQUESTER_ROLE = keccak256("REQUESTER_ROLE");

  //approval structure
  struct Approval {
    //max amount that can be approved
    uint256 max;
    //required approvals
    uint8 required;
    //cooldown between requests
    uint64 cooldown;
    //the next date we can make a request
    uint64 next;
  }

  //transaction structure
  struct TX {
    uint8 tier;
    address beneficiary;
    uint256 amount;
    uint256 approvals;
    bool withdrawn;
    mapping(address => bool) approved;
  }

  //mapping of tier to approval
  mapping(uint8 => Approval) public approvalTiers;

  //mapping of id to tx
  mapping(uint256 => TX) public txs;

  /**
   * @dev Sets up roles and sets the BUSD contract address 
   */
  constructor() payable {
    //setup roles
    address sender = _msgSender();
    _setupRole(PAUSER_ROLE, sender);
    _setupRole(REQUESTER_ROLE, sender);
    _setupRole(DEFAULT_ADMIN_ROLE, sender);
    //hard code tiers
    //0.05 ETH - 1 approver - 1 day
    approvalTiers[1] = Approval(0.05 ether, 1, 86400, 0);
    //0.50 ETH - 2 approvers - 3 days
    approvalTiers[2] = Approval(0.5 ether, 2, 259200, 0);
    //5.00 ETH - 3 approvers - 7 days
    approvalTiers[3] = Approval(5 ether, 3, 604800, 0);
    //20.0 ETH - 4 approvers - 30 days
    approvalTiers[4] = Approval(20 ether, 4, 2592000, 0);
  }

  /**
   * @dev Approves a transaction
   */
  function approve(uint256 id) public virtual onlyRole(APPROVER_ROLE) {
    require(!paused(), "Approving is paused");
    //check if tx exists
    require(txs[id].amount > 0, "Transaction does not exist");
    //check if tx exists
    require(!txs[id].withdrawn, "Transaction already withdrawn");
    //require approver didnt already approve
    require(!txs[id].approved[_msgSender()], "Sender has already approved");
    //add to the approval
    txs[id].approvals += 1; 
    txs[id].approved[_msgSender()] = true;
  }

  /**
   * @dev Determine the tier of a given amount
   */
  function tier(uint256 amount) public view virtual returns(uint8) {
    for (uint8 i = 1; i <= 4; i++) {
      //if amount is less than the max tier
      if (amount < approvalTiers[i].max) {
        return 1;
      }
    }

    return 0;
  }

  /**
   * @dev Returns true if tx is approved
   */
  function isApproved(uint256 id) public view returns(bool) {
    return txs[id].approvals >= approvalTiers[txs[id].tier].required;
  }

  /**
   * @dev Pauses all token transfers.
   */
  function pause() public virtual onlyRole(PAUSER_ROLE) {
    _pause();
  }

  /**
   * @dev Makes a transaction request
   */
  function request(
    uint256 id, 
    address beneficiary, 
    uint256 amount
  ) public virtual onlyRole(REQUESTER_ROLE) {
    //check paused
    require(!paused(), "Requesting is paused");
    //check to see if tx exists
    require(txs[id].amount == 0, "Transaction exists");
    //what tier level is this?
    uint8 level = tier(amount);
    //check to see if a tier is found
    require(approvalTiers[level].max > 0, "Request amount is too large");
    //get the time now
    uint64 timenow = uint64(block.timestamp);
    //the time should be greater than the last approved plus the cooldown
    require(timenow >= approvalTiers[level].next, "Tiered amount on cooldown");

    //create a new tx
    txs[id].tier = level;
    txs[id].amount = amount;
    txs[id].beneficiary = beneficiary;
    //if this sender is also an approver
    if (hasRole(APPROVER_ROLE, _msgSender())) {
      //then approve it
      approve(id);
    }

    //update the next time they can make a request
    approvalTiers[level].next = timenow + approvalTiers[level].cooldown;
  }

  /**
   * @dev Unpauses all token transfers.
   */
  function unpause() public virtual onlyRole(PAUSER_ROLE) {
    _unpause();
  }

  /**
   * @dev Allows transactions to be withdrawn
   */
  function withdraw(uint256 id) external nonReentrant {
    require(txs[id].amount > 0, "Funds do not exist");
    require(!txs[id].withdrawn, "Funds are already withdrawn");
    require(isApproved(id), "Request is not approved");

    //go ahead and transfer it
    txs[id].withdrawn = true;
    Address.sendValue(payable(txs[id].beneficiary), txs[id].amount);
  }
}