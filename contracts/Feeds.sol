// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./superclasses/KetlAllowMapChecker.sol";
import "./models/Post.sol";

contract Feeds is
  Initializable,
  ContextUpgradeable,
  OwnableUpgradeable,
  KetlAllowMapChecker
{
  using Counters for Counters.Counter;

  // Structs
  struct PostRequest {
    uint256 feedId;
    CID postMetadata;
  }

  // State
  CID[] public feeds;
  Counters.Counter public lastFeedId;
  mapping(uint256 => uint256[]) public feedPosts;
  mapping(uint256 => Counters.Counter) public lastFeedPostIds;

  // Events
  event FeedAdded(uint256 indexed id, CID metadata);
  event FeedPostAdded(
    uint256 indexed feedId,
    uint256 indexed postId,
    Post post
  );

  function initialize() public initializer {
    __Ownable_init();
  }

  function addFeed(CID memory feedMetadata) public onlyOwner returns (uint256) {
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
}
