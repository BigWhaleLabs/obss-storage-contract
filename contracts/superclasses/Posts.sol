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
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../models/PostAndParticipants.sol";
import "../models/Reaction.sol";
import "../models/PostRequest.sol";
import "../models/CommentRequest.sol";
import "../models/ReactionRequests.sol";
import "./KetlGuarded.sol";

contract Posts is KetlGuarded {
  using Counters for Counters.Counter;

  // State
  mapping(uint => Post[]) public posts;
  mapping(uint => mapping(uint => bool)) public pinnedPosts;
  mapping(uint => Counters.Counter) public lastPostIds;
  mapping(uint => mapping(uint => address[])) public participants;
  mapping(uint => mapping(uint => mapping(address => bool)))
    public participantsMap;

  mapping(uint => mapping(uint => Post[])) public comments;
  mapping(uint => mapping(uint => Counters.Counter)) public lastCommentIds;

  mapping(uint => mapping(uint => mapping(uint => mapping(uint => Reaction))))
    public reactions;
  mapping(uint => mapping(uint => mapping(uint => Counters.Counter)))
    public lastReactionIds;
  mapping(uint => mapping(uint => mapping(uint => mapping(address => Reaction))))
    public usersToReactions;

  // Events
  event PostAdded(
    uint indexed feedId,
    uint indexed postId,
    Post post,
    address indexed sender
  );
  event PostPinned(uint indexed feedId, uint indexed postId);
  event PostUnpinned(uint indexed feedId, uint indexed postId);
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
    uint commentId,
    uint8 reactionType,
    uint reactionId,
    uint value
  );
  event ReactionRemoved(
    address indexed sender,
    uint indexed feedId,
    uint indexed postId,
    uint commentId,
    uint reactionId
  );

  // Modifiers
  modifier onlyAllowedFeedId(uint feedId) virtual {
    _;
  }
  modifier onlyElevatedPriveleges(uint feedId, address sender) virtual {
    _;
  }

  // Posts

  function addPost(
    address sender,
    PostRequest memory postRequest
  )
    external
    onlyAllowedCaller
    onlyKetlTokenOwners(sender)
    onlyAllowedFeedId(postRequest.feedId)
  {
    uint feedId = postRequest.feedId;
    // Get current post id
    uint currentPostId = lastPostIds[feedId].current();
    // Create the post
    Post memory post = Post(
      sender,
      postRequest.postMetadata,
      block.timestamp,
      currentPostId,
      currentPostId,
      0
    );
    // Add the post
    posts[feedId].push(post);
    // Add the participants
    participants[feedId][currentPostId].push(sender);
    participantsMap[feedId][currentPostId][sender] = true;
    // Emit the event
    emit PostAdded(feedId, lastPostIds[feedId].current(), post, sender);
    // Increment current post id
    lastPostIds[feedId].increment();
  }

  function pinOrUnpinPost(
    address sender,
    uint feedId,
    uint postId,
    bool pin
  )
    public
    onlyAllowedCaller
    onlyAllowedFeedId(feedId)
    onlyKetlTokenOwners(sender)
    onlyElevatedPriveleges(feedId, sender)
  {
    uint lastPostId = lastPostIds[feedId].current();
    // @Todo: remove after debugging
    require(
      postId < lastPostId,
      string(
        abi.encodePacked(
          "Post not found for feedId: ",
          Strings.toString(feedId),
          ", postId: ",
          Strings.toString(postId),
          ", lastPostId: ",
          Strings.toString(lastPostId)
        )
      )
    );
    pinnedPosts[feedId][postId] = pin;
    if (pin) {
      emit PostPinned(feedId, postId);
    } else {
      emit PostUnpinned(feedId, postId);
    }
  }

  function getPostsAndParticipants(
    uint feedId,
    uint skip,
    uint limit,
    bool pinned
  ) external view returns (PostAndParticipants[] memory) {
    // Get the number of posts
    uint countPosts = lastPostIds[feedId].current();
    // Check if there are posts to return after skip
    if (skip > countPosts) {
      return new PostAndParticipants[](0);
    }
    // Create an temporary array of posts
    PostAndParticipants[] memory tempPosts = new PostAndParticipants[](
      countPosts - skip
    );
    // Fill the temporary array of posts
    uint index = 0;
    for (uint i = 0; i < countPosts - skip; i++) {
      // Check if post is pinned or unpinned based on the argument passed
      if (pinnedPosts[feedId][skip + i] == pinned) {
        Post memory post = posts[feedId][skip + i];
        tempPosts[index] = PostAndParticipants(
          post,
          participants[feedId][skip + i]
        );
        index++;
      }
    }
    // Get the number of posts to return
    uint length = index < limit ? index : limit;
    // Create the final array of posts
    PostAndParticipants[] memory allPosts = new PostAndParticipants[](length);
    // Copy posts from the temporary array to the final one
    for (uint i = 0; i < length; i++) {
      allPosts[i] = tempPosts[i];
    }
    // Return the array of posts
    return allPosts;
  }

  // Comments

  function addComment(
    address sender,
    CommentRequest memory commentRequest
  )
    external
    onlyAllowedCaller
    onlyKetlTokenOwners(sender)
    onlyAllowedFeedId(commentRequest.feedId)
  {
    uint feedId = commentRequest.feedId;
    uint postId = commentRequest.postId;
    uint replyTo = commentRequest.replyTo;
    // Check if parent post exists
    require(posts[feedId][postId].sender != address(0), "Post not found");
    // Fetch parent comment and check if it exists
    if (replyTo > 0) {
      require(
        comments[feedId][postId][replyTo].sender != address(0),
        "Comment not found"
      );
    }
    // Increment comment id (so that we start with 1)
    lastCommentIds[feedId][postId].increment();
    // Create comment
    Post memory comment = Post(
      sender,
      commentRequest.commentMetadata,
      block.timestamp,
      postId,
      replyTo,
      0
    );
    // Add comment
    comments[feedId][postId].push(comment);
    // Add the participant
    if (!participantsMap[feedId][postId][sender]) {
      participants[feedId][postId].push(sender);
      participantsMap[feedId][postId][sender] = true;
    }
    // Increment comments count
    posts[feedId][postId].numberOfComments++;
    if (replyTo > 0) {
      comments[feedId][postId][replyTo].numberOfComments++;
    }
    // Emit the event
    emit CommentAdded(
      feedId,
      postId,
      lastCommentIds[feedId][postId].current(),
      comment
    );
  }

  function getComments(
    uint feedId,
    uint postId,
    uint skip,
    uint limit
  ) external view returns (Post[] memory) {
    // Get the number of comments
    uint countComments = lastCommentIds[feedId][postId].current();

    // Return an empty array if there are no comments
    if (countComments == 0) {
      return new Post[](0);
    }

    // Check if there are comments to return after skip
    if (skip > countComments) {
      return new Post[](0);
    }
    // Get the number of comments to return
    uint length = skip + limit > countComments - 1
      ? countComments - skip
      : limit;
    // Create the array of comments
    Post[] memory allComments = new Post[](length);
    // Fill the array of comments
    for (uint i = 0; i < length; i++) {
      allComments[i] = comments[feedId][postId][skip + i];
    }
    // Return the array of comments
    return allComments;
  }

  // Reactions

  function addReaction(
    address sender,
    AddReactionRequest memory reactionRequest
  )
    external
    payable
    onlyAllowedCaller
    onlyKetlTokenOwners(sender)
    onlyAllowedFeedId(reactionRequest.feedId)
  {
    uint feedId = reactionRequest.feedId;
    uint postId = reactionRequest.postId;
    uint commentId = reactionRequest.commentId;
    uint8 reactionType = reactionRequest.reactionType;
    // Fetch post or comment
    Post memory post = commentId == 0
      ? posts[feedId][postId]
      : comments[feedId][postId][commentId];
    // Check if post or comment exists
    require(post.sender != address(0), "Post or comment not found");
    // Get old reaction if it exists
    Reaction memory oldReaction = usersToReactions[feedId][postId][commentId][
      sender
    ];
    // Check if reaction already exists
    require(oldReaction.sender == address(0), "Reaction already exists");
    // Increment and get lastReactionIds
    lastReactionIds[feedId][postId][commentId].increment();
    uint reactionId = lastReactionIds[feedId][postId][commentId].current();
    // Create reaction
    Reaction memory reaction = Reaction(
      sender,
      feedId,
      postId,
      commentId,
      reactionType,
      reactionId,
      msg.value
    );
    // Add reaction
    reactions[feedId][postId][commentId][reactionId] = reaction;
    // Remember the reaction for user
    usersToReactions[feedId][postId][commentId][sender] = reaction;
    // If ether was sent, transfer it to the sender
    if (msg.value > 0) {
      Address.sendValue(payable(post.sender), msg.value);
    }
    // Emit the event
    emit ReactionAdded(
      sender,
      feedId,
      postId,
      commentId,
      reactionType,
      reactionId,
      msg.value
    );
  }

  function removeReaction(
    address sender,
    RemoveReactionRequest memory reactionRequest
  )
    external
    onlyAllowedCaller
    onlyKetlTokenOwners(sender)
    onlyAllowedFeedId(reactionRequest.feedId)
  {
    uint feedId = reactionRequest.feedId;
    uint postId = reactionRequest.postId;
    uint commentId = reactionRequest.commentId;
    uint reactionId = reactionRequest.reactionId;
    // Fetch post or comment
    Post memory post = commentId == 0
      ? posts[feedId][postId]
      : comments[feedId][postId][commentId];
    // Check if post or comment exists
    require(post.sender != address(0), "Post or comment not found");
    // Check if sent by the owner
    require(
      reactions[feedId][postId][commentId][reactionId].sender == sender,
      "You are not the owner of this reaction"
    );
    // Delete the reaction
    delete reactions[feedId][postId][commentId][reactionId];
    // Delete the reaction from the user map
    delete usersToReactions[feedId][postId][commentId][sender];
    emit ReactionRemoved(sender, feedId, postId, commentId, reactionId);
  }

  function getReactions(
    uint feedId,
    uint postId,
    uint commentId
  ) external view returns (uint, uint) {
    // Fetch post or comment
    Post memory post = commentId == 0
      ? posts[feedId][postId]
      : comments[feedId][postId][commentId];
    // Check if post or comment exists
    require(post.sender != address(0), "Post or comment not found");
    // Get the number of reactions
    uint reactionsLength = lastReactionIds[feedId][postId][commentId].current();
    // Create the array of reactions
    uint negativeReactions = 0;
    uint positiveReactions = 0;
    // Fill the array of reactions
    for (uint i = 0; i < reactionsLength; i++) {
      Reaction memory currentReaction = reactions[feedId][postId][commentId][i];
      if (currentReaction.reactionType == 1) {
        positiveReactions += 1;
      } else if (currentReaction.reactionType == 2) {
        negativeReactions += 1;
      }
    }
    // Return the array of reactions
    return (negativeReactions, positiveReactions);
  }
}
