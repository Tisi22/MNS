//SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

import { StringUtils } from "./StringUtils.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract Price is Ownable{

    uint256 public len3Price;
    uint256 public len4Price;
    uint256 public len5Price;

    uint8 decimals;

    constructor(uint256 _len3Price, uint256 _len4Price, uint256 _len5Price){
        len3Price = _len3Price;
        len4Price = _len4Price;
        len5Price = _len5Price;
        decimals = 18;
    }

    function setUpNewPrice(uint256 _len3Price, uint256 _len4Price, uint256 _len5Price) public onlyOwner{
        len3Price = _len3Price;
        len4Price = _len4Price;
        len5Price = _len5Price;
    }

    function setUpDecimals(uint8 _decimals) public onlyOwner {
        decimals = _decimals;
    }

  
    function price(string calldata name) public view returns(uint) {
        uint len = StringUtils.strlen(name);
        require(len >= 3, "The length cannot be 0");
        if (len == 3) {
            return len3Price * 10**decimals; 
        } 
        else if (len == 4) {
            return len4Price * 10**decimals; 
        } 
        else {
        return len5Price * 10**decimals;
        }
    } 

  
}