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
   * @param _version Version of the contract
   */
  constructor(string memory _version) Versioned(_version) {}

  /**
   * @dev Add a new category
   * @param _category The category to add
   */
  function addCategory(CID memory _category) external {
    uint256 categoryId = lastCategoryId.current();
    categories.push(_category);
    emit CategoryAdded(categoryId, _category);
    lastCategoryId.increment();
  }

  /**
   * @dev Add a new category post
   * @param categoryId The category id
   * @param _postMetadata The post metadata to add
   */
  function addCategoryPost(uint256 categoryId, CID memory _postMetadata)
    external
  {
    Post memory post = Post(msg.sender, _postMetadata);
    uint256 objectId = lastCategoryPostIds[categoryId].current();
    categoryPosts[categoryId].push(post);
    emit CategoryPostAdded(categoryId, objectId, post);
    lastCategoryPostIds[categoryId].increment();
  }

  /**
   * @dev Add a new profile
   * @param _profile The profile to add
   */
  function addProfile(CID memory _profile) external {
    profiles[msg.sender] = _profile;
    emit ProfileAdded(msg.sender, _profile);
  }

  /**
   * @dev Add a new profile post
   * @param _postMetadata The post metadata to add
   */
  function addProfilePost(CID memory _postMetadata) external {
    Post memory post = Post(msg.sender, _postMetadata);
    uint256 objectId = lastProfilePostIds[msg.sender].current();
    profilePosts[msg.sender].push(post);
    emit ProfilePostAdded(msg.sender, objectId, post);
    lastProfilePostIds[msg.sender].increment();
  }

  /**
   * @dev Change the subscriptions of a user
   * @param _subscriptions The subscriptions to add
   */
  function changeSubscriptions(CID memory _subscriptions) external {
    subscriptions[msg.sender] = _subscriptions;
    emit SubsciptionsChanged(msg.sender, _subscriptions);
  }

  /**
   * @dev Add a reaction
   * @param _categoryOrProfileId The category or profile id
   * @param _postId The post id
   * @param _reactionType The reaction type
   */
  function addReaction(
    uint256 _categoryOrProfileId,
    uint256 _postId,
    uint8 _reactionType
  ) external payable {
    Post memory post = categoryPosts[_categoryOrProfileId][_postId];
    if (post.author == address(0)) {
      revert("Post not found");
    }
    Reaction memory reaction = Reaction(_reactionType, msg.value);
    reactions[post.metadata.digest][msg.sender] = reaction;
    if (msg.value > 0) {
      payable(post.author).transfer(msg.value);
    }
    emit ReactionAdded(
      msg.sender,
      _categoryOrProfileId,
      _postId,
      _reactionType,
      msg.value
    );
  }

  /**
   * @dev Remove a reaction
   * @param _categoryOrProfileId The category or profile id
   * @param _postId The post id
   */
  function removeReaction(uint256 _categoryOrProfileId, uint256 _postId)
    external
  {
    Post memory post = categoryPosts[_categoryOrProfileId][_postId];
    if (post.author == address(0)) {
      revert("Post not found");
    }
    delete reactions[post.metadata.digest][msg.sender];
    emit ReactionRemoved(msg.sender, _categoryOrProfileId, _postId);
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
