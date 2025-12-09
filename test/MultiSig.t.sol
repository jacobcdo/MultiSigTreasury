// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MultiSigTreasury.sol";

contract MultiSigTest is Test {
    MultiSigTreasury multisig;

    address owner1;
    address owner2;
    address owner3;
    address recipient;

    // <-- NEW: owners array as a state variable
    address[] owners;

    function setUp() public {
        // Setup test addresses
        owner1 = address(0xA1);
        owner2 = address(0xA2);
        owner3 = address(0xA3);
        recipient = address(0xB1);

        // Give owners ETH so they can send transactions
        vm.deal(owner1, 10 ether);
        vm.deal(owner2, 10 ether);
        vm.deal(owner3, 10 ether);

        // Initialize the owners array (length 3)
        owners = new address[](3);
        owners[0] = owner1;
        owners[1] = owner2;
        owners[2] = owner3;

        // Deploy multisig with 3 owners and threshold = 2
        multisig = new MultiSigTreasury(owners, 2);

        // Fund the multisig itself
        vm.deal(address(multisig), 5 ether);
    }

    function testProposeApproveExecute() public {
        // --- Step 1: Propose transaction ---
        vm.prank(owner1); // owner1 calls next function
        uint256 txId = multisig.proposeTransaction(
            recipient,
            1 ether,
            ""
        );

        // --- Step 2: Approve by owner1 ---
        vm.prank(owner1);
        multisig.approveTransaction(txId);

        // --- Step 3: Approve by owner2 ---
        vm.prank(owner2);
        multisig.approveTransaction(txId);

        // Record recipient initial balance
        uint256 beforeBalance = recipient.balance;

        // --- Step 4: Execute transaction ---
        vm.prank(owner1); // any owner can execute
        multisig.executeTransaction(txId);

        // Check ETH was transferred
        assertEq(recipient.balance, beforeBalance + 1 ether);
    }
}
