// SPDX-License-Identifier: GPL-3.0-or-latersol
pragma solidity ^0.8.15;

/* solhint-disable no-console */

import "../config/ERC4337TestConfig.t.sol";

import {MemberManager} from "@utils/MemberManager.sol"; // improve this import, try to take from ForumGroup

/**
 * TODO
 * - Improve salt for group deployment. Should be more restrictive to prevent frontrunning, and should work cross chain
 * - Improve test code - still some repeated code that could be broken into functions
 */
contract ForumGroupTest is ERC4337TestConfig {
    ForumGroup internal forumGroup;
    address internal forumGroupAddress;

    bytes internal basicTransferCalldata;

    string internal constant GROUP_NAME_1 = "test";
    string internal constant GROUP_NAME_2 = "test2";

    /// -----------------------------------------------------------------------
    /// Setup
    /// -----------------------------------------------------------------------

    constructor() {
        // Create passkey signers
        publicKey = createPublicKey(SIGNER_1);
        publicKey2 = createPublicKey(SIGNER_2);

        // Format signers into arrays to be added to contract
        inputMembers.push([publicKey[0], publicKey[1]]);

        // Deploy a forum safe from the factory
        forumGroup = ForumGroup(payable(forumGroupFactory.createForumGroup(GROUP_NAME_1, 1, inputMembers)));
        forumGroupAddress = address(forumGroup);

        // Deal the account some funds
        vm.deal(forumGroupAddress, 1 ether);

        // Build a basic transaction to execute in some tests
        basicTransferCalldata = buildExecutionPayload(alice, uint256(0.5 ether), "", Enum.Operation.Call);
    }

    /// -----------------------------------------------------------------------
    /// SETUP TESTS
    /// -----------------------------------------------------------------------

    function testSetUpState() public {
        // Check group singelton is set in factory
        assertEq(
            address(forumGroupFactory.forumGroupSingleton()), address(forumGroupSingleton), "forumGroupSingleton not set"
        );
        // Check 4337 entryPoint is set in factory
        assertEq(forumGroupFactory.entryPoint(), entryPointAddress, "entryPoint not set");
        // Check 4337 gnosis fallback handler is set in factory
        assertEq(address(forumGroupFactory.gnosisFallbackLibrary()), address(handler), "handler not set");
        // Can not initialize the singleton
        vm.expectRevert("GS200");
        forumGroupSingleton.initalize(entryPointAddress, address(1), uint256(1), inputMembers, "", "", "");
    }

    function testSetupGroup() public {
        uint256[2][] memory members = forumGroup.getMembers();

        // Check the setup params are set correctly
        assertTrue(members[0][0] == publicKey[0]);
        assertTrue(members[0][1] == publicKey[1]);
        assertTrue(forumGroup.getVoteThreshold() == 1);
        assertTrue(forumGroup.entryPoint() == address(entryPoint));

        // Check the member has been minted a membership token
        assertTrue(forumGroup.isMember(publicKeyAddress(publicKey)) == 1);

        // The safe has been initialized with a threshold of 1
        // This threshold is not used when executing via group
        assertTrue(forumGroup.getThreshold() == 1);

        // Can not initialize the group again
        vm.expectRevert("GS200");
        forumGroup.initalize(entryPointAddress, address(1), uint256(1), inputMembers, "", "", "");
    }

    function testPublicKeyAddressMatches() public {
        assertEq(
            forumGroup.publicKeyAddress(MemberManager.Member(publicKey[0], publicKey[1])),
            forumAccountFactory.getAddress(keccak256(abi.encodePacked(publicKey)))
        );
    }

    function testDeployViaEntryPoint() public {
        // Encode the calldata for the factory to create an account
        bytes memory factoryCalldata =
            abi.encodeCall(forumGroupFactory.createForumGroup, (GROUP_NAME_2, 1, inputMembers));

        //Prepend the address of the factory
        bytes memory initCode = abi.encodePacked(address(forumGroupFactory), factoryCalldata);

        // Calculate address in advance to use as sender
        address preCalculatedAccountAddress = forumGroupFactory.getAddress(keccak256(abi.encodePacked(GROUP_NAME_2)));

        // Deal funds to account
        deal(preCalculatedAccountAddress, 1 ether);
        // Cast to ERC4337Account - used to make some test assertions easier
        ForumGroup newForumGroup = ForumGroup(payable(preCalculatedAccountAddress));

        // Build user operation
        UserOperation memory userOp = buildUserOp(preCalculatedAccountAddress, 0, initCode, basicTransferCalldata);

        UserOperation[] memory userOpArray = signAndFormatUserOp(userOp, SIGNER_1, "");

        // Handle userOp
        entryPoint.handleOps(userOpArray, payable(alice));

        uint256[2][] memory members = newForumGroup.getMembers();

        // Check the setup params are set correctly
        assertTrue(members[0][0] == publicKey[0]);
        assertTrue(members[0][1] == publicKey[1]);
        assertTrue(newForumGroup.getVoteThreshold() == 1);
        assertTrue(newForumGroup.entryPoint() == address(entryPoint));

        // Check the member has been minted a membership token
        assertTrue(forumGroup.isMember(publicKeyAddress(publicKey)) == 1);

        // The safe has been initialized with a threshold of 1
        // This threshold is not used when executing via group
        assertTrue(forumGroup.getThreshold() == 1);
    }

    function testCorrectAddressCrossChain() public {
        address tmpMumbai;
        address tmpFuji;

        uint256[2][] memory inputMembersCrossChain = new uint256[2][](1);
        inputMembersCrossChain[0] = publicKey;

        // Fork Mumbai and create an account from a fcatory
        vm.createSelectFork(vm.envString("MUMBAI_RPC_URL"));

        forumGroupFactory = new ForumGroupFactory(
     		payable(address(forumGroupSingleton)),
    		entryPointAddress,
    		address(safeSingleton),
    		address(handler) ,'','',''
    	);

        // Deploy an account to be used in tests
        tmpMumbai = forumGroupFactory.createForumGroup("test", 1, inputMembersCrossChain);

        // Fork Fuji and create an account from a fcatory
        vm.createSelectFork(vm.envString("FUJI_RPC_URL"));

        forumGroupFactory = new ForumGroupFactory(
    		payable(address(forumGroupSingleton)),
    		entryPointAddress, 
    		address(safeSingleton),
    		address(handler),'','',''
    	);

        // Deploy an account to be used in tests
        tmpFuji = forumGroupFactory.createForumGroup("test", 1, inputMembersCrossChain);

        assertEq(tmpMumbai, tmpFuji, "address not the same");
    }

    /// -----------------------------------------------------------------------
    /// HELPERS
    /// -----------------------------------------------------------------------

    /**
     * @dev Returns the address which a public key will deploy to based of the individual account factory
     */
    function publicKeyAddress(uint256[2] memory publicKey_) public view returns (address) {
        return address(
            bytes20(
                keccak256(
                    abi.encodePacked(
                        bytes1(0xff),
                        0x4e59b44847b379578588920cA78FbF26c0B4956C,
                        keccak256(abi.encodePacked(publicKey_[0], publicKey_[1])),
                        keccak256(
                            abi.encodePacked(
                                // constructor
                                bytes10(0x3d602d80600a3d3981f3),
                                // proxy code
                                bytes10(0x363d3d373d3d3d363d73),
                                address(forumAccountSingleton),
                                bytes15(0x5af43d82803e903d91602b57fd5bf3)
                            )
                        )
                    )
                ) << 96
            )
        );
    }

    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    receive() external payable {}
}
