// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// 1 = upvote, 2 = downvote
struct Reaction {
  address sender;
  uint feedId;
  uint postId;
  uint8 reactionType;
  uint value;
}
