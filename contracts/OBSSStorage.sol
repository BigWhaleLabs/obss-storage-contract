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
import "./Karma.sol";
import "./Profiles.sol";
import "./Feeds.sol";

/**
 * @title OBSSStorage
 * @dev This contract is used to store the data of the OBSS contract
 */
contract OBSSStorage is OwnableUpgradeable, ERC2771Recipient {
  // State
  string public version;
  Karma public karma;
  Profiles public profiles;
  Feeds public feeds;
  mapping(uint => mapping(uint => mapping(uint => mapping(address => bool)))) karmaGranted;

  // Constructor
  function initialize(
    address _forwarder,
    string memory _version,
    address _karma,
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
    karma = Karma(_karma);
    profiles = Profiles(_profiles);
    feeds = Feeds(_feeds);
  }

  // Profiles

  function setProfile(CID memory profileMetadata) external {
    profiles.setProfile(_msgSender(), profileMetadata);
  }

  function addProfilePost(CID memory postMetadata) external {
    uint feedId = uint(keccak256(abi.encodePacked(_msgSender())));
    profiles.addPost(_msgSender(), PostRequest(feedId, postMetadata));
  }

  function addProfileComment(CommentRequest memory commentRequest) external {
    profiles.addComment(_msgSender(), commentRequest);
  }

  function addProfileReaction(
    AddReactionRequest memory reactionRequest
  ) external payable {
    profiles.addReaction(_msgSender(), reactionRequest);
    grantKarma(reactionRequest);
  }

  function removeProfileReaction(
    RemoveReactionRequest memory reactionRequest
  ) external {
    profiles.removeReaction(_msgSender(), reactionRequest);
  }

  // Feeds

  function addFeedPost(PostRequest memory postRequest) external {
    feeds.addPost(_msgSender(), postRequest);
  }

  function addBatchFeedPosts(PostRequest[] memory postRequests) public {
    for (uint i = 0; i < postRequests.length; i++) {
      feeds.addPost(_msgSender(), postRequests[i]);
    }
  }

  function addFeedComment(CommentRequest memory commentRequest) external {
    feeds.addComment(_msgSender(), commentRequest);
  }

  function addBatchFeedComments(
    CommentRequest[] memory commentRequests
  ) public {
    for (uint i = 0; i < commentRequests.length; i++) {
      feeds.addComment(_msgSender(), commentRequests[i]);
    }
  }

  function addFeedReaction(
    AddReactionRequest memory reactionRequest
  ) public payable {
    feeds.addReaction(_msgSender(), reactionRequest);
    grantKarma(reactionRequest);
  }

  function removeFeedReaction(
    RemoveReactionRequest memory reactionRequest
  ) public {
    feeds.removeReaction(_msgSender(), reactionRequest);
  }

  function batchAddRemoveReactions(
    AddReactionRequest[] memory addReactionRequests,
    RemoveReactionRequest[] memory removeReactionRequests
  ) public {
    for (uint i = 0; i < addReactionRequests.length; i++) {
      addFeedReaction(addReactionRequests[i]);
    }
    for (uint i = 0; i < removeReactionRequests.length; i++) {
      removeFeedReaction(removeReactionRequests[i]);
    }
  }

  function batchFeedAddPostsCommentsReactions(
    PostRequest[] memory postRequests,
    CommentRequest[] memory commentRequests,
    AddReactionRequest[] memory addReactionRequests,
    RemoveReactionRequest[] memory removeReactionRequests
  ) external {
    addBatchFeedPosts(postRequests);
    addBatchFeedComments(commentRequests);
    batchAddRemoveReactions(addReactionRequests, removeReactionRequests);
  }

  // Karma

  function grantKarma(AddReactionRequest memory reactionRequest) internal {
    if (
      !karmaGranted[reactionRequest.feedId][reactionRequest.postId][
        reactionRequest.commentId
      ][_msgSender()]
    ) {
      karmaGranted[reactionRequest.feedId][reactionRequest.postId][
        reactionRequest.commentId
      ][_msgSender()] = true;
      karma.mint(_msgSender(), 1);
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
