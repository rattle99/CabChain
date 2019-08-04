pragma solidity ^0.5.8;

contract Ownable {
        address public owner;

        event TransferOwnership(address indexed from, address indexed to);

        constructor() public {
                owner = msg.sender;
        }

        modifier onlyOwner() {
                require(msg.sender == owner, "Only owner can do this");
                _;
        }

        function transferOwnership(address newOwner) public onlyOwner {
                owner = newOwner;
                emit TransferOwnership(msg.sender, newOwner);
        }
}