// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IAccount} from "../lib/account-abstraction/contracts/interfaces/IAccount.sol";
import {PackedUserOperation} from "../lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {MessageHashUtils} from "../lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import {SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS} from "../lib/account-abstraction/contracts/core/Helpers.sol";

/**
* @title ogmaAccount
* @dev user submits a UserOperation to the EntryPoint
* EndPoints calls the validateUserOp() to validate the signature & pre payment of gas fee
* During validation, the EntryPoint tells the wallet how much ETH it needs to cover gas costs
* Wallet then transfers this amount to the EntryPoint using the _payFunds()
* Once validated, entry point will call execute function to execute the transaction
*/
contract OgmaAccount is IAccount, Ownable {

    address private immutable i_entryPoint;

    error NotAuthorized();

    constructor(address _entryPoint) Ownable(msg.sender) {
        i_entryPoint = _entryPoint;
    }

    modifier isEntryPoint() {
        if (msg.sender != i_entryPoint) {
            revert NotAuthorized();
        }
        _;
    }
    
    /**
    * @dev This function is called by the EntryPoint contract to validate a user operation
    * @param userOp The user operation to validate
    * @param userOpHash The hash of the user operation
    * @param missingAccountFunds The amount of funds the account needs to send to the EntryPoint
    * @return validationData Packed validation data (see SIG_VALIDATION constants)
    *
    * When client sends userOps to the EntryPoint, it will call this function to validate the userOps
    * We validate the signature and handle the payment for gas costs
    */
    function validateUserOp(
        PackedUserOperation calldata userOp, 
        bytes32 userOpHash, 
        uint256 missingAccountFunds
    ) external override isEntryPoint() returns (uint256 validationData) {
        validationData = _validateSignature(userOp, userOpHash);
        _payFunds(missingAccountFunds);
        return validationData;
    }


    /**
    * @dev Executes a transaction to an external contract
    * @param dest The address of the destination contract
    * @param value The amount of ETH to send with the transaction
    * @param func The calldata to send to the destination contract
    * @return success Whether the transaction was successful
    * 
    * This function can only be called by the EntryPoint
    * It allows the account to interact with other contracts as requested by the user
    */
    function execute(address dest, uint256 value, bytes calldata func) external isEntryPoint returns (bool) {
        (bool success, ) = dest.call{value: value}(func);
        require(success, "Failed to pay fund execute");
        return success;
    }

    /**
    * @dev Signature is valid if it is signed by the owner of the account    
    * First the userOp Hash is converted to signer message hash (\x19Ethereum Signed Message:\n32)
    * Secondly signer is recovered using EDCSA
    */
    function _validateSignature(
         PackedUserOperation calldata userOp,
        bytes32 userOpHash
    ) internal view returns (uint256 validationData) {
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(userOpHash);
        address signer = ECDSA.recover(ethSignedMessageHash, userOp.signature);
        if(signer!=owner()) {
            return SIG_VALIDATION_FAILED;
        }
        return SIG_VALIDATION_SUCCESS;
    }

    /**
    * @dev This function prefund gas for the operation!
    * This sends ETH from the wallet contract to the EntryPoint to cover gas costs
    * If a paymaster is used, this function could be modified to interact with it
    */
    function _payFunds(uint256 missingAccountFunds) internal {
        if(missingAccountFunds!=0) {
            // solidity low level call to send funds
            (bool success,) = payable(msg.sender).call{
                value: missingAccountFunds,
                gas: type(uint256).max
            }(""); //no func is called
            require(success, "Failed to pay fund to EntryPoint");
        }
    }

    receive() external payable {}
}
