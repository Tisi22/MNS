//SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

import "../registry/PNS.sol";
import "./IBaseRegistrar.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract BaseRegistrar is ERC721, ERC721URIStorage, IBaseRegistrar, Ownable {
    // A map of expiry times
    //mapping(uint256 => uint256) domains;
    // A "mapping" data type to store their names
    mapping(uint256 => address) public domains;
    // The ENS registry
    PNS public pns;
    // The namehash of the TLD this registrar owns (eg, .eth)
    bytes32 public baseNode;
    // A map of addresses that are authorised to register and renew names.
    mapping(address => bool) public controllers;
 
    bytes4 private constant INTERFACE_META_ID =
        bytes4(keccak256("supportsInterface(bytes4)"));
    bytes4 private constant ERC721_ID =
        bytes4(
            keccak256("balanceOf(address)") ^
            keccak256("ownerOf(uint256)") ^
            keccak256("approve(address,uint256)") ^
            keccak256("getApproved(uint256)") ^
            keccak256("setApprovalForAll(address,bool)") ^
            keccak256("isApprovedForAll(address,address)") ^
            keccak256("transferFrom(address,address,uint256)") ^
            keccak256("safeTransferFrom(address,address,uint256)") ^
            keccak256("safeTransferFrom(address,address,uint256,bytes)")
        );
    bytes4 private constant RECLAIM_ID =
        bytes4(keccak256("reclaim(uint256,address)"));

    constructor(PNS _pns, bytes32 _baseNode) ERC721("", "") {
        pns = _pns;
        baseNode = _baseNode;
    }

    modifier live() {
        require(pns.owner(baseNode) == address(this));
        _;
    }

    modifier onlyController() {
        require(controllers[msg.sender]);
        _;
    }

    // Authorises a controller, who can register domains.
    function addController(address controller) external override onlyOwner {
        controllers[controller] = true;
        emit ControllerAdded(controller);
    }

    // Revoke controller permission for an address.
    function removeController(address controller) external override onlyOwner {
        controllers[controller] = false;
        emit ControllerRemoved(controller);
    }

    // Set the resolver for the TLD this registrar manages.
    function setResolver(address resolver) external override onlyOwner {
        pns.setResolver(baseNode, resolver);
    }

    // Returns true iff the specified name is available for registration.
    function available(uint256 id) public view returns (bool) {
        require(domains[id] == address(0), "Domain already exists");
        return true;
    }

    function register(
        uint256 id,
        address owner,
        string memory finalTokenURI
    ) external {
         _register(id, owner, finalTokenURI, true);
    }

    function _register(uint256 id, address owner, string memory finalTokenURI, bool updateRegistry) internal live onlyController{
        require(available(id));

        domains[id] = owner;

        _safeMint(msg.sender, id);
        _setTokenURI(id, finalTokenURI);

        if (updateRegistry) {
            pns.setSubnodeOwner(baseNode, bytes32(id), owner);
        }

        emit NameRegistered(id, owner);

    }

    /**
     * @dev Reclaim ownership of a name in PNS, if you own it in the registrar.
     */
    function reclaim(uint256 id, address owner) public override live {
        require(_isApprovedOrOwner(msg.sender, id));
        pns.setSubnodeOwner(baseNode, bytes32(id), owner);
    }


    /**
     * @dev Override function from ERC721
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override (ERC721, IERC721) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        reclaim(tokenId, to);
        _safeTransfer(from, to, tokenId, data);
    }

    function supportsInterface(bytes4 interfaceID)
        public
        view
        override(ERC721, IERC165)
        returns (bool)
    {
        return
            interfaceID == INTERFACE_META_ID ||
            interfaceID == ERC721_ID ||
            interfaceID == RECLAIM_ID;
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}
