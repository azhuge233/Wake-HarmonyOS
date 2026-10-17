#!/usr/bin/env node
/**
 * One-time machine setup for Wake-HarmonyOS signing.
 *
 * Why: build-profile.json5 is committed with an empty signingConfigs array so
 * the project stays machine-independent. Each machine generates its own
 * debug/release signing material (devecocli signature generate), then this
 * script moves the generated signingConfigs into external-signing-config.json
 * (git-ignored) and restores build-profile.json5 to its committed state.
 *
 * Usage (from the repository root):
 *   node scripts/setup-signing.mjs
 *
 * Requirements: devecocli (DevEco CLI) on PATH and a logged-in Huawei
 * developer account (`devecocli auth status`).
 */
import { execSync } from 'node:child_process';
import { existsSync, readFileSync, writeFileSync, copyFileSync, unlinkSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import vm from 'node:vm';

const scriptDir = dirname(fileURLToPath(import.meta.url));
const projectRoot = resolve(scriptDir, '..');
const buildProfilePath = join(projectRoot, 'build-profile.json5');
const externalPath = join(projectRoot, 'external-signing-config.json');
const backupPath = join(projectRoot, '.build-profile.signing-backup.json5');

function parseJson5(text) {
  // build-profile.json5 is JSON5 (unquoted keys, single quotes, trailing
  // commas); an object literal wrapped in parentheses is valid JavaScript.
  return vm.runInNewContext(`(${text.replace(/^\uFEFF/, '')})`, Object.create(null), { timeout: 1000 });
}

function main() {
  if (!existsSync(buildProfilePath)) {
    throw new Error(`build-profile.json5 not found at ${buildProfilePath}`);
  }
  const original = readFileSync(buildProfilePath, 'utf-8');
  copyFileSync(buildProfilePath, backupPath);
  try {
    execSync('devecocli signature generate', {
      cwd: projectRoot,
      stdio: 'inherit',
    });
    const generated = parseJson5(readFileSync(buildProfilePath, 'utf-8'));
    const signingConfigs = generated?.app?.signingConfigs;
    if (!Array.isArray(signingConfigs) || signingConfigs.length === 0) {
      throw new Error('devecocli signature generate produced no signingConfigs');
    }
    writeFileSync(externalPath, `${JSON.stringify({ signingConfigs }, null, 2)}\n`, 'utf-8');
    writeFileSync(buildProfilePath, original, 'utf-8');
    console.log(`[signing] wrote ${signingConfigs.length} signing config(s) to ${externalPath}`);
    console.log('[signing] build-profile.json5 restored to its machine-independent state');
  } catch (error) {
    writeFileSync(buildProfilePath, original, 'utf-8');
    console.error(`[signing] setup failed: ${error.message}`);
    process.exitCode = 1;
  } finally {
    if (existsSync(backupPath)) {
      unlinkSync(backupPath);
    }
  }
}

main();
