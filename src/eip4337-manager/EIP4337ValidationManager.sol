//SPDX-License-Identifier: GPL
pragma solidity ^0.8.15;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */

// ! tmp sig method
import {Utils} from '@utils/Utils.sol';

import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol';

import '@eip4337/contracts/interfaces/IAccount.sol';
import '@eip4337/contracts/interfaces/IEntryPoint.sol';

// import './EIP4337Fallback.sol';

import '../eip4337-module/ForumSafe4337Module.sol';

import 'forge-std/console.sol';

using ECDSA for bytes32;

/**
 * Main EIP4337 module.
 * Called (through the fallback module) using "delegate" from the GnosisSafe as an "IAccount",
 * so must implement validateUserOp
 * holds an immutable reference to the EntryPoint
 * Inherits ForumSafe4337Module so that it can reference the memory storage
 */
contract EIP4337ValidationManager is ForumSafe4337Module {
	// // address public immutable eip4337Fallback;
	// address public immutable entryPoint;

	// constructor(address anEntryPoint) {
	// 	entryPoint = anEntryPoint;
	// 	//eip4337Fallback = address(new EIP4337Fallback(address(this)));
	// }

	/**
	 * delegate-called (using execFromModule) through the fallback, so "real" msg.sender is attached as last 20 bytes
	 */
	function validateUserOp(
		UserOperation calldata userOp,
		bytes32 userOpHash,
		address /*aggregator*/,
		uint256 missingAccountFunds
	) external override returns (uint256 sigTimeRange) {
		// ! consider checks on caller
		//address _msgSender = address(bytes20(msg.data[msg.data.length - 20:]));
		//require(_msgSender == address(entryPoint()), 'account: not from entrypoint');

		// !convert to forum based checks & sig validation - using non ecdsa
		// GnosisSafe pThis = GnosisSafe(payable(address(this)));
		// bytes32 hash = userOpHash.toEthSignedMessageHash();
		// address recovered = hash.recover(userOp.signature);
		// require(threshold == 1, 'account: only threshold 1');
		// require(pThis.isOwner(recovered), 'account: wrong signature');

		// ! decode calldata, determine vote type to count

		// ! need to add nonce to forumgroup

		if (missingAccountFunds > 0) {
			//TODO: MAY pay more than the minimum, to deposit for future transactions
			(bool success, ) = payable(address(entryPoint())).call{value: missingAccountFunds}('');
			(success);
			//ignore failure (its EntryPoint's job to verify, not account.)
		}

		// ! DEFAULTING TO MEMBER VOTE FOR TESTING
		return
			_countVotes(
				IForumSafeModuleTypes.VoteType.MEMBER,
				_getVotes(userOp.signature, IForumSafeModuleTypes.VoteType.MEMBER)
			)
				? 0
				: 1;
	}

	// ! consider moving the below 2 functions to a library
	/**
	 * @notice Count votes on a proposal
	 * @param voteType voteType to count
	 * @param yesVotes number of votes for the proposal
	 * @return bool true if the proposal passed, false otherwise
	 */
	function _countVotes(VoteType voteType, uint256 yesVotes) internal view returns (bool) {
		if (voteType == VoteType.MEMBER)
			if ((yesVotes * 100) / getOwners().length >= memberVoteThreshold) return true;

		if (voteType == VoteType.SIMPLE_MAJORITY)
			if (yesVotes > ((totalSupply * 50) / 100)) return true;

		if (voteType == VoteType.TOKEN_MAJORITY)
			if (yesVotes >= (totalSupply * tokenVoteThreshold) / 100) return true;

		return false;
	}

	function _getVotes(
		bytes memory signatures,
		IForumSafeModuleTypes.VoteType voteType
	) internal view returns (uint256 votes) {
		// We keep track of the previous signer in the array to ensure there are no duplicates
		address prevSigner;

		// ! consider some digest to secure executions - maybe using nonce
		bytes32 digest = keccak256(
			abi.encodePacked(
				'\x19\x01',
				DOMAIN_SEPARATOR(),
				keccak256(abi.encode(PROPOSAL_HASH, _nonce))
			)
		);

		// ! need to divide up sig input
		uint256 sigCount = 1;

		// For each sig we check the recovered signer is a valid member and count thier vote
		for (uint256 i; i < sigCount; ) {
			// Recover the signer
			console.logBytes(signatures);
			address recoveredSigner = Utils.recoverSigner(digest, signatures, i);

			// If not a member, or the signer is out of order (used to prevent duplicates), revert
			//if (!isOwner(recoveredSigner) || prevSigner >= recoveredSigner) revert SignatureError();

			// If the signer has not delegated their vote, we count, otherwise we skip
			if (memberDelegatee[recoveredSigner] == address(0)) {
				// If member vote we increment by 1 (for the signer) + the number of members who have delegated to the signer
				// Else we calculate the number of votes based on share of the treasury
				if (voteType == VoteType.MEMBER)
					votes += 1 + EnumerableSet.length(memberDelegators[recoveredSigner]);
				else {
					uint256 len = EnumerableSet.length(memberDelegators[recoveredSigner]);
					// Add the number of votes the signer holds
					votes += balanceOf[recoveredSigner][TOKEN];
					// If the signer has been delegated too,check the balances of anyone who has delegated to the current signer
					if (len != 0)
						for (uint256 j; j < len; ) {
							votes += balanceOf[
								EnumerableSet.at(memberDelegators[recoveredSigner], j)
							][TOKEN];
							++j;
						}
				}
			}

			// Increment the index and set the previous signer
			++i;
			prevSigner = recoveredSigner;
		}
	}

	// ! consider similar fn to assit factory, or setup new 4337 modules
	// /**
	//  * set up a safe as EIP-4337 enabled.
	//  * called from the GnosisSafeAccountFactory during construction time
	//  * - enable 3 modules (this module, fallback and the entrypoint)
	//  * - this method is called with delegateCall, so the module (usually itself) is passed as parameter, and "this" is the safe itself
	//  */
	// function setup4337Modules(
	// 	EIP4337Manager manager //the manager (this contract)
	// ) external {
	// 	GnosisSafe safe = GnosisSafe(payable(this));
	// 	safe.enableModule(manager.entryPoint());
	// 	safe.enableModule(manager.eip4337Fallback());
	// }

	// ! consider this to replace manager on module
	// /**
	//  * replace EIP4337 module, to support a new EntryPoint.
	//  * must be called using execTransaction and Enum.Operation.DelegateCall
	//  * @param prevModule returned by getCurrentEIP4337Manager
	//  * @param oldManager the old EIP4337 manager to remove, returned by getCurrentEIP4337Manager
	//  * @param newManager the new EIP4337Manager, usually with a new EntryPoint
	//  */
	// function replaceEIP4337Manager(
	// 	address prevModule,
	// 	EIP4337Manager oldManager,
	// 	EIP4337Manager newManager
	// ) public {
	// 	GnosisSafe pThis = GnosisSafe(payable(address(this)));
	// 	address oldFallback = oldManager.eip4337Fallback();
	// 	require(
	// 		pThis.isModuleEnabled(oldFallback),
	// 		'replaceEIP4337Manager: oldManager is not active'
	// 	);
	// 	pThis.disableModule(oldFallback, oldManager.entryPoint());
	// 	pThis.disableModule(prevModule, oldFallback);

	// 	address eip4337fallback = newManager.eip4337Fallback();

	// 	pThis.enableModule(newManager.entryPoint());
	// 	pThis.enableModule(eip4337fallback);

	// 	pThis.setFallbackHandler(eip4337fallback);

	// 	validateEip4337(pThis, newManager);
	// }

	// /**
	//  * Validate this gnosisSafe is callable through the EntryPoint.
	//  * the test is might be incomplete: we check that we reach our validateUserOp and fail on signature.
	//  *  we don't test full transaction
	//  */
	// function validateEip4337(GnosisSafe safe, EIP4337Manager manager) public {
	// 	// this prevent mistaken replaceEIP4337Manager to disable the module completely.
	// 	// minimal signature that pass "recover"
	// 	bytes memory sig = new bytes(65);
	// 	sig[64] = bytes1(uint8(27));
	// 	sig[2] = bytes1(uint8(1));
	// 	sig[35] = bytes1(uint8(1));
	// 	UserOperation memory userOp = UserOperation(
	// 		address(safe),
	// 		0,
	// 		'',
	// 		'',
	// 		0,
	// 		1000000,
	// 		0,
	// 		0,
	// 		0,
	// 		'',
	// 		sig
	// 	);
	// 	UserOperation[] memory userOps = new UserOperation[](1);
	// 	userOps[0] = userOp;
	// 	IEntryPoint _entryPoint = IEntryPoint(payable(manager.entryPoint()));
	// 	try _entryPoint.handleOps(userOps, payable(msg.sender)) {
	// 		revert('validateEip4337: handleOps must fail');
	// 	} catch (bytes memory error) {
	// 		if (
	// 			keccak256(error) !=
	// 			keccak256(
	// 				abi.encodeWithSignature(
	// 					'FailedOp(uint256,address,string)',
	// 					0,
	// 					address(0),
	// 					'account: wrong signature'
	// 				)
	// 			)
	// 		) {
	// 			revert(string(error));
	// 		}
	// 	}
	// }

	// ! maybe not needed in module version
	// function delegateCall(address to, bytes memory data) internal {
	// 	bool success;
	// 	assembly {
	// 		success := delegatecall(sub(0, 1), to, add(data, 0x20), mload(data), 0, 0)
	// 	}
	// 	require(success, 'delegate failed');
	// }

	// ! convert to check current 4337 manager on module
	// /**
	//  * enumerate modules, and find the currently active EIP4337 manager (and previous module)
	//  * @return prev prev module, needed by replaceEIP4337Manager
	//  * @return manager the current active EIP4337Manager
	//  */
	// function getCurrentEIP4337Manager(
	// 	GnosisSafe safe
	// ) public view returns (address prev, address manager) {
	// 	prev = address(SENTINEL_MODULES);
	// 	(address[] memory modules, ) = safe.getModulesPaginated(SENTINEL_MODULES, 100);
	// 	for (uint i = 0; i < modules.length; i++) {
	// 		address module = modules[i];
	// 		(bool success, bytes memory ret) = module.staticcall(
	// 			abi.encodeWithSignature('eip4337manager()')
	// 		);
	// 		if (success) {
	// 			manager = abi.decode(ret, (address));
	// 			return (prev, manager);
	// 		}
	// 		prev = module;
	// 	}
	// 	return (address(0), address(0));
	// }
}
