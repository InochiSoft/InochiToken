// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./DateTimeLib.sol";
import "./SafeMath.sol";
import "./ConvertString.sol";
import "./FactoryUpgradable.sol";
import "./ILedger.sol";

contract Factory is Initializable, FactoryUpgradable, PausableUpgradeable, OwnableUpgradeable {
    using SafeMath for uint256;
    using ConvertString for uint256;
    using DateTimeLib for uint;
    uint256 private constant MAX = ~uint256(0);

    mapping(address => mapping(address => uint256)) private _balances;
    mapping(address => mapping(address => uint256)) private _lockedUntils;
    mapping(address => mapping(address => uint256)) private _lockedBalances;

    mapping(address => address) public _ledgers;
    address[] public _ledgerList;
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    function initialize(string memory name_, string memory symbol_) initializer public {
        __Factory_init(name_, symbol_);
        __Pausable_init();
        __Ownable_init();
    }
    function pause() public onlyOwner {
        _pause();
    }
    function unpause() public onlyOwner {
        _unpause();
    }

    function dateToTimestamp(uint year, uint month, uint day, uint hour, uint minute) private pure returns (uint256) {
        bool valid = DateTimeLib.isValidDate(year, month, day);
        if (valid){
            return uint256(DateTimeLib.timestampFromDateTime(year, month, day, hour, minute, 0));
        }
        return 0;
    }
    function timestampToDate(uint timestamp) private pure returns (string memory) {
        (uint year, uint month, uint day, uint hour, uint minute, ) = DateTimeLib.timestampToDateTime(timestamp);

        string memory sYear = ConvertString.toStr(uint256(year));
        string memory sMonth = ConvertString.toStr(uint256(month));
        string memory sDay = ConvertString.toStr(uint256(day));
        string memory sHour = ConvertString.toStr(uint256(hour));
        string memory sMinute = ConvertString.toStr(uint256(minute));

        return string(abi.encodePacked(sYear, "-", sMonth, "-", sDay, " ", sHour, ":", sMinute));
    }

    /* Transactions Functions */
    function balanceOf(address address_, address account_) public view returns (uint256) {
        return _balances[address_][account_];
    }
    function myBalance(address address_) public view returns (uint256) {
        return _balances[address_][_msgSender()];
    }
    function lockedBalance(address address_, address account_) public view returns (uint256) {
        return _lockedBalances[address_][account_];
    }
    function myLockedBalance(address address_) public view returns (uint256) {
        return _lockedBalances[address_][_msgSender()];
    }
    function _freeBalance(address address_, address account_) private returns (uint256) {
        uint256 allBalance_ = _balances[address_][account_];
        uint256 lockedUntil_ = _lockedUntils[address_][account_];
        uint256 lockedBalance_ = _lockedBalances[address_][account_];

        uint256 free = 0;
        if (block.timestamp >= lockedUntil_) {
            _lockedBalances[address_][account_] = 0;
            free = allBalance_;
        } else {
            free = allBalance_.sub(lockedBalance_);
        }

        return free;
    }
    function _depositToken(address address_, uint256 amount_) internal whenNotPaused returns (uint256)  {
        require(amount_ >= 0, "ERC20: insufficient balance");
        IERC20Upgradeable(address_).transferFrom(_msgSender(), address(this), amount_);
        _balances[address_][_msgSender()] = _balances[address_][_msgSender()].add(amount_);
        return _balances[address_][_msgSender()];
    }
    function _sendToken(address address_, uint256 amount_, address recipient_) internal whenNotPaused returns (uint256) {
        address account_ = _msgSender();
        uint256 freeBalance_ = _freeBalance(address_, account_);
        require(freeBalance_ >= amount_, "ERC20: insufficient balance");
        IERC20Upgradeable(address_).transfer(recipient_, amount_);
        _balances[address_][account_] = _balances[address_][account_].sub(amount_);
        return _balances[address_][account_];
    }
    function _spendToken(address address_, uint256 amount_, address recipient_) internal whenNotPaused returns (uint256) {
        require(recipient_ != address(0), "ERC20: transfer to the zero address");
        address account_ = _msgSender();
        uint256 freeBal = _freeBalance(address_, account_);
        if (freeBal < amount_) {
            uint256 newAmount = amount_.sub(freeBal);
            _depositToken(address_, newAmount);
        }
        uint256 oldBal = _balances[address_][account_];
        uint256 newBal = _sendToken(address_, amount_, recipient_);
        uint256 spendBal = oldBal.sub(newBal);
        return spendBal;
    }
    function deposit(address address_, uint256 amount_) public returns (uint256) {
        return _depositToken(address_, amount_);
    }
    function send(address address_, uint256 amount_, address recipient_) public returns (uint256) {
        return _sendToken(address_, amount_, recipient_);
    }
    function spend(address address_, uint256 amount_, address recipient_) public returns (uint256) {
        return _spendToken(address_, amount_, recipient_);
    }
    function withdraw(address address_, uint256 amount_) public returns (uint256) {
        address account_ = _msgSender();
        uint256 balance_ = _freeBalance(address_, account_);
        require(balance_ >= amount_, "ERC20: insufficient balance");
        return _sendToken(address_, amount_, account_);
    }
    function withdrawAll(address address_) public returns (uint256) {
        address account_ = _msgSender();
        uint256 amount_ = _freeBalance(address_, account_);
        require(amount_ >= 0, "ERC20: insufficient balance");
        return _sendToken(address_, amount_, account_);
    }

    /* Lock Functions */
    function lock(address address_, uint256 amount_, uint year_, uint month_, uint day_, uint hour_, uint minute_) public {
        address account_ = _msgSender();
        uint256 balance_ = _balances[address_][account_];
        uint256 lockedUntil_ = _lockedUntils[address_][account_];
        require(balance_ >= amount_, "ERC20: insufficient balance");
        uint256 until_ = dateToTimestamp(year_, month_, day_, hour_, minute_);
        require(until_ >= block.timestamp, "ERC20: Change to newer date time");
        require(until_ >= lockedUntil_, "ERC20: Relocking only allowed beyond current lock period");

        _lockedUntils[address_][account_] = until_;
        _lockedBalances[address_][account_] = amount_;
    }
    function lockAll(address address_, uint year_, uint month_, uint day_, uint hour_, uint minute_) public {
        address account_ = _msgSender();
        uint256 balance_ = _balances[address_][account_];
        uint256 lockedUntil_ = _lockedUntils[address_][account_];
        uint256 until_ = dateToTimestamp(year_, month_, day_, hour_, minute_);
        require(until_ >= lockedUntil_, "ERC20: Relocking only allowed beyond current lock period");

        _lockedUntils[address_][account_] = until_;
        _lockedBalances[address_][account_] = balance_;
    }
    function unlockDate(address address_) public view returns (string memory) {
        address account_ = _msgSender();
        uint256 lockedUntil_ = _lockedUntils[address_][account_];
        return timestampToDate(uint256(lockedUntil_));
    }

    /* Ledger Functions */
    function addLedger(address address_, address pool_) public onlyOwner returns (bool) {
        _ledgers[address_] = pool_;
        uint rowCount = _ledgerList.length;
        bool blnInsert = true;
        if (rowCount > 0){
            for (uint i = 0; i < rowCount; i++) {
                if ( _ledgerList[i] == address_){
                    blnInsert = false;
                    break;
                }
            }
        }
        if (blnInsert) {
            _ledgerList.push(address_);
        }
        return blnInsert;
    }
    function deleteLedger(address address_) public onlyOwner {
        _ledgers[address_] = address(0);
        uint rowCount = _ledgerList.length;
        if (rowCount > 0){
            for (uint i = 0; i < rowCount; i++) {
                if ( _ledgerList[i] == address_){
                    delete _ledgerList[i];
                    break;
                }
            }
        }
    }
    function getLedgerPool(address address_) public view returns (address) {
        return _ledgers[address_];
    }
    function setLedgerPool(address address_, address payable pool_) public virtual onlyOwner {
        _ledgers[address_] = pool_;
    }
    function getListLedger() public view returns (address[] memory) {
        uint rowCount = _ledgerList.length;
        address[] memory _arrLedgers = new address[](rowCount);
        if (rowCount > 0){
            for (uint i = 0; i < rowCount; i++) {
                _arrLedgers[i] = _ledgerList[i];
            }
        }
        return _arrLedgers;
    }

    receive() external payable {}
}
