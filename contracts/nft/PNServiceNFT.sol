// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PNServiceNFT is ERC721, Ownable {

    //Public mint state
    bool public mintActive = false;
    //Token ID
    uint256 tokenID;
    //URI
    string uri;

    mapping(address => bool) public controllers;

    event ControllerAdded(address indexed controller);
    event ControllerRemoved(address indexed controller);

    modifier onlyController() {
        require(controllers[msg.sender]);
        _;
    }

    
    constructor() ERC721("Polygon name Service", "PNS") {}

    //-----CONTROLLERS-----//

    /**
    * @dev Authorises a controller, who can mint the NFT.
    */
    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
        emit ControllerAdded(controller);
    }

    /**
    * @dev Revoke controller permission for an address.
    */
    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
        emit ControllerRemoved(controller);
    }

    //-----END-----//

    //----SET VARIABLES----//

    /**
    * @dev Sets public mint state.
    */
    function setMintState(bool val) external onlyOwner {
        mintActive = val;
    }

    /**
    * @dev Sets URI.
    */
    function setUri(string memory _uri) external onlyOwner {
        uri = _uri;
    }

    //-----END-----//

    //-----MINT-----//

    /**
    * @dev Mints the NFT.
    */
    function mintNFT(address to) public onlyController{
 
        require(
            mintActive,
            "Minting paused"
        );

        //Increment token ID
        tokenID++;

        //Mint the NFT and send to the sender
        _safeMint(to, (tokenID-1));

    }

    //-----END-----//

    //-----OVERRIDE FUNCTIONS-----//

    function _baseURI() internal view virtual override returns (string memory) {
        return uri;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? baseURI : "";
    }

    // Block token transfers
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId, /* firstTokenId */
        uint256 batchSize
    ) internal virtual override{
    require(from == address(0), "Err: token transfer is BLOCKED");   
    super._beforeTokenTransfer(from, to, tokenId, batchSize);  
    }
    //-----END-----//
}