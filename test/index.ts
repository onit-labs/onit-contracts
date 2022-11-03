// Run the tests in the lib folder
import { describe } from 'mocha';

//
// See https://hardhat.org/tutorial/testing-contracts.html for further details
//

/* ///////////////////////////////////////////////////////////////
													Forums
	////////////////////////////////////////////////////////////// */

describe('Forum Factory', function () {
	require('./lib/ForumFactory.ts');
});

describe('ForumGroup', function () {
	require('./lib/ForumGroup.ts');
});

/* ///////////////////////////////////////////////////////////////
													Extensions
	////////////////////////////////////////////////////////////// */

describe.only('Fundraise Extension', function () {
	require('./lib/ext_Fundraise.ts');
});

describe('Delegation Extension', function () {
	require('./lib/ext_Delegator.ts');
});

describe('PFP Extension', function () {
	require('./lib/ext_PfpStaker.ts');
});

/* ///////////////////////////////////////////////////////////////
													Shields
	////////////////////////////////////////////////////////////// */

describe('FieldGenerator', function () {
	require('./lib/FieldGenerator.ts');
});

describe('Emblem Weaver', function () {
	require('./lib/EmblemWeaver.ts');
});

describe('Shield Manager', function () {
	require('./lib/ShieldManager.ts');
});

/* ///////////////////////////////////////////////////////////////
													Access Manager
	////////////////////////////////////////////////////////////// */

describe('Access Manager', function () {
	require('./lib/AccessManager.ts');
});
