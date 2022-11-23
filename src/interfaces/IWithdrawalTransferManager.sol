// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWithdrawalTransferManager {
    function buildApprovalPayloads(address collection, uint256 amountOrId)
        external
        view
        returns (bytes memory);

    function executeTransferPayloads(
        address collection,
        address from,
        address to,
        uint256 amountOrId
    )
        external;
}
