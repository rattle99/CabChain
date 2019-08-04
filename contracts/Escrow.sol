pragma solidity ^0.5.10;

import "./IERC20.sol";

contract ERC20Locker {
  struct Locked {
    address owner;
    uint256 unlockAfter;
    uint256 amount;
    IERC20 token;
  }
  Locked[] public locker;

  function lock(address _token, uint256 amount, uint256 lockTime) external {
    IERC20 token = IERC20(_token);
    require(token.transferFrom(msg.sender, address(this), amount), "Failed to transfer tokens");
    locker.push(Locked(msg.sender, block.number+lockTime, amount, token));
  }

  function unlock(uint256 index) external {
    Locked memory locked = locker[index];
    require(block.number > locked.unlockAfter, "Not ready");
    require(locked.owner == msg.sender, "Not owner of locked tokens");
    delete locker[index];
    locked.token.transfer(msg.sender, locked.amount);
  }
}