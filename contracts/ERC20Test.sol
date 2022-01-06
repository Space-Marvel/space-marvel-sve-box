// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Test is ERC20{
    constructor () ERC20("Erc20 Test","ERC20Test"){

    }

    function mint(address _account, uint256 _amount) external{
        _mint(_account, _amount);
    }
}