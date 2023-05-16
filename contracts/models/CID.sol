// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// IPFS storage ID
struct CID {
  bytes32 digest;
  uint8 hashFunction;
  uint8 size;
}
