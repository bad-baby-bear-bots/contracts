// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "erc721b/contracts/ERC721B.sol";
import "erc721b/contracts/extensions/ERC721BURIBase.sol";
import "erc721b/contracts/extensions/ERC721BBurnable.sol";
import "erc721b/contracts/extensions/ERC721BPausable.sol";

import "./BEP721/BEP721.sol";

abstract contract ERC721Base is
  Context,
  Ownable,
  AccessControlEnumerable,
  ERC721BBurnable,
  ERC721BPausable,
  ERC721BURIBase,
  BEP721
{
  // ============ Constants ============

  //all possible roles
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant CURATOR_ROLE = keccak256("CURATOR_ROLE");
  // bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
  bytes4 internal constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
  //max amount that can be minted in this collection
  uint16 public immutable MAX_SUPPLY;

  // ============ Internal Methods ============

  /**
   * @dev Grants `DEFAULT_ADMIN_ROLE` and `PAUSER_ROLE` to the
   * account that deploys the contract. Sets the contract's URI. 
   */
  constructor(
    string memory name_, 
    string memory symbol_, 
    uint16 maxSupply_
  ) ERC721B(name_, symbol_) {
    //provenance data
    MAX_SUPPLY = maxSupply_;
    //roles and permissions
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(PAUSER_ROLE, _msgSender());
    _setupRole(MINTER_ROLE, _msgSender());
    _setupRole(CURATOR_ROLE, _msgSender());
  }

  // ============ Read Methods ============
  
  /**
   * @dev Describes linear override for `supportsInterface` used in 
   * both `AccessControlEnumerable`, `ERC721B` and `IERC165`
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(AccessControlEnumerable, ERC721B, IERC165)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  // ============ Write Methods ============

  /**
   * @dev Pauses all token transfers.
   */
  function pause() public virtual onlyRole(PAUSER_ROLE) {
    _pause();
  }

  /**
   * @dev Unpauses all token transfers.
   */
  function unpause() public virtual onlyRole(PAUSER_ROLE) {
    _unpause();
  }

  // ============ Internal Methods ============
  
  /**
   * @dev Describes linear override for `_baseURI` used in 
   * both `ERC721B` and `ERC721BURIBase`
   */
  function _baseURI() 
    internal 
    view 
    virtual 
    override(ERC721B, ERC721BURIBase) 
    returns(string memory)
  {
    return super._baseURI();
  }

  /**
   * @dev Describes linear override for `_beforeTokenTransfer` used in 
   * both `ERC721B` and `ERC721BPausable`
   */
  function _beforeTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual override(ERC721B, ERC721BPausable) {
    super._beforeTokenTransfers(from, to, startTokenId, quantity);
  }
}
