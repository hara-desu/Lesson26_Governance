// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {Governance} from "../src/Governance.sol";
import {MyToken} from "../src/MyToken.sol";

contract DeployGovernance is Script {
    Governance public governance;
    MyToken public myToken;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        myToken = new MyToken();
        governance = new Governance(myToken);
        vm.stopBroadcast();
    }
}

contract DeployGovernanceSepolia is Script {
    function run() external {
        require(
            block.chainid == 11155111,
            "DeployGovernanceSepolia: wrong network (not Sepolia)"
        );

        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerKey);
        MyToken myToken = new MyToken();
        Governance governance = new Governance(myToken);
        vm.stopBroadcast();

        console2.log("Sepolia MyToken:     %s", address(myToken));
        console2.log("Sepolia Governance:  %s", address(governance));
        console2.log("Deployer:            %s", vm.addr(deployerKey));
        console2.log("Chain ID:            %s", block.chainid);
    }
}
