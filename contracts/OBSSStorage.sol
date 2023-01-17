// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@opengsn/contracts/src/ERC2771Recipient.sol";
import "@big-whale-labs/versioned-contract/contracts/Versioned.sol";

/**
 * @title OBSSStorage
 * @dev This contract is used to store the data of the OBSS contract
 */
contract OBSSStorage is Ownable, ERC2771Recipient, Versioned {
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
    uint256 commentsFeedId;
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
  mapping(bytes32 => Reaction[]) public reactions;
  mapping(bytes32 => address) public reactionToUser;

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

  constructor(address _forwarder, string memory _version) Versioned(_version) {
    _setTrustedForwarder(_forwarder);
    version = _version;
  }

  /**
   * @dev Add a new feed
   * @param feedMetadata The feed to add
   */
  function addFeed(CID memory feedMetadata) public returns (uint256) {
    uint256 feedId = lastFeedId.current();
    feeds.push(feedMetadata);
    emit FeedAdded(feedId, feedMetadata);
    lastFeedId.increment();
    return feedId;
  }

  /**
   * @dev Add a new feed post
   * @param feedId The feed id
   * @param postMetadata The post metadata to add
   */
  function addFeedPost(uint256 feedId, CID memory postMetadata) external {
    uint256 commentsFeedId = addFeed(postMetadata);
    Post memory post = Post(_msgSender(), postMetadata, commentsFeedId);
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
    profiles[_msgSender()] = profileMetadata;
    emit ProfileAdded(_msgSender(), profileMetadata);
  }

  /**
   * @dev Add a new profile post
   * @param postMetadata The post metadata to add
   */
  function addProfilePost(CID memory postMetadata) external {
    uint256 commentsFeedId = addFeed(postMetadata);
    Post memory post = Post(_msgSender(), postMetadata, commentsFeedId);
    uint256 objectId = lastProfilePostIds[_msgSender()].current();
    profilePosts[_msgSender()].push(post);
    emit ProfilePostAdded(_msgSender(), objectId, post);
    lastProfilePostIds[_msgSender()].increment();
  }

  /**
   * @dev Change the subscriptions of a user
   * @param subscriptionsMetadata The subscriptions to set
   */
  function changeSubscriptions(CID memory subscriptionsMetadata) external {
    subscriptions[_msgSender()] = subscriptionsMetadata;
    emit SubsciptionsChanged(_msgSender(), subscriptionsMetadata);
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
    if (reactionToUser[post.metadata.digest] == _msgSender()) {
      revert("Reaction already added");
    }
    Reaction memory reaction = Reaction(reactionType, msg.value);
    reactions[post.metadata.digest].push(reaction);
    reactionToUser[post.metadata.digest] = _msgSender();
    if (msg.value > 0) {
      payable(post.author).transfer(msg.value);
    }
    emit ReactionAdded(
      _msgSender(),
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
  function removeReaction(
    uint256 feedOrProfileId,
    uint256 postId,
    uint256 reactionId
  ) external {
    Post memory post = feedPosts[feedOrProfileId][postId];
    if (post.author == address(0)) {
      revert("Post not found");
    }
    delete reactions[post.metadata.digest][reactionId];
    delete reactionToUser[post.metadata.digest];
    emit ReactionRemoved(_msgSender(), feedOrProfileId, postId);
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
   * @dev Get the post rections
   */
  function getPostReactions(
    uint256 feedId,
    uint256 postId
  ) external view returns (uint256, uint256) {
    Post memory post = feedPosts[feedId][postId];
    if (post.author == address(0)) {
      revert("Post not found");
    }
    Reaction[] memory _reactions = reactions[post.metadata.digest];
    uint256 length = _reactions.length;

    uint256 negativeReactions = 0;
    uint256 positiveReactions = 0;

    for (uint256 i = 0; i < length; ) {
      Reaction memory currentReaction = _reactions[i];
      if (currentReaction.reactionType == 0) {
        positiveReactions += currentReaction.value;
      } else {
        negativeReactions += currentReaction.value;
      }
      unchecked {
        ++i;
      }
    }

    return (negativeReactions, positiveReactions);
  }

  function _msgSender()
    internal
    view
    override(Context, ERC2771Recipient)
    returns (address sender)
  {
    sender = ERC2771Recipient._msgSender();
  }

  function _msgData()
    internal
    view
    override(Context, ERC2771Recipient)
    returns (bytes calldata ret)
  {
    return ERC2771Recipient._msgData();
  }
}
