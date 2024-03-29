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

import "@opengsn/contracts/src/ERC2771Recipient.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./Kred.sol";
import "./Profiles.sol";
import "./Feeds.sol";

/**
 * @title OBSSStorage
 * @dev This contract is used to store the data of the OBSS contract
 */
contract OBSSStorage is OwnableUpgradeable, ERC2771Recipient {
  // State
  string public version;
  /// @custom:oz-renamed-from karma
  Kred public kred;
  Profiles public profiles;
  Feeds public feeds;
  /// @custom:oz-renamed-from karmaGranted
  mapping(uint feedId => mapping(uint postId => mapping(uint commentId => mapping(address sender => bool))))
    public kredGranted;

  // Constructor
  function initialize(
    address _forwarder,
    string calldata _version,
    address _kred,
    address _profiles,
    address _feeds
  ) public initializer {
    // Call parent initializers
    __Ownable_init();
    // Set forwarder for OpenGSN
    _setTrustedForwarder(_forwarder);
    // Set version
    version = _version;
    // Set sub-contracts
    kred = Kred(_kred);
    profiles = Profiles(_profiles);
    feeds = Feeds(_feeds);
  }

  // Setters

  function setKredContract(address _kred) public onlyOwner {
    kred = Kred(_kred);
  }

  function setProfilesContract(address _profiles) public onlyOwner {
    profiles = Profiles(_profiles);
  }

  function setFeedsContract(address _feeds) public onlyOwner {
    feeds = Feeds(_feeds);
  }

  function setTrustedForwarder(address _forwarder) public onlyOwner {
    _setTrustedForwarder(_forwarder);
  }

  function setVersion(string calldata _version) public onlyOwner {
    version = _version;
  }

  // Profiles

  function setProfile(CID calldata profileMetadata) external {
    profiles.setProfile(_msgSender(), profileMetadata);
  }

  function addProfilePost(CID calldata postMetadata) external {
    uint feedId = uint(keccak256(abi.encodePacked(_msgSender())));
    profiles.addPost(_msgSender(), PostRequest(feedId, postMetadata));
    kred.mint(_msgSender(), 5);
  }

  function pinOrUnpinProfilePost(uint postId, bool pin) public {
    uint feedId = uint(keccak256(abi.encodePacked(_msgSender())));
    profiles.pinOrUnpinPost(_msgSender(), feedId, postId, pin);
  }

  function addProfileComment(CommentRequest calldata commentRequest) external {
    profiles.addComment(_msgSender(), commentRequest);
    kred.mint(_msgSender(), 5);
  }

  function addProfileReaction(
    AddReactionRequest calldata reactionRequest
  ) external payable {
    profiles.addReaction(_msgSender(), reactionRequest);
    grantKred(reactionRequest);
  }

  function removeProfileReaction(
    RemoveReactionRequest calldata reactionRequest
  ) external {
    profiles.removeReaction(_msgSender(), reactionRequest);
  }

  // Feeds

  function addFeedPost(PostRequest calldata postRequest) public {
    feeds.addPost(_msgSender(), postRequest);
    kred.mint(_msgSender(), 5);
  }

  function pinOrUnpinFeedPost(uint feedId, uint postId, bool pin) public {
    feeds.pinOrUnpinPost(_msgSender(), feedId, postId, pin);
  }

  function addBatchFeedPosts(PostRequest[] calldata postRequests) public {
    for (uint i = 0; i < postRequests.length; i++) {
      addFeedPost(postRequests[i]);
    }
  }

  function addFeedComment(CommentRequest calldata commentRequest) public {
    feeds.addComment(_msgSender(), commentRequest);
    kred.mint(_msgSender(), 5);
  }

  function addBatchFeedComments(
    CommentRequest[] calldata commentRequests
  ) public {
    for (uint i = 0; i < commentRequests.length; i++) {
      addFeedComment((commentRequests[i]));
    }
  }

  function addFeedReaction(
    AddReactionRequest calldata reactionRequest
  ) public payable {
    feeds.addReaction(_msgSender(), reactionRequest);
    grantKred(reactionRequest);
  }

  function removeFeedReaction(
    RemoveReactionRequest calldata reactionRequest
  ) public {
    feeds.removeReaction(_msgSender(), reactionRequest);
  }

  function batchAddRemoveReactions(
    AddReactionRequest[] calldata addReactionRequests,
    RemoveReactionRequest[] calldata removeReactionRequests
  ) public {
    for (uint i = 0; i < addReactionRequests.length; i++) {
      addFeedReaction(addReactionRequests[i]);
    }
    for (uint i = 0; i < removeReactionRequests.length; i++) {
      removeFeedReaction(removeReactionRequests[i]);
    }
  }

  function batchFeedAddPostsCommentsReactions(
    PostRequest[] calldata postRequests,
    CommentRequest[] calldata commentRequests,
    AddReactionRequest[] calldata addReactionRequests,
    RemoveReactionRequest[] calldata removeReactionRequests
  ) external {
    addBatchFeedPosts(postRequests);
    addBatchFeedComments(commentRequests);
    batchAddRemoveReactions(addReactionRequests, removeReactionRequests);
  }

  // Kred

  function grantKred(AddReactionRequest calldata reactionRequest) internal {
    Post memory post = feeds.getPost(
      reactionRequest.feedId,
      reactionRequest.postId
    );
    if (
      !kredGranted[reactionRequest.feedId][reactionRequest.postId][
        reactionRequest.commentId
      ][_msgSender()] &&
      post.author != _msgSender() &&
      reactionRequest.reactionType == 1
    ) {
      kredGranted[reactionRequest.feedId][reactionRequest.postId][
        reactionRequest.commentId
      ][_msgSender()] = true;
      kred.mint(post.author, 5);
    }
  }

  // OpenGSN boilerplate

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
