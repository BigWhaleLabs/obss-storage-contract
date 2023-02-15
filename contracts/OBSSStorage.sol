// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@opengsn/contracts/src/ERC2771Recipient.sol";
import "@big-whale-labs/versioned-contract/contracts/Versioned.sol";
import "@big-whale-labs/ketl-allow-map-contract/contracts/KetlAllowMap.sol";

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
    uint256 timestamp;
  }
  // 1 = upvote, 2 = downvote
  struct Reaction {
    uint8 reactionType;
    uint256 value;
    address reactionOwner;
  }

  /* State */
  // Posts
  mapping(uint256 => Post) public posts;
  // Ketl allow map
  KetlAllowMap public vcAllowMap;
  KetlAllowMap public founderAllowMap;
  // Feeds
  CID[] public feeds;
  Counters.Counter public lastFeedId;
  mapping(uint256 => uint256[]) public feedPosts;
  mapping(uint256 => Counters.Counter) public lastFeedPostIds;
  // Profiles
  mapping(address => CID) public profiles;
  mapping(address => uint256[]) public profilePosts;
  mapping(address => Counters.Counter) public lastProfilePostIds;
  mapping(address => CID) public subscriptions;
  // Reactions
  mapping(bytes32 => mapping(uint256 => Reaction)) public reactions;
  mapping(bytes32 => Counters.Counter) public lastReactionIds;
  mapping(bytes32 => mapping(address => uint256)) public reactionsUserToId;

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

  // Modifiers
  modifier onlyAllowedAddresses() {
    if (
      !vcAllowMap.isAddressAllowed(_msgSender()) &&
      !founderAllowMap.isAddressAllowed(_msgSender())
    ) {
      revert("Address is not allowed");
    }
    _;
  }

  constructor(
    address _forwarder,
    string memory _version,
    address _vcAllowMap,
    address _founderAllowMap
  ) Versioned(_version) {
    vcAllowMap = KetlAllowMap(_vcAllowMap);
    founderAllowMap = KetlAllowMap(_founderAllowMap);
    _setTrustedForwarder(_forwarder);
    version = _version;
  }

  function addAddressToVCAllowMap(
    address _address,
    uint[2] memory a,
    uint[2][2] memory b,
    uint[2] memory c,
    uint[2] memory input
  ) public {
    vcAllowMap.addAddressToAllowMap(_address, a, b, c, input);
  }

  function addAddressToFounderAllowMap(
    address _address,
    uint[2] memory a,
    uint[2][2] memory b,
    uint[2] memory c,
    uint[2] memory input
  ) public {
    founderAllowMap.addAddressToAllowMap(_address, a, b, c, input);
  }

  /**
   * @dev Add a new feed
   * @param feedMetadata The feed to add
   */
  function addFeed(
    CID memory feedMetadata
  ) public onlyAllowedAddresses returns (uint256) {
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
  function addFeedPost(
    uint256 feedId,
    CID memory postMetadata
  ) external onlyAllowedAddresses {
    uint256 commentsFeedId = addFeed(postMetadata);
    Post memory post = Post(
      _msgSender(),
      postMetadata,
      commentsFeedId,
      block.timestamp
    );
    uint256 objectId = lastFeedPostIds[feedId].current();
    posts[commentsFeedId] = post;
    feedPosts[feedId].push(commentsFeedId);
    emit FeedPostAdded(feedId, objectId, post);
    lastFeedPostIds[feedId].increment();
  }

  /**
   * @dev Add a new profile
   * @param profileMetadata The profile to add
   */
  function addProfile(
    CID memory profileMetadata
  ) external onlyAllowedAddresses {
    profiles[_msgSender()] = profileMetadata;
    emit ProfileAdded(_msgSender(), profileMetadata);
  }

  /**
   * @dev Add a new profile post
   * @param postMetadata The post metadata to add
   */
  function addProfilePost(
    CID memory postMetadata
  ) external onlyAllowedAddresses {
    uint256 commentsFeedId = addFeed(postMetadata);
    Post memory post = Post(
      _msgSender(),
      postMetadata,
      commentsFeedId,
      block.timestamp
    );
    uint256 objectId = lastProfilePostIds[_msgSender()].current();
    posts[commentsFeedId] = post;
    profilePosts[_msgSender()].push(commentsFeedId);
    emit ProfilePostAdded(_msgSender(), objectId, post);
    lastProfilePostIds[_msgSender()].increment();
  }

  /**
   * @dev Change the subscriptions of a user
   * @param subscriptionsMetadata The subscriptions to set
   */
  function changeSubscriptions(
    CID memory subscriptionsMetadata
  ) external onlyAllowedAddresses {
    subscriptions[_msgSender()] = subscriptionsMetadata;
    emit SubsciptionsChanged(_msgSender(), subscriptionsMetadata);
  }

  /**
   * @dev Add a reaction
   * @param postId The post id
   * @param reactionType The reaction type
   */
  function addReaction(
    uint256 postId,
    uint8 reactionType
  ) external payable onlyAllowedAddresses {
    Post memory post = posts[postId];
    if (post.author == address(0)) {
      revert("Post not found");
    }
    uint256 oldReactionId = reactionsUserToId[post.metadata.digest][
      _msgSender()
    ];
    if (
      reactions[post.metadata.digest][oldReactionId].reactionType ==
      reactionType
    ) revert("Reaction already added");
    if (oldReactionId > 0) {
      delete reactions[post.metadata.digest][oldReactionId];
      delete reactionsUserToId[post.metadata.digest][_msgSender()];
      emit ReactionRemoved(_msgSender(), postId, oldReactionId);
    }
    Reaction memory reaction = Reaction(reactionType, msg.value, _msgSender());
    lastReactionIds[post.metadata.digest].increment();
    uint256 reactionId = lastReactionIds[post.metadata.digest].current();
    reactions[post.metadata.digest][reactionId] = reaction;
    reactionsUserToId[post.metadata.digest][_msgSender()] = reactionId;
    if (msg.value > 0) {
      payable(post.author).transfer(msg.value);
    }
    emit ReactionAdded(
      _msgSender(),
      postId,
      reactionType,
      reactionId,
      msg.value
    );
  }

  /**
   * @dev Remove a reaction
   * @param postId The post id
   * @param reactionId The reaction id
   */
  function removeReaction(
    uint256 postId,
    uint256 reactionId
  ) external onlyAllowedAddresses {
    Post memory post = posts[postId];
    if (post.author == address(0)) {
      revert("Post not found");
    }
    if (
      _msgSender() != reactions[post.metadata.digest][reactionId].reactionOwner
    ) {
      revert("You are not the reaction owner");
    }
    delete reactions[post.metadata.digest][reactionId];
    delete reactionsUserToId[post.metadata.digest][_msgSender()];
    emit ReactionRemoved(_msgSender(), postId, reactionId);
  }

  /**
   * @dev Get the feed posts
   */
  function getFeedPosts(
    uint256 feedId,
    uint256 skip,
    uint256 limit
  ) external view returns (Post[] memory) {
    uint256 countPosts = lastFeedPostIds[feedId].current();
    if (skip > countPosts) {
      return new Post[](0);
    }
    uint256 length = skip + limit > countPosts - 1 ? countPosts - skip : limit;
    Post[] memory allPosts = new Post[](length);
    for (uint256 i = 0; i < length; i++) {
      uint256 postId = feedPosts[feedId][skip + i];
      Post memory post = posts[postId];
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
    uint256 countPosts = lastProfilePostIds[profile].current();
    if (skip > countPosts) {
      return new Post[](0);
    }
    uint256 length = skip + limit > countPosts - 1 ? countPosts - skip : limit;
    Post[] memory allPosts = new Post[](length);
    for (uint256 i = 0; i < length; i++) {
      uint256 postId = profilePosts[profile][skip + i];
      Post memory post = posts[postId];
      allPosts[i] = post;
    }
    return allPosts;
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
    uint256 reactionsLength = lastReactionIds[post.metadata.digest].current();
    uint256 negativeReactions = 0;
    uint256 positiveReactions = 0;

    for (uint256 i = 1; i < reactionsLength + 1; ) {
      Reaction memory currentReaction = reactions[post.metadata.digest][i];
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
