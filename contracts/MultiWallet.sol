//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract MultiWallet {
    address payable owner;

    mapping(address => uint) public allowance;
    mapping(address => bool) public isAllowedToSend;

    mapping(address => bool) public member;
    address payable nextOwner;
    uint memberResetCount;
    uint public constant confirmationsFromMembersForReset = 2;

    constructor() {
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    function proposeNewOwner(address payable newOwner) public {
        require(member[msg.sender], "You are not a member");
        if (nextOwner != newOwner) {
            nextOwner = newOwner;
            memberResetCount = 0;
        }

        memberResetCount++;

        if (memberResetCount >= confirmationsFromMembersForReset) {
            owner = nextOwner;
            nextOwner = payable(address(0));
        }
    }

    function setAllowance(address _from, uint _amount) public onlyOwner {
        allowance[_from] = _amount;
        isAllowedToSend[_from] = true;
    }

    function denySending(address _from) public onlyOwner {
        isAllowedToSend[_from] = false;
    }

    function transfer(
        address payable _to,
        uint _amount,
        bytes memory payload
    ) public returns (bytes memory) {
        require(
            _amount <= address(this).balance,
            "Can't send more than the contract owns"
        );
        if (msg.sender != owner) {
            require(
                isAllowedToSend[msg.sender],
                "You are no permission to send any transactions"
            );
            require(
                allowance[msg.sender] >= _amount,
                "You are trying to send more than you are allowed to"
            );
            allowance[msg.sender] -= _amount;
        }

        (bool success, bytes memory returnData) = _to.call{value: _amount}(
            payload
        );
        require(success, "Transaction failed");
        return returnData;
    }

    receive() external payable {}
}
