// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NoteFromMom is ERC721, Ownable {

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

    // Authorises a controller, who can register domains.
    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
        emit ControllerAdded(controller);
    }

    // Revoke controller permission for an address.
    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
        emit ControllerRemoved(controller);
    }

    //-----END-----//

    //----SET VARIABLES----//

    //Sets public mint state
    function setMintState(bool val) external onlyOwner {
        mintActive = val;
    }

    function setUri(string memory _uri) external onlyOwner {
        uri = _uri;
    }

    //-----END-----//

    //-----MINT-----//

    function mintNFT() public onlyController{
 
        require(
            mintActive,
            "Minting paused"
        );

        //Increment token ID
        tokenID++;

        //Mint the NFT and send to the sender
        _safeMint(msg.sender, (tokenID-1));

    }

    //-----END-----//

    //-----OVERRIDE FUNCTIONS-----//


    function _baseURI() internal view virtual override returns (string memory) {
        return uri;
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