// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Tracker is Context, IERC20, IERC20Metadata, Ownable, Pausable {
    mapping(address => uint256) private _balances;
    uint256 private _totalSupply;
    string private _prefixName;
    string private _prefixSymbol;
    string private _name;
    string private _symbol;
    address private _token;
    struct TrxInfo {
        uint256 trxMode;
        address trxAccount;
        uint256 trxDate;
        uint256 trxAmount;
    }
    TrxInfo[] private _trxList;
    mapping (string => string) private _fieldStringMap;
    mapping (string => uint256) private _fieldNumberMap;
    mapping (string => address) private _fieldAddressMap;
    modifier authSender() {
        require((owner() == _msgSender() || _token == _msgSender()), "Ownable: caller is not the owner");
        _;
    }
    constructor(string memory name_, string memory symbol_, address token_) {
        _prefixName = "Tracker ";
        _prefixSymbol = "TRACKER-";
        _name = string(abi.encodePacked(_prefixName, name_));
        _symbol = string(abi.encodePacked(_prefixSymbol, symbol_));
        _token = token_;
    }
    function pause() public authSender {
        _pause();
    }
    function unpause() public authSender {
        _unpause();
    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual override returns (uint8) {
        return 0;
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        revert("INOERC20: method not implemented");
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        revert("INOERC20: method not implemented");
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        revert("INOERC20: method not implemented");
    }
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        revert("INOERC20: method not implemented");
    }
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
        _balances[from] = fromBalance - amount;
        // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
        // decrementing then incrementing.
        _balances[to] += amount;
    }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "INOERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
    unchecked {
        // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
        _balances[account] += amount;
    }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "INOERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "INOERC20: burn amount exceeds balance");
    unchecked {
        _balances[account] = accountBalance - amount;
        // Overflow not possible: amount <= accountBalance <= totalSupply.
        _totalSupply -= amount;
    }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }
    /*
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
    */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal whenNotPaused {}
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
    function _setBalance(address account_, uint256 newBalance_) private {
        uint256 currentBalance = _balances[account_];
        if(newBalance_ > currentBalance) {
            uint256 addAmount = newBalance_ - currentBalance;
            _mint(address(this), addAmount);
            _transfer(address(this), account_, addAmount);
        } else if(newBalance_ < currentBalance) {
            uint256 subAmount = currentBalance - newBalance_;
            _transfer(account_, address(this), subAmount);
            _burn(address(this), subAmount);
        }
    }
    function _increaseBalance(address account_, uint256 balance_) private {
        uint256 currBalance = _balances[account_];
        uint256 newBalance = currBalance + balance_;
        _setBalance(account_, newBalance);
    }
    function _decreaseBalance(address account_, uint256 balance_) private {
        uint256 currBalance = _balances[account_];
        uint256 newBalance = currBalance - balance_;
        require(newBalance >= 0, "ERR");
        _setBalance(account_, newBalance);
    }
    function increaseBalance(address account_, uint256 balance_) public onlyOwner returns (uint256) {
        _increaseBalance(account_, balance_);
        TrxInfo memory trxInfo = TrxInfo(1, account_, block.timestamp, balance_);
        _trxList.push(trxInfo);
        return _balances[account_];
    }
    function decreaseBalance(address account_, uint256 balance_) public onlyOwner returns (uint256) {
        _decreaseBalance(payable(account_), balance_);
        TrxInfo memory trxInfo = TrxInfo(2, account_, block.timestamp, balance_);
        _trxList.push(trxInfo);
        return _balances[account_];
    }
    function getAccountBalanceOf(address account_) public view returns (uint256) {
        return _balances[account_];
    }
    function setFieldString(string memory key_, string memory value_) public onlyOwner {
        _fieldStringMap[key_] = value_;
    }
    function getFieldString(string memory key_) public view returns (string memory) {
        return _fieldStringMap[key_];
    }
    function setFieldNumber(string memory key_, uint256 value_) public onlyOwner {
        _fieldNumberMap[key_] = value_;
    }
    function getFieldNumber(string memory key_) public view returns (uint256) {
        return _fieldNumberMap[key_];
    }
    function setFieldAddress(string memory key_, address value_) public onlyOwner {
        _fieldAddressMap[key_] = value_;
    }
    function getFieldAddress(string memory key_) public view returns (address) {
        return _fieldAddressMap[key_];
    }
    function getListTrx(address account_) public view returns (uint256[] memory, uint256[] memory, uint256[] memory) {
        uint rowCount = _trxList.length;

        uint256[] memory _modes = new uint256[](rowCount);
        uint256[] memory _dates = new uint256[](rowCount);
        uint256[] memory _amounts = new uint256[](rowCount);

        uint id = 0;

        for (uint i = 0; i < rowCount; i++) {
            address _account = _trxList[i].trxAccount;
            if (account_ == _account){
                _modes[id] = _trxList[i].trxMode;
                _dates[id] = _trxList[i].trxDate;
                _amounts[id] = _trxList[i].trxAmount;
                id++;
            }
        }
        return (_modes, _dates, _amounts);
    }
    function getTrxCount(address account_) public view returns (uint256) {
        uint256 result;
        for (uint i = 0; i < _trxList.length; i++) {
            address _account = _trxList[i].trxAccount;
            if (account_ == _account){
                result++;
            }
        }
        return result;
    }
    function setToken(address token_) public authSender {
        _token = token_;
    }
}
