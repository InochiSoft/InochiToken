// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract FactoryUpgradable is Initializable, ContextUpgradeable {
    string private _prefixName;
    string private _prefixSymbol;
    string private _name;
    string private _symbol;
    function __Factory_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __Factory_init_unchained(name_, symbol_);
    }
    function __Factory_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _prefixName = "Factory ";
        _prefixSymbol = "FACTORY-";
        _name = string(abi.encodePacked(_prefixName, name_));
        _symbol = string(abi.encodePacked(_prefixSymbol, symbol_));
    }
    function name() public view virtual returns (string memory) {
        return _name;
    }
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }
    uint256[55] private __gap;
}
