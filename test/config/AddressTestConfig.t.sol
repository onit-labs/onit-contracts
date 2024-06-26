// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <=0.8.23;

import {StdCheats} from "forge-std/StdCheats.sol";

/**
 * @title AddressTestConfig
 * @notice Create some commonly used addresses and private keys for testing
 */
abstract contract AddressTestConfig is StdCheats {
    // Used to create addresses for users beyond first 5
    bytes32 internal nextUser = keccak256(abi.encodePacked("user address"));

    // Commonly used addresses & private keys
    address internal immutable alice;
    address internal immutable bob;
    address internal immutable carl;
    address internal immutable dave;
    address internal immutable eve;

    uint256 internal immutable alicePk;
    uint256 internal immutable bobPk;
    uint256 internal immutable carlPk;
    uint256 internal immutable davePk;
    uint256 internal immutable evePk;

    // Some basic addresses
    address internal constant ZERO_ADDRESS = address(0);
    address internal constant ONE_ADDRESS = address(1);
    address internal constant DEAD_ADDRESS = address(0xDEAD);

    /// -----------------------------------------------------------------------
    /// Setup
    /// -----------------------------------------------------------------------

    constructor() {
        // Create labeled addresses for most commonly used accounts
        (alice, alicePk) = makeAddrAndKey("alice");
        (bob, bobPk) = makeAddrAndKey("bob");
        (carl, carlPk) = makeAddrAndKey("carl");
        (dave, davePk) = makeAddrAndKey("dave");
        (eve, evePk) = makeAddrAndKey("eve");

        deal(alice, 100 ether);
        deal(bob, 100 ether);
        deal(carl, 100 ether);
        deal(dave, 100 ether);
        deal(eve, 100 ether);
    }

    function getNextUserAddress() public returns (address payable) {
        // Bytes32 to address conversion
        address payable user = payable(address(uint160(uint256(nextUser))));
        nextUser = keccak256(abi.encodePacked(nextUser));
        return user;
    }

    // Create users with 100 ether balance
    function createUsers(uint256 userNum) public returns (address payable[] memory) {
        address payable[] memory users = new address payable[](userNum);
        for (uint256 i = 0; i < userNum; i++) {
            address payable user = this.getNextUserAddress();
            deal(user, 100 ether);
            users[i] = user;
        }
        return users;
    }
}
