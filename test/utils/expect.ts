const chai = require('chai');
const { expect, use } = require('chai');

import { jestSnapshotPlugin } from 'mocha-chai-jest-snapshot'


use(jestSnapshotPlugin())
chai.should();

export { expect }
