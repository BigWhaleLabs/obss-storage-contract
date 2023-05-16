// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./CID.sol";

struct Post {
  address author;
  CID metadata;
  uint timestamp;
}
