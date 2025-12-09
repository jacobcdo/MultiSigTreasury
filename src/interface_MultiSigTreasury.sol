// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IMultiSigTreasury {

    function proposeTransaction(address to, uint256 value, bytes calldata data) external returns (uint256 txId);

    function approveTransaction(uint256 txId) external;

    function revokeApproval(uint256 txId) external;

    function executeTransaction(uint256 txId) external;

    function addOwner(address newOwner) external;
    function removeOwner(address owner) external;
    function changeThreshold(uint256 newThreshold) external;

    function getOwners() external view returns (address[] memory);
    function isOwner(address addr) external view returns (bool);
}
