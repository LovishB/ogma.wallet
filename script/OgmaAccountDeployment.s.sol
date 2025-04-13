// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {OgmaAccountFactory} from "src/OgmaAccountFactory.sol";

contract OgmaAccountScript is Script {

    function run() public {
        deployOgmaAccount();
    }

    function deployOgmaAccount() public returns (HelperConfig, OgmaAccountFactory) {
        HelperConfig helperConfig = new HelperConfig();
        (uint256 deployerKey,,) = helperConfig.activeNetworkConfig();

        vm.startBroadcast(deployerKey);
        OgmaAccountFactory ogmaAccount = new OgmaAccountFactory();

        vm.stopBroadcast();
        return (helperConfig, ogmaAccount);
    }
}
