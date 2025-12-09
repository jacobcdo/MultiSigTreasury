// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IMultiSigTreasury} from "./interface_MultiSigTreasury.sol";

contract MultiSigTreasury is IMultiSigTreasury {

    // variables, threshold for how many approvals needed
    address[] private owners; 
    mapping(address => bool) private ownerExists; 
    uint256 private threshold; 

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 approvalCount;
    }

    Transaction[] private transactions;

    // approval tracking, per transaction per owner
    mapping(uint256 => mapping(address => bool)) private hasApproved;

    event TransactionProposed(uint256 txId, address proposer);
    event TransactionApproved(uint256 txId, address owner);
    event ApprovalRevoked(uint256 txId, address owner);
    event TransactionExecuted(uint256 txId);

    event OwnerAdded(address newOwner);
    event OwnerRemoved(address removedOwner);
    event ThresholdChanged(uint256 newThreshold);

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _onlyOwner() internal view {
        require(ownerExists[msg.sender], "Not an owner");
    }

    modifier txExists(uint256 txId) {
        _txExists(txId);
        _;
    }

    function _txExists(uint256 txId) internal view {
        require(txId < transactions.length, "Tx does not exist");
    }

    modifier notExecuted(uint256 txId) {
        _notExecuted(txId);
        _;
    }

    function _notExecuted(uint256 txId) internal view {
        require(!transactions[txId].executed, "Already executed");
    }

    // Constructors

    constructor(address[] memory _owners, uint256 _threshold) {
        require(_owners.length > 0, "No owners provided");
        require(_threshold > 0 && _threshold <= _owners.length, "Invalid threshold");

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Owner cannot be zero");
            require(!ownerExists[owner], "Duplicate owner");

            ownerExists[owner] = true;
            owners.push(owner);
        }

        threshold = _threshold;
    }

function proposeTransaction(address to, uint256 value, bytes calldata data)
    external
    onlyOwner
    returns (uint256 txId)
{
    require(to != address(0), "Invalid address");

    Transaction memory newTx;
    newTx.to = to;
    newTx.value = value;

    newTx.data = data;

    newTx.approvalCount = 1;

    transactions.push(newTx);

    txId = transactions.length - 1;

    emit TransactionProposed(txId, msg.sender);
}

    function approveTransaction(uint256 txId) external onlyOwner txExists(txId) notExecuted(txId) {
        // Prevent double approvals
        require(!hasApproved[txId][msg.sender], "Already approved");

        hasApproved[txId][msg.sender] = true;

        transactions[txId].approvalCount++;

        emit TransactionApproved(txId, msg.sender);
    }

    function revokeApproval(uint256 txId) external onlyOwner txExists(txId) notExecuted(txId) {
        require(hasApproved[txId][msg.sender], "Not approved yet");

        hasApproved[txId][msg.sender] = false;

        transactions[txId].approvalCount--;

        emit ApprovalRevoked(txId, msg.sender);
    }

    function executeTransaction(uint256 txId) external txExists(txId) notExecuted(txId) {
        Transaction storage txn = transactions[txId];

        // Check if enough approvals
        require(txn.approvalCount >= threshold, "Not enough approvals");

        //
        txn.executed = true;

        // Execute the transaction
        (bool success,) = txn.to.call{value: txn.value}(txn.data);
        require(success, "Transaction failed");

        emit TransactionExecuted(txId);
    }

    function addOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Owner cannot be zero");
        require(!ownerExists[newOwner], "Owner already exists");

        ownerExists[newOwner] = true;
        owners.push(newOwner);

        // Ensure threshold is still valid
        require(threshold <= owners.length, "Threshold too high");

        emit OwnerAdded(newOwner);
    }

    function removeOwner(address owner) external onlyOwner {
        require(ownerExists[owner], "Not an owner");
        require(owners.length > 1, "Cannot remove last owner");

        // Mark owner as removed
        ownerExists[owner] = false;

        // Remove from owners array
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                owners.pop(); 
                break;
            }
        }

        // Make sure threshold still valid
        if (threshold > owners.length) {
            threshold = owners.length;
            emit ThresholdChanged(threshold);
        }

        emit OwnerRemoved(owner);
    }

    // Change the approval threshold
    function changeThreshold(uint256 newThreshold) external onlyOwner {
        require(newThreshold > 0, "Threshold must be > 0");
        require(newThreshold <= owners.length, "Threshold too high");

        threshold = newThreshold;

        emit ThresholdChanged(newThreshold);
    }

    function getOwners() external view returns (address[] memory) {
        return owners;
    }

    function isOwner(address addr) external view returns (bool) {
        return ownerExists[addr];
    }

    receive() external payable {}
}
