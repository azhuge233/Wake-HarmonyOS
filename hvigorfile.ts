import { appTasks, OhosPluginId } from '@ohos/hvigor-ohos-plugin';
import { hvigor } from '@ohos/hvigor';
import * as fs from 'fs';
import * as path from 'path';

/**
 * Machine-local signing configuration.
 *
 * The committed build-profile.json5 has an empty signingConfigs array so that
 * every machine can clone the project without conflicts. Each machine runs
 * `node scripts/setup-signing.mjs` once: it generates that machine's signing
 * material and writes `external-signing-config.json` (git-ignored). This hook
 * injects the machine-local signingConfigs into the build profile at build
 * time, for both debug and release builds.
 */
const EXTERNAL_SIGNING_FILE = path.join(__dirname, 'external-signing-config.json');

hvigor.afterNodeEvaluate((hvigorNode) => {
  const context = hvigorNode.getContext(OhosPluginId.OHOS_APP_PLUGIN);
  if (!context || !context.getBuildProfileOpt || !context.setBuildProfileOpt) {
    return;
  }
  if (!fs.existsSync(EXTERNAL_SIGNING_FILE)) {
    console.warn(
      `[signing] ${EXTERNAL_SIGNING_FILE} not found. ` +
      'Run `node scripts/setup-signing.mjs` to configure this machine before building.'
    );
    return;
  }
  const external = JSON.parse(fs.readFileSync(EXTERNAL_SIGNING_FILE, 'utf-8'));
  if (!external || !Array.isArray(external.signingConfigs) || external.signingConfigs.length === 0) {
    throw new Error(`[signing] No signingConfigs found in ${EXTERNAL_SIGNING_FILE}`);
  }
  const buildProfile = context.getBuildProfileOpt();
  buildProfile.app.signingConfigs = external.signingConfigs;
  context.setBuildProfileOpt(buildProfile);
});

export default {
  system: appTasks,  /* Built-in plugin of Hvigor. It cannot be modified. */
  plugins: []        /* Custom plugin to extend the functionality of Hvigor. */
}
