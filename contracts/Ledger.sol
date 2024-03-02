// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./LedgerUpgradable.sol";
import "./SafeMath.sol";
import "./ConvertString.sol";
import "./Tracker.sol";

contract Ledger is Initializable, LedgerUpgradeable, PausableUpgradeable, OwnableUpgradeable {
    using SafeMath for uint256;
    using ConvertString for uint256;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) public _trackers;
    address[] public _trackerList;
    address private _token;
    address private _admin;
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    modifier authSender() {
        require((owner() == _msgSender() || _token == _msgSender()), "Ownable: caller is not the owner");
        _;
    }
    function initialize(string memory name_, string memory symbol_) initializer public {
        __Ledger_init(name_, symbol_);
        __Pausable_init();
        __Ownable_init();
        _token = address(this);
        _admin = address(_msgSender());
    }
    function pause() public authSender {
        _pause();
    }
    function unpause() public authSender {
        _unpause();
    }
    function totalSupply() public view returns (uint256) {
        return _trackerList.length;
    }
    function getTrackerAddress(uint256 code_) public view returns (address) {
        return _trackers[code_];
    }
    function getTrackerBalance(address address_, address account_) public view returns (uint256) {
        Tracker tracker = Tracker(payable(address_));
        return tracker.getAccountBalanceOf(account_);
    }
    function getTrackerSupply(address address_) public view returns (uint256) {
        Tracker tracker = Tracker(payable(address_));
        return tracker.totalSupply();
    }
    function getTrackerFieldString(address address_, string memory key_) public view returns (string memory) {
        Tracker tracker = Tracker(payable(address_));
        return tracker.getFieldString(key_);
    }
    function getTrackerFieldNumber(address address_, string memory key_) public view returns (uint256) {
        Tracker tracker = Tracker(payable(address_));
        return tracker.getFieldNumber(key_);
    }
    function getTrackerFieldAddress(address address_, string memory key_) public view returns (address) {
        Tracker tracker = Tracker(payable(address_));
        return tracker.getFieldAddress(key_);
    }
    function setTrackerFieldString(address address_, string memory key_, string memory value_) public authSender {
        Tracker tracker = Tracker(payable(address_));
        return tracker.setFieldString(key_, value_);
    }
    function setTrackerFieldNumber(address address_, string memory key_, uint256 value_) public authSender {
        Tracker tracker = Tracker(payable(address_));
        return tracker.setFieldNumber(key_, value_);
    }
    function setTrackerFieldAddress(address address_, string memory key_, address value_) public authSender {
        Tracker tracker = Tracker(payable(address_));
        return tracker.setFieldAddress(key_, value_);
    }
    function increaseBalance(address address_, address account_, uint256 balance_) public authSender returns (uint256){
        Tracker tracker = Tracker(payable(address_));
        return tracker.increaseBalance(account_, balance_);
    }
    function decreaseBalance(address address_, address account_, uint256 balance_) public authSender returns (uint256){
        Tracker tracker = Tracker(payable(address_));
        return tracker.decreaseBalance(account_, balance_);
    }
    function addTracker(uint256 code_) public authSender returns (address){
        string memory codeString = ConvertString.toStr(code_);
        Tracker tracker = new Tracker(codeString, codeString, _token);
        address address_ = address(tracker);
        _trackers[code_] = address_;
        _trackerList.push(address_);
        return address_;
    }
    function getListTracker(uint limit_, uint page_) public view returns (address[] memory) {
        uint listCount = _trackerList.length;

        uint rowStart = 0;
        uint rowEnd = 0;
        uint rowCount = listCount;
        bool pagination = false;

        if (limit_ > 0 && page_ > 0){
            rowStart = (page_ - 1) * limit_;
            rowEnd = (rowStart + limit_) - 1;
            pagination = true;
            rowCount = limit_;
        }

        address[] memory _arrTrackers = new address[](rowCount);

        uint id = 0;
        uint j = 0;

        if (listCount > 0){
            for (uint i = 0; i < listCount; i++) {
                bool insert = !pagination;
                if (pagination){
                    if (j >= rowStart && j <= rowEnd){
                        insert = true;
                    }
                }
                if (insert){
                    _arrTrackers[id] = _trackerList[i];
                    id++;
                }
                j++;
            }
        }

        return (_arrTrackers);
    }
    function getListTrx(uint256 code_, address account_) public view returns (uint256[] memory, uint256[] memory, uint256[] memory) {
        Tracker tracker = Tracker(payable(getTrackerAddress(code_)));
        return tracker.getListTrx(account_);
    }
    function getTrxCount(uint256 code_, address account_) public view returns (uint256) {
        Tracker tracker = Tracker(payable(getTrackerAddress(code_)));
        return tracker.getTrxCount(account_);
    }
    function setTokenAddress(address address_) public authSender {
        _token = address_;
        if (_trackerList.length > 0){
            for (uint i = 0; i < _trackerList.length; i++) {
                address _arrTrackers = _trackerList[i];
                Tracker tracker = Tracker(payable(_arrTrackers));
                tracker.setToken(_token);
            }
        }
    }
    function getAdminAddress() public view returns (address) {
        return _admin;
    }
    function setAdminAddress(address address_) public authSender {
        _admin = address_;
    }
    function withdraw(address address_) public authSender {
        address account_ = address(this);
        uint256 amount_ = IERC20Upgradeable(address_).balanceOf(account_);
        require(amount_ >= 0, "ERC20: insufficient balance");
        IERC20Upgradeable(address_).transfer(_admin, amount_);
    }
    receive() external payable {}
}
