//SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import { StringUtils } from "../libraries/StringUtils.sol";
import { Price } from "../data/Price.sol";
import {BaseRegistrar} from "./BaseRegistrar.sol";
import {Metadata} from "../data/Metadata.sol";


contract PolygonRegistrarController is Ownable {

  bytes4 constant private INTERFACE_META_ID = bytes4(keccak256("supportsInterface(bytes4)"));
  bytes4 constant private COMMITMENT_CONTROLLER_ID = bytes4(
    keccak256("available(string)") ^
    keccak256("makeCommitmentWithConfig(string,address,bytes32, address)") ^
    keccak256("commit(bytes32)") ^
    keccak256("registerDomain(string,bytes32,address)")
  );

  BaseRegistrar base;

  Price price;

  Metadata metadata;

  mapping(bytes32 => uint256) public commitments;

  uint public maxCommitmentAge;
  uint public minCommitmentAge;

  error UnexpiredCommitmentExists(bytes32 commitment);

  event NameRegistered(string name, bytes32 indexed label, address indexed owner, uint cost);

  constructor(BaseRegistrar _base, Price _price, Metadata _metadata, uint _maxCommitmentAge, uint _minCommitmentAge){
    require(_maxCommitmentAge > _minCommitmentAge);

    price = _price;
    maxCommitmentAge = _maxCommitmentAge;
    minCommitmentAge = _minCommitmentAge;
    base = _base;
    metadata = _metadata;
  }

  /**
  * @dev Check and set commintment for a domain.
  * @param commitment The domain to set and check.
  */
  function commit(bytes32 commitment) public {
        if (commitments[commitment] + maxCommitmentAge >= block.timestamp) {
            revert UnexpiredCommitmentExists(commitment);
        }
        commitments[commitment] = block.timestamp;
  }

  function makeCommitmentWithConfig(string memory name, bytes32 secret, address resolver) public view returns(bytes32) {
    bytes32 label = keccak256(bytes(name));
    return keccak256(abi.encodePacked(label, msg.sender, resolver, secret));
  }

  // A register function that adds their names to our mapping
  function registerDomain(string memory name, bytes32 secret, address resolver) public payable {
    require(resolver != address(0), "Need a resolver contract");

    bytes32 commitment = makeCommitmentWithConfig(name, secret, resolver);
    uint256 cost =  _consumeCommitment(name, commitment);

    bytes32 label = keccak256(bytes(name));
    uint256 tokenId = uint256(label);

    base.register(tokenId, address(this), metadata.URI(name));

    // The nodehash of this label
    bytes32 nodehash = keccak256(abi.encodePacked(base.baseNode(), label));

    // Set the resolver
    base.pns().setResolver(nodehash, resolver);
    Resolver(resolver).setAddr(nodehash, msg.sender);

    base.reclaim(tokenId, msg.sender);
    base.transferFrom(address(this), msg.sender, tokenId);

    emit NameRegistered(name, label, msg.sender, cost);

  }

  function available(string memory name) public view returns(bool) {
    bytes32 label = keccak256(bytes(name));
    return base.available(uint256(label));
  }

  
  function _consumeCommitment(string memory name, bytes32 commitment) internal returns(uint256){
    // Require a valid commitment
    require(commitments[commitment] + minCommitmentAge <= block.timestamp);

    // If the commitment is too old, or the name is registered, stop
    require(commitments[commitment] + maxCommitmentAge > block.timestamp);
    require(available(name));

    delete(commitments[commitment]);

    uint cost = price.price(name);
    require(msg.value >= cost, "Not enough Matic sent");

    return cost;

  }

  function setCommitmentAges(uint _minCommitmentAge, uint _maxCommitmentAge) public onlyOwner {
    minCommitmentAge = _minCommitmentAge;
    maxCommitmentAge = _maxCommitmentAge;
  }

  function withdraw() public onlyOwner  {
        uint256 amount = address(this).balance;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }

  function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
    return interfaceID == INTERFACE_META_ID ||
           interfaceID == COMMITMENT_CONTROLLER_ID;
  }


}