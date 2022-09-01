// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

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
  // 0 = upvote, 1 = downvote
  struct Reaction {
    uint8 reactionType;
    uint256 value;
  }

  /* State */
  // Categories
  CID[] public categories;
  Counters.Counter public lastCategoryId;
  mapping(uint256 => Post[]) public categoryPosts;
  mapping(uint256 => Counters.Counter) public lastCategoryPostIds;
  // Profiles
  mapping(address => CID) public profiles;
  mapping(address => Post[]) public profilePosts;
  mapping(address => Counters.Counter) public lastProfilePostIds;
  mapping(address => CID) public subscriptions;
  // Reactions
  mapping(bytes32 => mapping(address => Reaction)) public reactions;

  /* Events */
  // Categories
  event CategoryAdded(uint256 indexed id, CID metadata);
  event CategoryPostAdded(
    uint256 indexed categoryId,
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
    uint256 indexed categoryOrProfileId,
    uint256 indexed postId,
    uint8 reactionType,
    uint256 value
  );
  event ReactionRemoved(
    address indexed user,
    uint256 indexed categoryOrProfileId,
    uint256 postId
  );

  /**
   * @dev Constructor
   * @param version Version of the contract
   */
  constructor(string memory version) Versioned(version) {}

  /**
   * @dev Add a new category
   * @param categoryMetadata The category to add
   */
  function addCategory(CID memory categoryMetadata) external {
    uint256 categoryId = lastCategoryId.current();
    categories.push(categoryMetadata);
    emit CategoryAdded(categoryId, categoryMetadata);
    lastCategoryId.increment();
  }

  /**
   * @dev Add a new category post
   * @param categoryId The category id
   * @param postMetadata The post metadata to add
   */
  function addCategoryPost(uint256 categoryId, CID memory postMetadata)
    external
  {
    Post memory post = Post(msg.sender, postMetadata);
    uint256 objectId = lastCategoryPostIds[categoryId].current();
    categoryPosts[categoryId].push(post);
    emit CategoryPostAdded(categoryId, objectId, post);
    lastCategoryPostIds[categoryId].increment();
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
   * @param categoryOrProfileId The category or profile id
   * @param postId The post id
   * @param reactionType The reaction type
   */
  function addReaction(
    uint256 categoryOrProfileId,
    uint256 postId,
    uint8 reactionType
  ) external payable {
    Post memory post = categoryPosts[categoryOrProfileId][postId];
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
      categoryOrProfileId,
      postId,
      reactionType,
      msg.value
    );
  }

  /**
   * @dev Remove a reaction
   * @param categoryOrProfileId The category or profile id
   * @param postId The post id
   */
  function removeReaction(uint256 categoryOrProfileId, uint256 postId)
    external
  {
    Post memory post = categoryPosts[categoryOrProfileId][postId];
    if (post.author == address(0)) {
      revert("Post not found");
    }
    delete reactions[post.metadata.digest][msg.sender];
    emit ReactionRemoved(msg.sender, categoryOrProfileId, postId);
  }

  /**
   * @dev Get the category posts
   */
  function getCategoryPosts(
    uint256 categoryId,
    uint256 skip,
    uint256 limit
  ) external view returns (Post[] memory) {
    Post[] memory posts = categoryPosts[categoryId];
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
}
