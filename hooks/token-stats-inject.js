#!/usr/bin/env node
/**
 * AuraKit — UserPromptSubmit Token Stats Inject (Node.js wrapper)
 * token-stats-inject.py를 호출하는 크로스 플랫폼 래퍼
 */
'use strict';
const path = require('path');
const { pipeStdinToPython } = require('./lib/python.js');

pipeStdinToPython(path.join(__dirname, 'token-stats-inject.py'));
