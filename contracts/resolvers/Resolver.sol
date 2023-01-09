//SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

import "../registry/PNS.sol";

contract Resolver {

    modifier authorised(bytes32 node) {
        require(isAuthorised(node));
        _;
    }

    mapping(bytes32 => address) public nodeAddress;

    mapping(address => mapping(address => bool)) private _operatorApprovals;

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    PNS immutable pns;
    address immutable trustedPolygonRegistrarController;

    constructor(PNS _pns, address _trustedPolygonRegistrarController) {
        pns = _pns;
        trustedPolygonRegistrarController = _trustedPolygonRegistrarController;
    }

    function supportsInterface(bytes4 interfaceID) public pure returns (bool) {
        return interfaceID == 0x3b3b57de;
    }

    function setAddr(bytes32 node, address _addr) public authorised(node) {
        nodeAddress[node] = _addr;
    }

    function addr(bytes32 nodeID) public view returns (address _addr) {
        return nodeAddress[nodeID];
    }

    
    function setApprovalForAll(address operator, bool approved) external {
        require(
            msg.sender != operator,
            "ERC1155: setting approval status for self"
        );

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

   
    function isApprovedForAll(address account, address operator)
        public
        view
        returns (bool)
    {
        return _operatorApprovals[account][operator];
    }

    function isAuthorised(bytes32 node) public view returns (bool) {
        if (
            msg.sender == trustedPolygonRegistrarController
        ) {
            return true;
        }
        address owner = pns.owner(node);
        return owner == msg.sender || isApprovedForAll(owner, msg.sender);
    }
}

