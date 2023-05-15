// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@opengsn/contracts/src/ERC2771Recipient.sol";
import "@big-whale-labs/ketl-allow-map-contract/contracts/KetlAllowMap.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./KetlKarma.sol";

/**
 * @title OBSSStorage
 * @dev This contract is used to store the data of the OBSS contract
 */
contract OBSSStorage is
  Initializable,
  ContextUpgradeable,
  OwnableUpgradeable,
  ERC2771Recipient
{
  using Counters for Counters.Counter;

  /* State */
  string public version;
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
  mapping(uint256 => mapping(uint256 => Reaction)) public reactions;
  mapping(uint256 => Counters.Counter) public lastReactionIds;
  mapping(uint256 => mapping(address => uint256)) public reactionsUserToId;
  bool public isDataMigrationLocked;
  // Karma
  KetlKarma public karma;

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
    uint256 postId;
    uint8 reactionType;
    uint256 value;
    address reactionOwner;
  }

  struct ReactionRequest {
    uint256 postId;
    uint8 reactionType;
  }

  struct ReactionRemoveRequest {
    uint256 postId;
    uint8 reactionId;
  }

  struct PostRequest {
    uint256 feedId;
    CID postMetadata;
  }

  struct LegacyPost {
    Post post;
    uint256 feedId;
  }
  struct LegacyReaction {
    Reaction reaction;
  }

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
    require(
      vcAllowMap.isAddressAllowed(_msgSender()) ||
        founderAllowMap.isAddressAllowed(_msgSender()),
      "Address is not allowed"
    );
    _;
  }

  modifier onlyIfLoadingAllowed() {
    require(!isDataMigrationLocked, "All legacy data already loaded");
    _;
  }

  // Constructor
  function initialize(
    address _forwarder,
    string memory _version,
    address _vcAllowMap,
    address _founderAllowMap
  ) public initializer {
    vcAllowMap = KetlAllowMap(_vcAllowMap);
    founderAllowMap = KetlAllowMap(_founderAllowMap);
    _setTrustedForwarder(_forwarder);
    version = _version;
    // Set owner
    __Ownable_init();
    isDataMigrationLocked = false;
    // Set karma
    karma = new KetlKarma(address(this));
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

  function isAddressAllowedInVCAllowMap(
    address _address
  ) public view returns (bool) {
    return vcAllowMap.isAddressAllowed(_address);
  }

  function isAddressAllowedInFounderAllowMap(
    address _address
  ) public view returns (bool) {
    return founderAllowMap.isAddressAllowed(_address);
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
   * @param postRequest Post to add
   */
  function _addFeedPost(
    PostRequest memory postRequest
  ) private onlyAllowedAddresses {
    uint256 commentsFeedId = addFeed(postRequest.postMetadata);
    Post memory post = Post(
      _msgSender(),
      postRequest.postMetadata,
      commentsFeedId,
      block.timestamp
    );
    uint256 objectId = lastFeedPostIds[postRequest.feedId].current();
    posts[commentsFeedId] = post;
    feedPosts[postRequest.feedId].push(commentsFeedId);
    emit FeedPostAdded(postRequest.feedId, objectId, post);
    lastFeedPostIds[postRequest.feedId].increment();
  }

  function addFeedPost(PostRequest memory postRequest) external {
    _addFeedPost(postRequest);
  }

  function addBatchFeedPosts(PostRequest[] memory batchPosts) public {
    uint256 length = batchPosts.length;
    for (uint8 i = 0; i < length; ) {
      PostRequest memory post = batchPosts[i];
      _addFeedPost(post);

      unchecked {
        ++i;
      }
    }
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

  function batchReactionsAndPosts(
    PostRequest[] memory batchPosts,
    ReactionRequest[] memory batchReactionsToAdd,
    ReactionRemoveRequest[] memory batchReactionsToRemove
  ) external {
    addBatchFeedPosts(batchPosts);
    addBatchReactions(batchReactionsToAdd);
    removeBatchReactions(batchReactionsToRemove);
  }

  function migrateLegacyData(
    LegacyPost[] memory legacyPosts,
    LegacyReaction[] memory legacyReactions
  ) external onlyOwner onlyIfLoadingAllowed {
    _addFeedLegacyPostsBatch(legacyPosts);
    _addFeedLegacyReactionsBatch(legacyReactions);
  }

  function _addFeedLegacyPostsBatch(LegacyPost[] memory legacyPosts) private {
    uint256 length = legacyPosts.length;
    for (uint8 i = 0; i < length; ) {
      LegacyPost memory legacyPost = legacyPosts[i];
      uint256 commentsFeedId = addFeed(legacyPost.post.metadata);
      Post memory post = Post(
        legacyPost.post.author,
        legacyPost.post.metadata,
        commentsFeedId,
        legacyPost.post.timestamp
      );
      uint256 objectId = lastFeedPostIds[legacyPost.feedId].current();
      posts[commentsFeedId] = post;
      feedPosts[legacyPost.feedId].push(commentsFeedId);
      emit FeedPostAdded(legacyPost.feedId, objectId, post);
      lastFeedPostIds[legacyPost.feedId].increment();
      unchecked {
        ++i;
      }
    }
  }

  function _addFeedLegacyReactionsBatch(
    LegacyReaction[] memory legacyReactions
  ) private {
    uint256 length = legacyReactions.length;
    for (uint8 i = 0; i < length; ) {
      LegacyReaction memory legacyReaction = legacyReactions[i];
      Reaction memory reaction = Reaction(
        legacyReaction.reaction.postId,
        legacyReaction.reaction.reactionType,
        legacyReaction.reaction.value,
        legacyReaction.reaction.reactionOwner
      );
      lastReactionIds[legacyReaction.reaction.postId].increment();
      uint256 reactionId = lastReactionIds[legacyReaction.reaction.postId]
        .current();
      reactions[legacyReaction.reaction.postId][reactionId] = reaction;
      reactionsUserToId[legacyReaction.reaction.postId][
        legacyReaction.reaction.reactionOwner
      ] = reactionId;
      if (msg.value > 0) {
        payable(legacyReaction.reaction.reactionOwner).transfer(msg.value);
      }
      emit ReactionAdded(
        legacyReaction.reaction.reactionOwner,
        legacyReaction.reaction.postId,
        legacyReaction.reaction.reactionType,
        reactionId,
        0
      );
      unchecked {
        ++i;
      }
    }
  }

  function lockDataMigration() external onlyOwner {
    isDataMigrationLocked = true;
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

  function _msgSender()
    internal
    view
    override(ContextUpgradeable, ERC2771Recipient)
    returns (address sender)
  {
    sender = ERC2771Recipient._msgSender();
  }

  function _msgData()
    internal
    view
    override(ContextUpgradeable, ERC2771Recipient)
    returns (bytes calldata ret)
  {
    return ERC2771Recipient._msgData();
  }
}
