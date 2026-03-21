#!/usr/bin/env node
/**
 * AuraKit — Stop Hook Token Tracker (Node.js wrapper)
 * token-tracker.py를 호출하는 크로스 플랫폼 래퍼
 */
'use strict';
const path = require('path');
const { pipeStdinToPython } = require('./lib/python.js');

pipeStdinToPython(path.join(__dirname, 'token-tracker.py'));
