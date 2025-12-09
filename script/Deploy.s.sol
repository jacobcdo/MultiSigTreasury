// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/MultiSigTreasury.sol";



contract Deploy is Script {

    address[] owners;

    function run() external {
        vm.startBroadcast();

        address owner1 = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        address owner2 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
        address owner3 = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;

        owners = new address[](3);
        owners[0] = owner1;
        owners[1] = owner2;
        owners[2] = owner3;

        MultiSigTreasury m = new MultiSigTreasury(owners, 2);

        console.log("Deployed multisig:", address(m));

        vm.stopBroadcast();
    }
}
