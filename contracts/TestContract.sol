// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

contract TestContract {
    address private _owner;

    constructor(address owner) {
        _owner = owner;
    }

    function getOwner() public view returns (address) {
        return _owner;
    }
}
