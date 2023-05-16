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
pragma solidity ^0.8.20;

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
    profiles.addPost(_msgSender(), feedId, postMetadata);
  }

  function addProfileComment(
    uint feedId,
    uint postId,
    uint replyTo,
    CID memory commentMetadata
  ) external {
    profiles.addComment(_msgSender(), feedId, postId, replyTo, commentMetadata);
  }

  function addProfileReaction(
    uint feedId,
    uint postId,
    uint commentId,
    uint8 reactionType
  ) external payable {
    profiles.addReaction(_msgSender(), feedId, postId, commentId, reactionType);
  }

  function removeProfileReaction(
    uint feedId,
    uint postId,
    uint commentId,
    uint reactionId
  ) external {
    profiles.removeReaction(
      _msgSender(),
      feedId,
      postId,
      commentId,
      reactionId
    );
  }

  // Feeds

  function addFeedPost(uint feedId, CID memory postMetadata) external {
    feeds.addPost(_msgSender(), feedId, postMetadata);
  }

  function addFeedComment(
    uint feedId,
    uint postId,
    uint replyTo,
    CID memory commentMetadata
  ) external {
    feeds.addComment(_msgSender(), feedId, postId, replyTo, commentMetadata);
  }

  function addFeedReaction(
    uint feedId,
    uint postId,
    uint commentId,
    uint8 reactionType
  ) external payable {
    feeds.addReaction(_msgSender(), feedId, postId, commentId, reactionType);
  }

  function removeFeedReaction(
    uint feedId,
    uint postId,
    uint commentId,
    uint reactionId
  ) external {
    feeds.removeReaction(_msgSender(), feedId, postId, commentId, reactionId);
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
