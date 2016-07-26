#!/usr/bin/env node
// Extremely simple preview tool for habitat configuration templates
// Takes a toml file and a config template and applies the config to the
// template, printing out the output
//
// Usage:
//
// ./hab_template_preview.js default.toml config/myfile.conf
//
// Requirements:
//
// npm install -g toml handlebars
//
// Limitations:
//
// Currently doesn't include any built in habitat variables.
// Error checking/support is minimal

var handlebars = require('handlebars');
var toml = require('toml');
var fs = require('fs');
var process = require('process');

config = toml.parse(fs.readFileSync(process.argv[2], 'utf8'));
context = {cfg: config};
var template = handlebars.compile(fs.readFileSync(process.argv[3], 'utf8'));
console.log(template(context));
