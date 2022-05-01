// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract AhoyToken is ERC20, ERC20Burnable {
    constructor() ERC20("AhoyToken", "AToken") {
        _mint(msg.sender, 100000000 * 10**decimals());
    }
}
