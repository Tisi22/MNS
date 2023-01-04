//SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import { StringUtils } from "../libraries/StringUtils.sol";
import { Price } from "../libraries/Price.sol";
import {BaseRegistrar} from "./BaseRegistrar.sol";


contract PoligonRegistrarCOntroller is Ownable {

  bytes4 constant private INTERFACE_META_ID = bytes4(keccak256("supportsInterface(bytes4)"));
  bytes4 constant private COMMITMENT_CONTROLLER_ID = bytes4(
    keccak256("available(string)") ^
    keccak256("makeCommitmentWithConfig(string,address,bytes32, address)") ^
    keccak256("commit(bytes32)") ^
    keccak256("registerDomain(string,bytes32,address)")
  );


  string public tld;

  BaseRegistrar base;

  Price price;

  string svgPartOne = '<svg xmlns="http://www.w3.org/2000/svg" width="270" height="270" fill="none"><path fill="url(#B)" d="M0 0h270v270H0z"/><defs><filter id="A" color-interpolation-filters="sRGB" filterUnits="userSpaceOnUse" height="270" width="270"><feDropShadow dx="0" dy="1" stdDeviation="2" flood-opacity=".225" width="200%" height="200%"/></filter></defs><path d="M72.863 42.949c-.668-.387-1.426-.59-2.197-.59s-1.529.204-2.197.59l-10.081 6.032-6.85 3.934-10.081 6.032c-.668.387-1.426.59-2.197.59s-1.529-.204-2.197-.59l-8.013-4.721a4.52 4.52 0 0 1-1.589-1.616c-.384-.665-.594-1.418-.608-2.187v-9.31c-.013-.775.185-1.538.572-2.208a4.25 4.25 0 0 1 1.625-1.595l7.884-4.59c.668-.387 1.426-.59 2.197-.59s1.529.204 2.197.59l7.884 4.59a4.52 4.52 0 0 1 1.589 1.616c.384.665.594 1.418.608 2.187v6.032l6.85-4.065v-6.032c.013-.775-.185-1.538-.572-2.208a4.25 4.25 0 0 0-1.625-1.595L41.456 24.59c-.668-.387-1.426-.59-2.197-.59s-1.529.204-2.197.59l-14.864 8.655a4.25 4.25 0 0 0-1.625 1.595c-.387.67-.585 1.434-.572 2.208v17.441c-.013.775.185 1.538.572 2.208a4.25 4.25 0 0 0 1.625 1.595l14.864 8.655c.668.387 1.426.59 2.197.59s1.529-.204 2.197-.59l10.081-5.901 6.85-4.065 10.081-5.901c.668-.387 1.426-.59 2.197-.59s1.529.204 2.197.59l7.884 4.59a4.52 4.52 0 0 1 1.589 1.616c.384.665.594 1.418.608 2.187v9.311c.013.775-.185 1.538-.572 2.208a4.25 4.25 0 0 1-1.625 1.595l-7.884 4.721c-.668.387-1.426.59-2.197.59s-1.529-.204-2.197-.59l-7.884-4.59a4.52 4.52 0 0 1-1.589-1.616c-.385-.665-.594-1.418-.608-2.187v-6.032l-6.85 4.065v6.032c-.013.775.185 1.538.572 2.208a4.25 4.25 0 0 0 1.625 1.595l14.864 8.655c.668.387 1.426.59 2.197.59s1.529-.204 2.197-.59l14.864-8.655c.657-.394 1.204-.95 1.589-1.616s.594-1.418.609-2.187V55.538c.013-.775-.185-1.538-.572-2.208a4.25 4.25 0 0 0-1.625-1.595l-14.993-8.786z" fill="#fff"/><defs><linearGradient id="B" x1="0" y1="0" x2="270" y2="270" gradientUnits="userSpaceOnUse"><stop stop-color="#cb5eee"/><stop offset="1" stop-color="#0cd7e4" stop-opacity=".99"/></linearGradient></defs><text x="32.5" y="231" font-size="27" fill="#fff" filter="url(#A)" font-family="Plus Jakarta Sans,DejaVu Sans,Noto Color Emoji,Apple Color Emoji,sans-serif" font-weight="bold">';
  string svgPartTwo = '</text></svg>';

  mapping(bytes32 => uint256) public commitments;

  uint public maxCommitmentAge;
  uint public minCommitmentAge;

  error UnexpiredCommitmentExists(bytes32 commitment);

  event NameRegistered(string name, bytes32 indexed label, address indexed owner, uint cost);

  constructor(BaseRegistrar _base, Price _price, string memory _tld, uint _maxCommitmentAge, uint _minCommitmentAge){
    require(_maxCommitmentAge > _minCommitmentAge);

    price = _price;
    maxCommitmentAge = _maxCommitmentAge;
    minCommitmentAge = _minCommitmentAge;
    base = _base;
    tld = _tld;
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

  function makeCommitmentWithConfig(string memory name, address owner, bytes32 secret, address resolver) pure private returns(bytes32) {
    bytes32 label = keccak256(bytes(name));
    return keccak256(abi.encodePacked(label, owner, resolver, secret));
  }

  // A register function that adds their names to our mapping
  function registerDomain(string memory name, bytes32 secret, address resolver) public payable {
    require(resolver != address(0), "Need a resolver contract");

    bytes32 commitment = makeCommitmentWithConfig(name, msg.sender, secret, resolver);
    uint cost = _consumeCommitment(name, commitment);

    // Combine the name passed into the function  with the TLD
    string memory _name = string(abi.encodePacked(name, ".", tld));
    // Create the SVG (image) for the NFT with the name
    string memory finalSvg = string(abi.encodePacked(svgPartOne, _name, svgPartTwo));
    bytes32 label = keccak256(bytes(name));
    uint256 tokenId = uint256(label);
    uint256 length = StringUtils.strlen(name);
    string memory strLen = Strings.toString(length);

    // Create the JSON metadata of our NFT. We do this by combining strings and encoding as base64
    string memory json = Base64.encode(
      abi.encodePacked(
        '{"name": "',
        _name,
        '", "description": "A domain on Polygon Name Service", "image": "data:image/svg+xml;base64,',
        Base64.encode(bytes(finalSvg)),
        '","length":"',
        strLen,
        '"}'
      )
    );

    string memory finalTokenUri = string( abi.encodePacked("data:application/json;base64,", json));

    base.register(tokenId, address(this), finalTokenUri);

    // The nodehash of this label
    bytes32 nodehash = keccak256(abi.encodePacked(base.baseNode(), label));

    // Set the resolver
    base.pns().setResolver(nodehash, resolver);

    base.reclaim(tokenId, msg.sender);
    base.transferFrom(address(this), msg.sender, tokenId);

    //emit NameRegistered(name, label, msg.sender, cost);

  }

  function available(string memory name) public view returns(bool) {
    bytes32 label = keccak256(bytes(name));
    return base.available(uint256(label));
  }

  
  function _consumeCommitment(string memory name, bytes32 commitment) internal returns (uint256) {
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