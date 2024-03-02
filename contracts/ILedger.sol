// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ILedger {
    function owner() external view returns (address);
    function addTracker(uint256 code_) external returns (address);
    function getTrackerAddress(uint256 code_) external returns (address);
    function getTrackerBalance(address address_, address account_) external view returns (uint256);
    function getTrackerSupply(address address_) external returns (uint256);
    function getTrackerFieldString(address address_, string memory key_) external view returns (string memory);
    function getTrackerFieldNumber(address address_, string memory key_) external view returns (uint256);
    function getTrackerFieldAddress(address address_, string memory key_) external view returns (address);
    function setTrackerFieldString(address address_, string memory key_, string memory value_) external;
    function setTrackerFieldNumber(address address_, string memory key_, uint256 value_) external;
    function setTrackerFieldAddress(address address_, string memory key_, address value_) external;
    function increaseBalance(address address_, address account_, uint256 balance_) external returns (uint256);
    function decreaseBalance(address address_, address account_, uint256 balance_) external returns (uint256);
    function getListTracker(uint limit_, uint page_) external view returns (address[] memory);
    function getListTrx(uint256 code_, address account_) external view returns (
        uint256[] memory, uint256[] memory, uint256[] memory
    );
    function transferOwnership(address newOwner) external;
}
