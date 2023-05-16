// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./models/Reaction.sol";

contract Feeds is Initializable, ContextUpgradeable, OwnableUpgradeable {
  using Counters for Counters.Counter;

  // Structs
  struct ReactionRequest {
    uint256 postId;
    uint8 reactionType;
  }
  struct ReactionRemoveRequest {
    uint256 postId;
    uint8 reactionId;
  }

  // State
  mapping(uint256 => mapping(uint256 => Reaction)) public reactions;
  mapping(uint256 => Counters.Counter) public lastReactionIds;
  mapping(uint256 => mapping(address => uint256)) public reactionsUserToId;

  // Events
  event ReactionAdded(
    address indexed user,
    uint256 indexed postId,
    uint8 reactionType,
    uint256 reactionId,
    uint256 value
  );
  event ReactionRemoved(
    address indexed user,
    uint256 postId,
    uint256 reactionId
  );

  function initialize() public initializer {
    __Ownable_init();
  }

  /**
   * @dev Add a reaction
   * @param reactionRequest Reaction to add
   */
  function _addReaction(
    ReactionRequest memory reactionRequest
  ) private onlyAllowedAddresses {
    Post memory post = posts[reactionRequest.postId];
    if (post.author == address(0)) {
      revert("Post not found");
    }
    uint256 oldReactionId = reactionsUserToId[reactionRequest.postId][
      _msgSender()
    ];
    if (
      reactions[reactionRequest.postId][oldReactionId].reactionType ==
      reactionRequest.reactionType
    ) revert("Reaction already added");
    if (oldReactionId > 0) {
      delete reactions[reactionRequest.postId][oldReactionId];
      delete reactionsUserToId[reactionRequest.postId][_msgSender()];
      emit ReactionRemoved(_msgSender(), reactionRequest.postId, oldReactionId);
    }
    Reaction memory reaction = Reaction(
      reactionRequest.postId,
      reactionRequest.reactionType,
      msg.value,
      _msgSender()
    );
    lastReactionIds[reactionRequest.postId].increment();
    uint256 reactionId = lastReactionIds[reactionRequest.postId].current();
    reactions[reactionRequest.postId][reactionId] = reaction;
    reactionsUserToId[reactionRequest.postId][_msgSender()] = reactionId;
    if (msg.value > 0) {
      payable(post.author).transfer(msg.value);
    }
    if (reactionRequest.reactionType == 1) {
      karma.mint(post.author, 1);
    }
    emit ReactionAdded(
      _msgSender(),
      reactionRequest.postId,
      reactionRequest.reactionType,
      reactionId,
      msg.value
    );
  }

  function addReaction(
    ReactionRequest memory reactionRequest
  ) external payable {
    _addReaction(reactionRequest);
  }

  function addBatchReactions(
    ReactionRequest[] memory reactionsBatch
  ) public payable {
    uint256 length = reactionsBatch.length;
    for (uint8 i = 0; i < length; ) {
      ReactionRequest memory reaction = reactionsBatch[i];
      _addReaction(reaction);

      unchecked {
        ++i;
      }
    }
  }

  /**
   * @dev Remove a reaction
   * @param reactionRequest Reaction to remove
   */
  function _removeReaction(
    ReactionRemoveRequest memory reactionRequest
  ) private onlyAllowedAddresses {
    Post memory post = posts[reactionRequest.postId];
    if (post.author == address(0)) {
      revert("Post not found");
    }
    if (
      _msgSender() !=
      reactions[reactionRequest.postId][reactionRequest.reactionId]
        .reactionOwner
    ) {
      revert("You are not the reaction owner");
    }
    delete reactions[reactionRequest.postId][reactionRequest.reactionId];
    delete reactionsUserToId[reactionRequest.postId][_msgSender()];
    emit ReactionRemoved(
      _msgSender(),
      reactionRequest.postId,
      reactionRequest.reactionId
    );
  }

  function removeReaction(
    ReactionRemoveRequest memory reactionRequest
  ) external {
    _removeReaction(reactionRequest);
  }

  function removeBatchReactions(
    ReactionRemoveRequest[] memory reactionsBatch
  ) public payable {
    uint256 length = reactionsBatch.length;
    for (uint8 i = 0; i < length; ) {
      ReactionRemoveRequest memory reaction = reactionsBatch[i];
      _removeReaction(reaction);

      unchecked {
        ++i;
      }
    }
  }

  /**
   * @dev Get the post rections
   */
  function getPostReactions(
    uint256 postId
  ) external view returns (uint256, uint256) {
    Post memory post = posts[postId];
    if (post.author == address(0)) {
      revert("Post not found");
    }
    uint256 reactionsLength = lastReactionIds[postId].current();
    uint256 negativeReactions = 0;
    uint256 positiveReactions = 0;

    for (uint256 i = 1; i < reactionsLength + 1; ) {
      Reaction memory currentReaction = reactions[postId][i];
      if (currentReaction.reactionType == 1) {
        positiveReactions += 1;
      } else if (currentReaction.reactionType == 2) {
        negativeReactions += 1;
      }
      unchecked {
        ++i;
      }
    }

    return (negativeReactions, positiveReactions);
  }
}
