// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SimpleStorage {
    uint256 private storedNumber;
    string private storedMessage;
    address public owner;
    
    event NumberChanged(uint256 indexed oldNumber, uint256 indexed newNumber, address indexed changer);
    event MessageChanged(string oldMessage, string newMessage, address indexed changer);
    
    constructor(uint256 _initialNumber) {
        storedNumber = _initialNumber;
        storedMessage = "Hello, Orbit Chain!";
        owner = msg.sender;
    }
    
    function getNumber() public view returns (uint256) {
        return storedNumber;
    }
    
    function setNumber(uint256 _number) public {
        uint256 oldNumber = storedNumber;
        storedNumber = _number;
        emit NumberChanged(oldNumber, _number, msg.sender);
    }
    
    function getMessage() public view returns (string memory) {
        return storedMessage;
    }
    
    function setMessage(string memory _message) public {
        string memory oldMessage = storedMessage;
        storedMessage = _message;
        emit MessageChanged(oldMessage, _message, msg.sender);
    }
    
    function getInfo() public view returns (
        uint256 number,
        string memory message,
        address contractOwner,
        uint256 blockNumber,
        uint256 chainId
    ) {
        return (
            storedNumber,
            storedMessage,
            owner,
            block.number,
            block.chainid
        );
    }
} 