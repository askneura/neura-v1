// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.28;

import {NeuraV1Factory} from "../src/NeuraV1Factory.sol";
import {NeuraV1Router} from "../src/NeuraV1Router.sol";

interface DeploymentVm {
    function startBroadcast() external;
    function stopBroadcast() external;
}

/// @notice Deployment preparation only. No networks or keys embedded.
/// @dev UNAUDITED. Default forge script runs as a local simulation, not a broadcast.
contract DeployNeuraV1 {
    DeploymentVm constant vm = DeploymentVm(address(uint160(uint256(keccak256("hevm cheat code")))));
    function run() external returns (NeuraV1Factory factory, NeuraV1Router router) {
        vm.startBroadcast();
        factory = new NeuraV1Factory();
        router = new NeuraV1Router(address(factory));
        vm.stopBroadcast();
    }
}