// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// 1 = upvote, 2 = downvote
struct Reaction {
  uint256 postId;
  uint8 reactionType;
  uint256 value;
  address reactionOwner;
}
