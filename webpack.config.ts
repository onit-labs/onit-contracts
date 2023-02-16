const path = require('path')
const webpack = require('webpack')
require('dotenv').config({ path: '.env' })

// Webpack config used to build the Autotasks
// TODO: Move this into seperate package to keep project root tidy

module.exports = (env) => ({
	entry: `./services/oz-defender/autotasks/src/${env.TASK_NAME}/index.ts`,
	target: 'node',
	mode: 'development',
	devtool: 'cheap-module-source-map',
	module: {
		rules: [{ test: /\.tsx?$/, use: 'ts-loader', exclude: /node_modules/ }]
	},
	resolve: {
		extensions: ['.ts', '.js']
	},
	externals: [
		// List here all dependencies available on the Autotask environment
		/axios/,
		/apollo-client/,
		/defender-[^\-]+-client/,
		/ethers/,
		/web3/,
		/@ethersproject\/.*/,
		/aws-sdk/,
		/aws-sdk\/.*/
	],
	externalsType: 'commonjs2',
	plugins: [
		// List here all dependencies that are not run in the Autotask environment
		new webpack.IgnorePlugin({ resourceRegExp: /dotenv/ })
	],
	output: {
		filename: `${env.TASK_NAME}/index.js`,
		path: path.resolve(__dirname, './services/oz-defender/autotasks/dist'),
		library: { type: 'commonjs2' }
	}
})
