#!/usr/bin/env node

var main
if (process.env['SNOOPDOG_DEBUG'] != null) {
	console.log('snoopdog starting in debug mode')
	require('coffee-script/register')
	main = require('./../src/index.coffee')
} else {
	main = require('./../lib/index.js')
}

main(process.argv)
