//                                                                        ,-,
//                            *                      .                   /.(              .
//                                       \|/                             \ {
//    .                 _    .  ,   .    -*-       .                      `-`
//     ,'-.         *  / \_ *  / \_      /|\         *   /\'__        *.                 *
//    (____".         /    \  /    \,     __      .    _/  /  \  * .               .
//               .   /\/\  /\/ :' __ \_  /  \       _^/  ^/    `—./\    /\   .
//   *       _      /    \/  \  _/  \-‘\/  ` \ /\  /.' ^_   \_   .’\\  /_/\           ,'-.
//          /_\   /\  .-   `. \/     \ /.     /  \ ;.  _/ \ -. `_/   \/.   \   _     (____".    *
//     .   /   \ /  `-.__ ^   / .-'.--\      -    \/  _ `--./ .-'  `-/.     \ / \             .
//        /     /.       `.  / /       `.   /   `  .-'      '-._ `._         /.  \
// ~._,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'
// ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~~
// ~~    ~~~~    ~~~~     ~~~~   ~~~~    ~~~~    ~~~~    ~~~~    ~~~~    ~~~~    ~~~~    ~~~~    ~~
//     ~~     ~~      ~~      ~~      ~~      ~~      ~~      ~~       ~~     ~~      ~~      ~~
//                          ๐
//                                                                              _
//                                                  ₒ                         ><_>
//                                  _______     __      _______
//          .-'                    |   _  "\   |" \    /" _   "|                               ๐
//     '--./ /     _.---.          (. |_)  :)  ||  |  (: ( \___)
//     '-,  (__..-`       \        |:     \/   |:  |   \/ \
//        \          .     |       (|  _  \\   |.  |   //  \ ___
//         `,.__.   ,__.--/        |: |_)  :)  |\  |   (:   _(  _|
//           '._/_.'___.-`         (_______/   |__\|    \_______)                 ๐
//
//                  __   __  ___   __    __         __       ___         _______
//                 |"  |/  \|  "| /" |  | "\       /""\     |"  |       /"     "|
//      ๐          |'  /    \:  |(:  (__)  :)     /    \    ||  |      (: ______)
//                 |: /'        | \/      \/     /' /\  \   |:  |   ₒ   \/    |
//                  \//  /\'    | //  __  \\    //  __'  \   \  |___    // ___)_
//                  /   /  \\   |(:  (  )  :)  /   /  \\  \ ( \_|:  \  (:      "|
//                 |___/    \___| \__|  |__/  (___/    \___) \_______)  \_______)
//                                                                                     ₒ৹
//                          ___             __       _______     ________
//         _               |"  |     ₒ     /""\     |   _  "\   /"       )
//       ><_>              ||  |          /    \    (. |_)  :) (:   \___/
//                         |:  |         /' /\  \   |:     \/   \___  \
//                          \  |___     //  __'  \  (|  _  \\    __/  \\          \_____)\_____
//                         ( \_|:  \   /   /  \\  \ |: |_)  :)  /" \   :)         /--v____ __`<
//                          \_______) (___/    \___)(_______/  (_______/                  )/
//                                                                                        '
//
//            ๐                          .    '    ,                                           ₒ
//                         ₒ               _______
//                                 ____  .`_|___|_`.  ____
//                                        \ \   / /                        ₒ৹
//                                          \ ' /                         ๐
//   ₒ                                        \/
//                                   ₒ     /      \       )                                 (
//           (   ₒ৹               (                      (                                  )
//            )                   )               _      )                )                (
//           (        )          (       (      ><_>    (       (        (                  )
//     )      )      (     (      )       )              )       )        )         )      (
//    (      (        )     )    (       (              (       (        (         (        )
// ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Counters.sol";
import "../models/Post.sol";
import "../models/Reaction.sol";
import "./KetlGuarded.sol";

