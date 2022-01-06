// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFTTest is ERC721 {
    uint256 currentId;

    constructor() ERC721("spacemarvel", "SVE721") {
        currentId = 1;
    }

    function mint(address to) public {
        _mint(to, currentId);
        currentId += 1;
    }
}
