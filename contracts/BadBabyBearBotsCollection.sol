// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./ERC721Base.sol";

contract BadBabyBearBotsCollection is ERC721Base, ReentrancyGuard {
  using Strings for uint256;
  using SafeMath for uint256;

  // ============ Constants ============

  //maximum amount that can be purchased per wallet
  uint8 public constant MAX_PURCHASE = 5;
  //start date of the token sale
  //April 1, 2022 12AM GTM
  uint64 public constant SALE_DATE = 1648771200;
  //the sale price per token
  uint256 public constant SALE_PRICE = 0.08 ether;
  //the amount of tokens to reserve
  uint16 public constant RESERVED = 30;
  //the provenance hash (the CID)
  string public PROVENANCE;
  //the offset to be used to determine what token id should get which CID
  uint16 public indexOffset;
  //the contract address of the DAO
  address public immutable DAO;
  //the contract address of the BBBB multisig wallet
  address public immutable BBBB;

  // ============ Deploy ============

  /**
   * @dev Sets up ERC721Base. Permanently sets the IPFS CID
   */
  constructor(
    string memory uri, 
    string memory cid, 
    address dao, 
    address bbbb
  ) ERC721Base(
    //name
    "Bad Baby Bear Bots",
    //symbol 
    "BBBB",
    //max supply
    10000
  ) {
    //save DAO address. now it's immutable
    DAO = dao;
    //save BBBB address. now it's immutable
    BBBB = bbbb;
    //make cid immutable
    PROVENANCE = cid;
    //set the initial base uri
    _setBaseURI(uri);

    //reserve bears
    _safeMint(_msgSender(), 30);
  }

  // ============ Read Methods ============

  /**
   * @dev The URI for contract data ex. https://creatures-api.opensea.io/contract/opensea-creatures
   * Example Format:
   * {
   *   "name": "OpenSea Creatures",
   *   "description": "OpenSea Creatures are adorable aquatic beings primarily for demonstrating what can be done using the OpenSea platform. Adopt one today to try out all the OpenSea buying, selling, and bidding feature set.",
   *   "image": "https://openseacreatures.io/image.png",
   *   "external_link": "https://openseacreatures.io",
   *   "seller_fee_basis_points": 100, # Indicates a 1% seller fee.
   *   "fee_recipient": "0xA97F337c39cccE66adfeCB2BF99C1DdC54C2D721" # Where seller fees will be paid to.
   * }
   */
  function contractURI() public view returns(string memory) {
    //ex. https://ipfs.io/ipfs/ + Qm123abc + /contract.json
    return string(
      abi.encodePacked(baseTokenURI(), PROVENANCE, "/contract.json")
    );
  }

  /**
   * @dev Combines the base token URI and the token CID to form a full 
   * token URI
   */
  function tokenURI(uint256 tokenId) 
    public view virtual override returns(string memory) 
  {
    require(_exists(tokenId), "URI query for nonexistent token");

    //if no offset
    if (indexOffset == 0) {
      //use the placeholder
      return string(
        abi.encodePacked(baseTokenURI(), PROVENANCE, "/placeholder.json")
      );
    }

    //for example, given offset is 2 and size is 8:
    // - token 5 = ((5 + 2) % 8) + 1 = 8
    // - token 6 = ((6 + 2) % 8) + 1 = 1
    // - token 7 = ((7 + 2) % 8) + 1 = 2
    // - token 8 = ((8 + 2) % 8) + 1 = 3
    uint256 index = tokenId.add(indexOffset).mod(MAX_SUPPLY).add(1);
    //ex. https://ipfs.io/ + Qm123abc + / + 1000 + .json
    return string(
      abi.encodePacked(baseTokenURI(), PROVENANCE, "/", index.toString(), ".json")
    );
  }

  // ============ Minting Methods ============

  /**
   * @dev Creates a new token for the sender. Its token ID will be 
   * automatically assigned (and available on the emitted 
   * {IERC721-Transfer} event), and the token URI autogenerated based 
   * on the base URI passed at construction.
   */
  function mint(uint256 quantity) external payable nonReentrant {
    //has the sale started?
    require(uint64(block.timestamp) >= SALE_DATE, "Sale has not started");
    //get the recipient
    address recipient = _msgSender();
    //make sure recipient is a valid address
    require(recipient != address(0), "Invalid recipient");
    //fix for valid quantity
    if (quantity == 0) {
      quantity = 1;
    }

    //the quantity here plus the current balance 
    //should be less than the max purchase amount
    require(
      quantity.add(balanceOf(recipient)) <= MAX_PURCHASE, 
      "Cannot mint more than allowed"
    );
    //the value sent should be the price times quantity
    require(
      quantity.mul(SALE_PRICE) <= msg.value, 
      "Amount sent is not correct"
    );
    //the quantity being minted should not 
    //exceed the max supply less the reserve
    require(
      totalSupply().add(quantity) <= MAX_SUPPLY, 
      "Amount exceeds total allowable collection"
    );

    _safeMint(recipient, quantity);
  }

  /**
   * @dev Allows the proceeds to be withdrawn to the DAO and BBBB
   */
  function withdraw() external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
    //set the offset
    if (indexOffset == 0) {
      indexOffset = uint16(block.number - 1) % MAX_SUPPLY;
      if (indexOffset == 0) {
        indexOffset = 1;
      }
    }

    //DAO gets 50%
    payable(DAO).transfer(address(this).balance.div(2));
    //rest goes to BBBB
    payable(BBBB).transfer(address(this).balance);
  }

  // ============ Metadata Methods ============

  /**
   * @dev Since we are using IPFS CID for the token URI, we can allow 
   * the changing of the base URI to toggle between services for faster 
   * speeds while keeping the metadata provably fair
   */
  function setBaseURI(string memory uri) 
    external virtual onlyRole(CURATOR_ROLE) 
  {
    _setBaseURI(uri);
  }
}