contract Posts is KetlGuarded {
  using Counters for Counters.Counter;

  // State
  mapping(uint => Post[]) public posts;
  mapping(uint => Counters.Counter) public lastPostIds;

  mapping(uint => mapping(uint => Post[])) public comments;
  mapping(uint => mapping(uint => Counters.Counter)) public lastCommentIds;

  mapping(uint => mapping(uint => Reaction[])) public reactions;
  mapping(uint => mapping(uint => Counters.Counter)) public lastReactionIds;
  mapping(uint => mapping(uint => mapping(address => Reaction)))
    public usersToReactions;

  // Events
  event PostAdded(uint indexed feedId, uint indexed postId, Post post);
  event CommentAdded(
    uint indexed feedId,
    uint indexed postId,
    uint indexed commentId,
    Post comment
  );
  event ReactionAdded(
    address indexed sender,
    uint indexed feedId,
    uint indexed postId,
    uint8 reactionType,
    uint reactionId,
    uint value
  );
  event ReactionRemoved(
    address indexed sender,
    uint feedId,
    uint postId,
    uint reactionId
  );

  function addPost(
    address sender,
    uint id,
    CID memory postMetadata
  ) internal onlyAllowedCaller onlyKetlTokenOwners(sender) {
    Post memory post = Post(sender, postMetadata, block.timestamp);
    posts[id].push(post);
    emit PostAdded(id, lastPostIds[id].current(), post);
    lastPostIds[id].increment();
  }

  function getPosts(
    uint id,
    uint skip,
    uint limit
  ) external view returns (Post[] memory) {
    uint countPosts = lastPostIds[id].current();
    if (skip > countPosts) {
      return new Post[](0);
    }
    uint length = skip + limit > countPosts - 1 ? countPosts - skip : limit;
    Post[] memory allPosts = new Post[](length);
    for (uint i = 0; i < length; i++) {
      Post memory post = posts[id][skip + i];
      allPosts[i] = post;
    }
    return allPosts;
  }

  function addComment(
    address sender,
    uint id,
    uint postId,
    CID memory commentMetadata
  ) internal onlyAllowedCaller onlyKetlTokenOwners(sender) {
    Post memory comment = Post(sender, commentMetadata, block.timestamp);
    comments[id][postId].push(comment);
    emit CommentAdded(
      id,
      postId,
      lastCommentIds[id][postId].current(),
      comment
    );
    lastCommentIds[id][postId].increment();
  }

  function addReaction(
    address sender,
    uint feedId,
    uint postId,
    uint8 reactionType
  ) external payable onlyAllowedCaller onlyKetlTokenOwners(sender) {
    Post memory post = posts[feedId][postId];
    require(post.author != address(0), "Post not found");
    Reaction memory oldReaction = usersToReactions[feedId][postId][sender];
    require(oldReaction.sender == address(0), "Reaction already exists");

    Reaction memory reaction = Reaction(
      sender,
      feedId,
      postId,
      reactionType,
      msg.value
    );
    reactions[feedId][postId].push(reaction);
    usersToReactions[feedId][postId][sender] = reaction;
    lastReactionIds[feedId][postId].increment();

    if (msg.value > 0) {
      payable(post.author).transfer(msg.value);
    }

    emit ReactionAdded(
      sender,
      feedId,
      postId,
      reactionType,
      lastReactionIds[feedId][postId].current(),
      msg.value
    );
  }

  function removeReaction(
    address sender,
    uint feedId,
    uint postId,
    uint reactionId
  ) external onlyAllowedCaller onlyKetlTokenOwners(sender) {
    Post memory post = posts[feedId][postId];
    require(post.author != address(0), "Post not found");
    require(
      reactions[feedId][postId][reactionId].sender == sender,
      "You are not the owner of this reaction"
    );
    delete reactions[feedId][postId][reactionId];
    delete usersToReactions[feedId][postId][sender];
    emit ReactionRemoved(sender, feedId, postId, reactionId);
  }

  function getPostReactions(
    uint feedId,
    uint postId
  ) external view returns (uint, uint) {
    Post memory post = posts[feedId][postId];
    require(post.author != address(0), "Post not found");
    uint reactionsLength = lastReactionIds[feedId][postId].current();
    uint negativeReactions = 0;
    uint positiveReactions = 0;

    for (uint i = 0; i < reactionsLength; i++) {
      Reaction memory currentReaction = reactions[feedId][postId][i];
      if (currentReaction.reactionType == 1) {
        positiveReactions += 1;
      } else if (currentReaction.reactionType == 2) {
        negativeReactions += 1;
      }
    }

    return (negativeReactions, positiveReactions);
  }
}
