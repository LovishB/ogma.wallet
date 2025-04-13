// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {OgmaAccount} from "src/OgmaAccount.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract OgmaAccountScript is Script {

    function run() public {
        deployOgmaAccount();
    }

    function deployOgmaAccount() public returns (HelperConfig, OgmaAccount) {
        HelperConfig helperConfig = new HelperConfig();
        (uint256 deployerKey, , address entryPoint) = helperConfig.activeNetworkConfig();

        vm.startBroadcast(deployerKey);
        OgmaAccount ogmaAccount = new OgmaAccount(entryPoint);
        ogmaAccount.transferOwnership(msg.sender);
        vm.stopBroadcast();
        return (helperConfig, ogmaAccount);
    }
}
