// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {OgmaAccountPassKey} from "./OgmaAccountPassKey.sol";

contract OgmaAccountFactory is Ownable {

    constructor() Ownable(msg.sender) {}

    function createAccount(
        address _entryPoint,
        bytes calldata _initialPassKeyHash
    ) external onlyOwner returns (address) {
        OgmaAccountPassKey account = new OgmaAccountPassKey(_entryPoint, _initialPassKeyHash);
        account.transferOwnership(msg.sender);
        return address(account);
    }

}