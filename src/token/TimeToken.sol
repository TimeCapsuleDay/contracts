// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract TimeToken is ERC20, ERC20Burnable, ERC20Permit {
    constructor() ERC20("TimeToken", "TIME") ERC20Permit("TimeToken") {
        _mint(msg.sender, 10_000_000 * 10**decimals());
    }
}
