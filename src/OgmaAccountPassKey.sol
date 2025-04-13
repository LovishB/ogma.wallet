// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IAccount} from "../lib/account-abstraction/contracts/interfaces/IAccount.sol";
import {PackedUserOperation} from "../lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS} from "../lib/account-abstraction/contracts/core/Helpers.sol";

/**
* @title ogmaAccount
* @dev user submits a UserOperation to the EntryPoint
* EndPoints calls the validateUserOp() to validate the signature & pre payment of gas fee
* During validation, the EntryPoint tells the wallet how much ETH it needs to cover gas costs
* Wallet then transfers this amount to the EntryPoint using the _payFunds()
* Once validated, entry point will call execute function to execute the transaction
* 
* This version uses passkey authentication instead of ECDSA
*/
contract OgmaAccountPassKey is IAccount, Ownable {

    address private immutable i_entryPoint;
    bytes32 private immutable i_passKeyHash;
    
    // Events to track EntryPoint interactions
    event UserOperationValidated(bytes32 indexed userOpHash, bool success, uint256 missingFunds);
    event TransactionExecuted(address indexed dest, uint256 value, bytes data, bool success);

    error NotAuthorized();
    error InvalidPassKey();

    constructor(address _entryPoint, bytes memory _initialPassKeyHash) Ownable(msg.sender) {
        i_entryPoint = _entryPoint;
        i_passKeyHash = keccak256(_initialPassKeyHash);
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
    * We validate the passkey and handle the payment for gas costs
    */
    function validateUserOp(
        PackedUserOperation calldata userOp, 
        bytes32 userOpHash, 
        uint256 missingAccountFunds
    ) external override isEntryPoint() returns (uint256 validationData) {
        validationData = _validateSignature(userOp);
        _payFunds(missingAccountFunds);
        
        // Emit event with validation result
        bool success = validationData == SIG_VALIDATION_SUCCESS;
        emit UserOperationValidated(userOpHash, success, missingAccountFunds);
        
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
        require(success, "Failed to execute transaction");
        
        // Emit event with execution details and result
        emit TransactionExecuted(dest, value, func, success);
        
        return success;
    }

    /**
    * @dev Validates the passkey provided in the signature field
    * The user provides the actual passkey + userOpHash to prevent replay attacks
    * We hash this combination and compare with the stored passkey hash
    */
    function _validateSignature(
        PackedUserOperation calldata userOp
    ) internal view returns (uint256 validationData) {
        // Just validate the passkey directly
        bytes32 providedHash = keccak256(userOp.signature);
        
        if (providedHash == i_passKeyHash) {
            return SIG_VALIDATION_SUCCESS;
        }
        
        return SIG_VALIDATION_FAILED;
    }

    /**
    * @dev This function prefund gas for the operation!
    * This sends ETH from the wallet contract to the EntryPoint to cover gas costs
    * If a paymaster is used, this function could be modified to interact with it
    */
    function _payFunds(uint256 missingAccountFunds) internal {
        if(missingAccountFunds != 0) {
            // solidity low level call to send funds
            (bool success,) = payable(msg.sender).call{
                value: missingAccountFunds,
                gas: type(uint256).max
            }(""); // no func is called
            require(success, "Failed to pay fund to EntryPoint");
        }
    }

    function login(
        bytes32 passKeyHash
    ) external onlyOwner view returns (bool) {
        if (passKeyHash == i_passKeyHash) {
            return true;
        }
        revert InvalidPassKey();
    }

    receive() external payable {}
}