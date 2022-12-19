// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@big-whale-labs/versioned-contract/contracts/Versioned.sol";

/**
 * @title OBSSStorage
 * @dev This contract is used to store the data of the OBSS contract
 */
contract OBSSStorage is Ownable, Versioned {
  using Counters for Counters.Counter;

  // IPFS cid represented in a more efficient way
  struct CID {
    bytes32 digest;
    uint8 hashFunction;
    uint8 size;
  }
  // Post struct
  struct Post {
    address author;
    CID metadata;
  }
  // Coment struct
  struct Comment {
    address author;
    CID metadata;
  }

  // 0 = upvote, 1 = downvote
  struct Reaction {
    uint8 reactionType;
    uint256 value;
  }

  /* State */
  // Feeds
  CID[] public feeds;
  Counters.Counter public lastFeedId;
  mapping(uint256 => Post[]) public feedPosts;
  mapping(uint256 => Counters.Counter) public lastFeedPostIds;
  // Profiles
  mapping(address => CID) public profiles;
  mapping(address => Post[]) public profilePosts;
  mapping(address => Counters.Counter) public lastProfilePostIds;
  mapping(address => CID) public subscriptions;
  // Reactions
  mapping(bytes32 => mapping(address => Reaction)) public reactions;
  // Comments
  mapping (bytes32 => Comment[]) public comments;
  mapping(bytes32 => bytes32[]) public rootCommentsDigest;
  /* Events */
  // Feeds
  event FeedAdded(uint256 indexed id, CID metadata);
  event FeedPostAdded(
    uint256 indexed feedId,
    uint256 indexed postId,
    Post post
  );
  // Profiles
  event ProfileAdded(address indexed user, CID metadata);
  event ProfilePostAdded(
    address indexed profile,
    uint256 indexed postId,
    Post post
  );
  event SubsciptionsChanged(address indexed user, CID metadata);
  // Reactions
  event ReactionAdded(
    address indexed user,
    uint256 indexed feedOrProfileId,
    uint256 indexed postId,
    uint8 reactionType,
    uint256 value
  );
  event ReactionRemoved(
    address indexed user,
    uint256 indexed feedOrProfileId,
    uint256 postId
  );
  event CommentAdded(
    bytes32 indexed postDigest,
    bytes32 indexed commentDigest,
    Comment comment
  );

  /**
   * @dev Constructor
   * @param version Version of the contract
   */
  constructor(string memory version) Versioned(version) {}

  /**
   * @dev Add a new feed
   * @param feedMetadata The feed to add
   */
  function addFeed(CID memory feedMetadata) external {
    uint256 feedId = lastFeedId.current();
    feeds.push(feedMetadata);
    emit FeedAdded(feedId, feedMetadata);
    lastFeedId.increment();
  }

  /**
   * @dev Add a new feed post
   * @param feedId The feed id
   * @param postMetadata The post metadata to add
   */
  function addFeedPost(uint256 feedId, CID memory postMetadata) external {
    Post memory post = Post(msg.sender, postMetadata);
    uint256 objectId = lastFeedPostIds[feedId].current();
    feedPosts[feedId].push(post);
    emit FeedPostAdded(feedId, objectId, post);
    lastFeedPostIds[feedId].increment();
  }

  /**
   * @dev Add a new profile
   * @param profileMetadata The profile to add
   */
  function addProfile(CID memory profileMetadata) external {
    profiles[msg.sender] = profileMetadata;
    emit ProfileAdded(msg.sender, profileMetadata);
  }

  /**
   * @dev Add a new profile post
   * @param postMetadata The post metadata to add
   */
  function addProfilePost(CID memory postMetadata) external {
    Post memory post = Post(msg.sender, postMetadata);
    uint256 objectId = lastProfilePostIds[msg.sender].current();
    profilePosts[msg.sender].push(post);
    emit ProfilePostAdded(msg.sender, objectId, post);
    lastProfilePostIds[msg.sender].increment();
  }

  /**
   * @dev Change the subscriptions of a user
   * @param subscriptionsMetadata The subscriptions to set
   */
  function changeSubscriptions(CID memory subscriptionsMetadata) external {
    subscriptions[msg.sender] = subscriptionsMetadata;
    emit SubsciptionsChanged(msg.sender, subscriptionsMetadata);
  }

  /**
   * @dev Add a reaction
   * @param feedOrProfileId The feed or profile id
   * @param postId The post id
   * @param reactionType The reaction type
   */
  function addReaction(
    uint256 feedOrProfileId,
    uint256 postId,
    uint8 reactionType
  ) external payable {
    Post memory post = feedPosts[feedOrProfileId][postId];
    if (post.author == address(0)) {
      revert("Post not found");
    }
    Reaction memory reaction = Reaction(reactionType, msg.value);
    reactions[post.metadata.digest][msg.sender] = reaction;
    if (msg.value > 0) {
      payable(post.author).transfer(msg.value);
    }
    emit ReactionAdded(
      msg.sender,
      feedOrProfileId,
      postId,
      reactionType,
      msg.value
    );
  }

  /**
   * @dev Remove a reaction
   * @param feedOrProfileId The feed or profile id
   * @param postId The post id
   */
  function removeReaction(uint256 feedOrProfileId, uint256 postId) external {
    Post memory post = feedPosts[feedOrProfileId][postId];
    if (post.author == address(0)) {
      revert("Post not found");
    }
    delete reactions[post.metadata.digest][msg.sender];
    emit ReactionRemoved(msg.sender, feedOrProfileId, postId);
  }

  /**
   * @dev Get the feed posts
   */
  function getFeedPosts(
    uint256 feedId,
    uint256 skip,
    uint256 limit
  ) external view returns (Post[] memory) {
    Post[] memory posts = feedPosts[feedId];
    if (skip > posts.length) {
      return new Post[](0);
    }
    uint256 length = skip + limit > posts.length - 1
      ? posts.length - skip
      : limit;
    Post[] memory allPosts = new Post[](length);
    for (uint256 i = 0; i < length; i++) {
      Post memory post = posts[skip + i];
      allPosts[i] = post;
    }
    return allPosts;
  }

  /**
   * @dev Get the profile posts
   */
  function getProfilePosts(
    address profile,
    uint256 skip,
    uint256 limit
  ) external view returns (Post[] memory) {
    Post[] memory posts = profilePosts[profile];
    if (skip > posts.length) {
      return new Post[](0);
    }
    uint256 length = skip + limit > posts.length - 1
      ? posts.length - skip
      : limit;
    Post[] memory allPosts = new Post[](length);
    for (uint256 i = 0; i < length; i++) {
      Post memory post = posts[skip + i];
      allPosts[i] = post;
    }
    return allPosts;
  }

  /**
   * @dev Add top-level comment to a post
   * @param postDigest The post digest
   * @param commentMetadata The comment metadata
   */
  function addRootComment(bytes32 postDigest, CID memory commentMetadata) external {
    Comment memory comment = Comment(msg.sender, commentMetadata);
    rootCommentsDigest[postDigest].push(commentMetadata.digest);
    comments[postDigest].push(comment);
    emit CommentAdded(postDigest, commentMetadata.digest, comment);
  }
  /**
   * @dev Add reply to comment
   * @param commentDigest The digest of comment to reply to
   * @param replyMetadata The reply metadata
   */
  function addReplyToComment(bytes32 commentDigest, CID memory replyMetadata) external {
    Comment memory reply = Comment(msg.sender, replyMetadata);
    comments[commentDigest].push(Comment(msg.sender, replyMetadata));
    emit CommentAdded(commentDigest, replyMetadata.digest, reply);
  }
}
