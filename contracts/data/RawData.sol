// SPDX-License-Identifier: GPL-3.0

pragma solidity ~0.8.17;


contract RawData {

    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
    bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    function makeCommitmentWithConfig(string memory name, bytes32 secret, address resolver) public view returns(bytes32) {
    bytes32 label = keccak256(bytes(name));
    return keccak256(abi.encodePacked(label, msg.sender, resolver, secret));
    }


   
}

