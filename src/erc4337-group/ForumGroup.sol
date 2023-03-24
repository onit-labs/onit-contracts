// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

/* solhint-disable avoid-low-level-calls */

import {Base64} from '@libraries/Base64.sol';
import {HexToLiteralBytes} from '@libraries/HexToLiteralBytes.sol';

import {Exec} from '@utils/Exec.sol';

import {Safe, Enum} from '@safe/Safe.sol';
import {IAccount} from '@erc4337/interfaces/IAccount.sol';
import {IEntryPoint, UserOperation} from '@erc4337/interfaces/IEntryPoint.sol';
import {Secp256r1, PassKeyId} from '@aa-passkeys-wallet/Secp256r1.sol';

import {ForumGroupGovernanceBasic} from './ForumGroupGovernanceBasic.sol';

/**
 * @notice Forum Group
 * @author Forum - Modified from infinitism https://github.com/eth-infinitism/account-abstraction/contracts/samples/gnosis/ERC4337Module.sol
 */
contract ForumGroup is IAccount, Safe, ForumGroupGovernanceBasic {
	/// ----------------------------------------------------------------------------------------
	///							EVENTS & ERRORS
	/// ----------------------------------------------------------------------------------------

	event ChangedVoteThreshold(uint256 voteThreshold);

	error ModuleAlreadySetUp();

	error NotFromEntrypoint();

	error InvalidInitialisation();

	error InvalidThreshold();

	error MemberExists();

	error CannotRemoveMember();

	/// ----------------------------------------------------------------------------------------
	///							GROUP STORAGE
	/// ----------------------------------------------------------------------------------------

	/**
	 * @notice Member struct
	 * @param x Public key of member
	 * @param y Public key of next member
	 * @dev x & y are the public key of the members P-256 passkey
	 */
	struct Member {
		uint256 x;
		uint256 y;
	}

	// Should be made immutable - also consider removing variables and passing in signature
	string internal _clientDataStart;

	// Should be made immutable - also consider removing variables and passing in signature
	string internal _clientDataEnd;

	// Reference to latest entrypoint
	address internal _entryPoint;

	// Number of required signatures for a Safe transaction.
	uint256 internal _voteThreshold;

	// Return value in case of signature failure, with no time-range.
	// Equivalent to _packValidationData(true,0,0);
	uint256 internal constant _SIG_VALIDATION_FAILED = 1;

	// ! consider making the key here an address & calcualting the address from the public key
	// This would require using the getAddress fn from the factory, or simplifying the factory
	// By removing salt from the account deployment, we could get a consistent address based only off the public key
	// The downside is that each passkey can only deply one account
	// The pro is that we can use the address as the key for the mapping, and use a real 1155 token
	mapping(bytes32 => Member) internal _members;

	// Used nonces; 1 = used (prevents replaying the same userOp, while allowing out of order execution)
	mapping(uint256 => uint256) public usedNonces;

	// Storing all members to index the mapping
	bytes32[] internal _membersHashArray;

	/// -----------------------------------------------------------------------
	/// 						SETUP
	/// -----------------------------------------------------------------------

	// Ensures the singleton can not be setup
	constructor() {
		_voteThreshold = 1;
	}

	/**
	 * @notice Setup the module.
	 * @param _anEntryPoint The entrypoint to use on the safe
	 * @param fallbackHandler The fallback handler to use on the safe
	 * @param voteThreshold Vote threshold to pass (counted in members)
	 * @param members The public key pairs of the signing members of the group
	 */
	function setUp(
		address _anEntryPoint,
		address fallbackHandler,
		uint256 voteThreshold,
		uint256[2][] memory members,
		string memory clientDataStart,
		string memory clientDataEnd
	) external {
		// Can only be set up once
		if (_voteThreshold != 0) revert ModuleAlreadySetUp();

		// Create a placeholder owner
		address[] memory ownerPlaceholder = new address[](1);
		ownerPlaceholder[0] = address(0xdead);

		// Setup the safe with placeholder owner and threshold 1
		this.setup(
			ownerPlaceholder,
			1,
			address(0),
			new bytes(0),
			fallbackHandler,
			address(0),
			0,
			payable(address(0))
		);

		if (
			_anEntryPoint == address(0) ||
			voteThreshold < 1 ||
			voteThreshold > members.length ||
			members.length < 1
		) revert InvalidInitialisation();

		_entryPoint = _anEntryPoint;

		_clientDataStart = clientDataStart;

		_clientDataEnd = clientDataEnd;

		_voteThreshold = voteThreshold;

		// Set up the members
		for (uint256 i; i < members.length; ++i) {
			// Create a hash used to identify the member
			bytes32 memberHash = publicKeyHash(Member(members[i][0], members[i][1]));

			// ! consider the below, there are many things being tracked here
			// Add key pair to the members mapping
			_members[memberHash] = Member(members[i][0], members[i][1]);
			// Add hash to the members array
			_membersHashArray.push(memberHash);
			// Mint membership token
			_mint(memberHash, MEMBERSHIP, 1, '');
		}
	}

	/// -----------------------------------------------------------------------
	/// 						VALIDATION
	/// -----------------------------------------------------------------------

	function validateUserOp(
		UserOperation calldata userOp,
		bytes32 userOpHash,
		uint256 missingAccountFunds
	) external override returns (uint256 validationData) {
		if (msg.sender != _entryPoint) revert NotFromEntrypoint();

		// Extract the passkey generated signature and authentacator data
		// Signer index is the index of the signer in the members array, used to retrieve the public key
		(uint256[] memory signerIndex, uint256[2][] memory sig, string memory authData) = abi
			.decode(userOp.signature, (uint256[], uint256[2][], string));

		// Hash the client data to produce the challenge signed by the passkey offchain
		bytes32 hashedClientData = sha256(
			abi.encodePacked(
				_clientDataStart,
				Base64.encode(abi.encodePacked(userOpHash)),
				_clientDataEnd
			)
		);

		bytes32 fullMessage = sha256(
			abi.encodePacked(HexToLiteralBytes.fromHex(authData), hashedClientData)
		);

		uint256 count;

		for (uint i; i < signerIndex.length; ) {
			// Check if the signature is valid and increment count if so
			if (
				Secp256r1.Verify(
					PassKeyId(
						_members[_membersHashArray[signerIndex[i]]].x,
						_members[_membersHashArray[signerIndex[i]]].y,
						''
					),
					sig[i][0],
					sig[i][1],
					uint(fullMessage)
				)
			) ++count;

			++i;
		}

		if (count < _voteThreshold) {
			validationData = _SIG_VALIDATION_FAILED;
		}

		// usedNonces mapping keeps the option to execute nonces out of order
		// We increment nonce so we have a way to keep track of the next available nonce
		if (userOp.initCode.length == 0) {
			if (usedNonces[userOp.nonce] == 1) revert InvalidNonce();
			++usedNonces[userOp.nonce];
			++nonce;
		}

		if (missingAccountFunds > 0) {
			//Note: MAY pay more than the minimum, to deposit for future transactions
			(bool success, ) = payable(msg.sender).call{value: missingAccountFunds}('');
			(success);
			//ignore failure (its EntryPoint's job to verify, not account.)
		}
	}

	/// -----------------------------------------------------------------------
	/// 						EXECUTION
	/// -----------------------------------------------------------------------

	/**
	 * Execute a call but also revert if the execution fails.
	 * The default behavior of the Safe is to not revert if the call fails,
	 * which is challenging for integrating with ERC4337 because then the
	 * EntryPoint wouldn't know to emit the UserOperationRevertReason event,
	 * which the frontend/client uses to capture the reason for the failure.
	 */
	function executeAndRevert(
		address to,
		uint256 value,
		bytes memory data,
		Enum.Operation operation
	) external {
		if (msg.sender != _entryPoint) revert NotFromEntrypoint();

		bool success = execute(to, value, data, operation, type(uint256).max);

		bytes memory returnData = Exec.getReturnData(type(uint256).max);
		// Revert with the actual reason string
		// Adopted from: https://github.com/Uniswap/v3-periphery/blob/464a8a49611272f7349c970e0fadb7ec1d3c1086/contracts/base/Multicall.sol#L16-L23
		if (!success) {
			if (returnData.length < 68) revert();
			assembly {
				returnData := add(returnData, 0x04)
			}
			revert(abi.decode(returnData, (string)));
		}
	}

	/// -----------------------------------------------------------------------
	/// 						GROUP MANAGEMENT
	/// -----------------------------------------------------------------------

	// /**
	//  * @notice Manage admin of group
	//  */
	// function manageAdmin(
	// 	IForumSafeModuleTypes.ProposalType proposalType,
	// 	address[] memory accounts,
	// 	uint256[] memory amounts,
	// 	bytes[] memory payloads
	// ) external payable {
	// 	// ! count votes and limit to entrypoint or passed vote

	// 	require(msg.sender == address(_entryPoint), 'Only entrypoint can execute');

	// 	// Consider these checks which used to happen in propose function
	// 	if (accounts.length != amounts.length || amounts.length != payloads.length)
	// 		revert NoArrayParity();

	// 	if (
	// 		proposalType == ProposalType.MEMBER_THRESHOLD ||
	// 		proposalType == ProposalType.TOKEN_THRESHOLD
	// 	)
	// 		if (amounts[0] == 0 || amounts[0] > 100) revert VoteThresholdBounds();

	// 	// ! correct count based on new struct
	// 	if (proposalType == ProposalType.TYPE)
	// 		if (amounts[0] > 13 || amounts[1] > 2 || amounts.length != 2) revert TypeBounds();

	// 	unchecked {
	// 		// Add / remove members + update gnosis threshold

	// 		if (proposalType == ProposalType.MEMBER_THRESHOLD)
	// 			memberVoteThreshold = uint32(amounts[0]);

	// 		if (proposalType == ProposalType.TOKEN_THRESHOLD)
	// 			tokenVoteThreshold = uint32(amounts[0]);

	// 		if (proposalType == ProposalType.TYPE)
	// 			proposalVoteTypes[ProposalType(amounts[0])] = VoteType(amounts[1]);

	// 		if (proposalType == ProposalType.PAUSE) _flipPause();

	// 		if (proposalType == ProposalType.EXTENSION)
	// 			for (uint256 i; i < accounts.length; ) {
	// 				if (amounts[i] != 0) extensions[accounts[i]] = !extensions[accounts[i]];

	// 				if (payloads[i].length > 3) {
	// 					IForumGroupExtension(accounts[i]).setExtension(payloads[i]);
	// 				}
	// 				++i;
	// 			}

	// 		if (proposalType == ProposalType.DOCS) docs = string(payloads[0]);

	// 		// ! consider a nonce or similar to prevent replies (if sigs are used)
	// 	}
	// }

	// ! consider visibility and access control
	/// @notice Changes the voteThreshold of the Safe to `voteThreshold`.
	/// @param voteThreshold New voteThreshold.
	function changeVoteThreshold(uint256 voteThreshold) public authorized {
		// Validate that voteThreshold is smaller than number of members & is at least 1
		if (voteThreshold < 1 || voteThreshold > totalSupply[TOKEN]) revert InvalidThreshold();

		_voteThreshold = voteThreshold;
		emit ChangedVoteThreshold(_voteThreshold);
	}

	/// @notice Adds a member to the Safe.
	/// @param member Member to add.
	/// @param voteThreshold_ New voteThreshold.
	function addMemberWithThreshold(
		Member memory member,
		uint256 voteThreshold_
	) public authorized {
		bytes32 memberHash = keccak256(abi.encodePacked(member.x, member.y));
		if (_members[memberHash].x != 0) revert MemberExists();

		// Validate that voteThreshold is at least 1 & is smaller than (the new) number of members
		if (voteThreshold_ < 1 || voteThreshold_ > totalSupply[MEMBERSHIP] + 1)
			revert InvalidThreshold();

		_mint(memberHash, MEMBERSHIP, 1, '');
		_members[memberHash] = member;
		_membersHashArray.push(memberHash);

		// Update voteThreshold
		_voteThreshold = voteThreshold_;

		// ! consider a nonce or similar to prevent replies (if sigs are used)
		//emit AddedMember(x, y);
	}

	// ! improve handling of member array
	/// @notice Removes a member from the Safe & updates threshold.
	/// @param memberHash Hash of the member's public key.
	/// @param voteThreshold_ New voteThreshold.
	function removeMemberWithThreshold(
		bytes32 memberHash,
		uint256 voteThreshold_
	) public authorized {
		if (_members[memberHash].x == 0) revert CannotRemoveMember();

		// Validate that voteThreshold is at least 1 & is smaller than (the new) number of members
		// This also ensures the last member is not removed
		if (voteThreshold_ < 1 || voteThreshold_ > totalSupply[MEMBERSHIP] - 1)
			revert InvalidThreshold();

		_burn(memberHash, MEMBERSHIP, 1);
		delete _members[memberHash];
		for (uint256 i = 0; i < _membersHashArray.length; i++) {
			if (_membersHashArray[i] == memberHash) {
				_membersHashArray[i] = _membersHashArray[_membersHashArray.length - 1];
				_membersHashArray.pop();
				break;
			}
		}

		// Update voteThreshold
		_voteThreshold = voteThreshold_;

		// ! consider a nonce or similar to prevent replies (if sigs are used)
		//emit RemovedMember(x, y);
	}

	function setEntryPoint(address anEntryPoint) external {
		if (msg.sender != _entryPoint) revert NotFromEntrypoint();

		// ! consider checks that entrypoint is valid here !
		// ! potential to brick account !
		_entryPoint = anEntryPoint;
	}

	/// -----------------------------------------------------------------------
	/// 						VIEW FUNCTIONS
	/// -----------------------------------------------------------------------

	function entryPoint() public view virtual returns (address) {
		return _entryPoint;
	}

	function getVoteThreshold() public view returns (uint256) {
		return _voteThreshold;
	}

	function getMembers() public view returns (uint256[2][] memory members) {
		uint256 len = _membersHashArray.length;

		members = new uint256[2][](len);

		for (uint256 i; i < len; ) {
			Member memory _mem = _members[_membersHashArray[i]];
			members[i] = [_mem.x, _mem.y];

			// Length of member array can't exceed max uint256
			unchecked {
				++i;
			}
		}
	}

	function publicKeyHash(Member memory pk) public pure returns (bytes32) {
		return keccak256(abi.encodePacked(pk.x, pk.y));
	}
}
