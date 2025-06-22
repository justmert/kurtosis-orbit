// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SimpleStorage {
    uint256 private storedValue;
    address public owner;
    
    event ValueChanged(uint256 oldValue, uint256 newValue, address indexed changer);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    constructor(uint256 _initialValue) {
        storedValue = _initialValue;
        owner = msg.sender;
    }
    
    function setValue(uint256 _newValue) public {
        uint256 oldValue = storedValue;
        storedValue = _newValue;
        emit ValueChanged(oldValue, _newValue, msg.sender);
    }
    
    function getValue() public view returns (uint256) {
        return storedValue;
    }
    
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "New owner cannot be zero address");
        owner = _newOwner;
    }
}