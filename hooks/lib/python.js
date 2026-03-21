/**
 * AuraKit — Python Executable Detector
 * 플랫폼별 Python 실행 파일 감지 및 Python 스크립트 실행 유틸리티
 */
'use strict';

const { execSync, spawnSync } = require('child_process');
const fs = require('fs');

/**
 * 플랫폼에 맞는 Python 실행 파일 이름 반환
 * @returns {string} 'python' | 'python3'
 */
function getPythonExecutable() {
  if (process.platform === 'win32') return 'python';
  try {
    execSync('python3 --version', { stdio: 'pipe' });
    return 'python3';
  } catch {
    return 'python';
  }
}

/**
 * Python 스크립트를 stdin 전달 방식으로 실행
 * @param {string} scriptPath — 절대 경로
 * @param {Buffer|string} stdin — 표준 입력
 * @param {number} timeout — 타임아웃 ms (기본 10000)
 * @returns {{ stdout, stderr, status }}
 */
function runPythonScript(scriptPath, stdin, timeout = 10000) {
  const py = getPythonExecutable();
  return spawnSync(py, [scriptPath], {
    input: stdin,
    encoding: 'utf8',
    timeout,
  });
}

/**
 * stdin을 읽어서 Python 스크립트로 전달하고 결과를 stdout으로 출력
 * @param {string} scriptPath — 절대 경로
 */
function pipeStdinToPython(scriptPath) {
  const stdin = fs.readFileSync(0);
  const result = runPythonScript(scriptPath, stdin);
  if (result.stdout) process.stdout.write(result.stdout);
  if (result.stderr) process.stderr.write(result.stderr);
  process.exit(result.status || 0);
}

module.exports = {
  getPythonExecutable,
  runPythonScript,
  pipeStdinToPython,
};
