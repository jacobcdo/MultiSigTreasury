// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interface_MultiSigTreasury.sol";

contract MultiSigTreasury is IMultiSigTreasury {

    /*//////////////////////////////////////////////////////////////
                               STORAGE
    //////////////////////////////////////////////////////////////*/

    address[] private owners;                    // list of owners
    mapping(address => bool) private ownerExists; // quick owner lookup
    uint256 private threshold;                   // approvals required

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 approvalCount;
    }

    Transaction[] private transactions;

    // txId => owner => approved?
    mapping(uint256 => mapping(address => bool)) private hasApproved;


    /*//////////////////////////////////////////////////////////////
                               EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransactionProposed(uint256 txId, address proposer);
    event TransactionApproved(uint256 txId, address owner);
    event ApprovalRevoked(uint256 txId, address owner);
    event TransactionExecuted(uint256 txId);

    event OwnerAdded(address newOwner);
    event OwnerRemoved(address removedOwner);
    event ThresholdChanged(uint256 newThreshold);


    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyOwner() {
        require(ownerExists[msg.sender], "Not an owner");
        _;
    }

    modifier txExists(uint256 txId) {
        require(txId < transactions.length, "Tx does not exist");
        _;
    }

    modifier notExecuted(uint256 txId) {
        require(!transactions[txId].executed, "Tx already executed");
        _;
    }


    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address[] memory _owners, uint256 _threshold) {
        require(_owners.length > 0, "No owners provided");
        require(
            _threshold > 0 && _threshold <= _owners.length,
            "Invalid threshold"
        );

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Owner cannot be zero");
            require(!ownerExists[owner], "Duplicate owner");

            ownerExists[owner] = true;
            owners.push(owner);
        }

        threshold = _threshold;
    }


    /*//////////////////////////////////////////////////////////////
                        CORE MULTISIG LOGIC (TO IMPLEMENT)
    //////////////////////////////////////////////////////////////*/

    function proposeTransaction(address to, uint256 value, bytes calldata data)
        external
        onlyOwner
        returns (uint256 txId)
    {
        require(to != address(0), "Invalid address");

        Transaction memory newTx = Transaction({
            to: to,
            value: value,
            data: data,
            executed: false,
            approvalCount: 0
        });

        transactions.push(newTx);
        txId = transactions.length - 1;

        emit TransactionProposed(txId, msg.sender);
    }


function approveTransaction(uint256 txId)
    external
    onlyOwner
    txExists(txId)
    notExecuted(txId)
{
    // Prevent double approvals
    require(!hasApproved[txId][msg.sender], "Already approved");

    // Mark the approval
    hasApproved[txId][msg.sender] = true;

    // Increase approval count
    transactions[txId].approvalCount++;

    // Emit event
    emit TransactionApproved(txId, msg.sender);
}



function revokeApproval(uint256 txId)
    external
    onlyOwner
    txExists(txId)
    notExecuted(txId)
{
    // Must have approved before
    require(hasApproved[txId][msg.sender], "Not approved yet");

    // Remove approval
    hasApproved[txId][msg.sender] = false;

    // Reduce approval count
    transactions[txId].approvalCount--;

    // Emit event
    emit ApprovalRevoked(txId, msg.sender);
}



function executeTransaction(uint256 txId)
    external
    txExists(txId)
    notExecuted(txId)
{
    Transaction storage txn = transactions[txId];

    // Must meet threshold
    require(
        txn.approvalCount >= threshold,
        "Not enough approvals"
    );

    // Mark as executed BEFORE the external call
    txn.executed = true;

    // Execute the transaction
    (bool success, ) = txn.to.call{value: txn.value}(txn.data);
    require(success, "Transaction failed");

    // Emit event
    emit TransactionExecuted(txId);
}



    /*//////////////////////////////////////////////////////////////
                        OWNER / THRESHOLD MGMT STUBS
    //////////////////////////////////////////////////////////////*/

function addOwner(address newOwner) external onlyOwner {
    require(newOwner != address(0), "Owner cannot be zero");
    require(!ownerExists[newOwner], "Owner already exists");

    ownerExists[newOwner] = true;
    owners.push(newOwner);

    // Ensure threshold is still valid:
    // threshold <= number of owners
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
            owners[i] = owners[owners.length - 1]; // move last owner into this slot
            owners.pop(); // remove last element
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


function changeThreshold(uint256 newThreshold) external onlyOwner {
    require(newThreshold > 0, "Threshold must be > 0");
    require(newThreshold <= owners.length, "Threshold too high");

    threshold = newThreshold;

    emit ThresholdChanged(newThreshold);
}



    /*//////////////////////////////////////////////////////////////
                               VIEW HELPERS
    //////////////////////////////////////////////////////////////*/

    function getOwners() external view returns (address[] memory) {
        return owners;
    }

    function isOwner(address addr) external view returns (bool) {
        return ownerExists[addr];
    }

    receive() external payable {}
}
