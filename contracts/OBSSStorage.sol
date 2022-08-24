// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title OBSSStorage
 * @dev This contract is used to store the data of the OBSS contract
 */
contract OBSSStorage is Ownable {
  using Counters for Counters.Counter;

  // State
  string public version;
  mapping(uint256 => bytes32) public categories;
  Counters.Counter public lastCategoryId;
  mapping(uint256 => bytes32[]) public objects;
  mapping(uint256 => Counters.Counter) public lastObjectIds;

  // Events
  event CategoryAdded(uint256 categoryId, bytes32 category);
  event ObjectAdded(uint256 categoryId, uint256 objectId, bytes32 object);

  /**
   * @dev Constructor
   * @param _version Version of the contract
   */
  constructor(string memory _version) {
    version = _version;
  }

  /**
   * @dev Add a new category
   * @param _category The category to add
   */
  function addCategory(bytes32 _category) external {
    uint256 categoryId = lastCategoryId.current();
    categories[categoryId] = _category;
    emit CategoryAdded(categoryId, _category);
    lastCategoryId.increment();
  }

  /**
   * @dev Add a new object
   * @param _categoryId The category id
   * @param _object The object to add
   */
  function addObject(uint256 _categoryId, bytes32 _object) external {
    uint256 objectId = lastObjectIds[_categoryId].current();
    objects[_categoryId].push(_object);
    emit ObjectAdded(_categoryId, objectId, _object);
    lastObjectIds[_categoryId].increment();
  }
}
