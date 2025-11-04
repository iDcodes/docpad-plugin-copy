/**
 * Forked docpad-plugin-copy
 * Modern ES6+ implementation with stable cross-platform file copying.
 */

const path = require('path');
const eachr = require('eachr');
const TaskGroup = require('taskgroup').TaskGroup;
const safeps = require('safeps');

module.exports = function (BasePlugin) {
  return class CopyPlugin extends BasePlugin {
    get name() {
      return 'copy';
    }

    /**
     * Triggered after DocPad writes the output directory.
     * Copies configured folders to output.
     */
    writeAfter(opts, next) {
      const docpad = this.docpad;
      const config = this.getConfig();
      const docpadConfig = docpad.getConfig();

      const outPath = path.normalize(docpad.getPath('out'));
      const srcPath = path.normalize(docpad.getPath('source'));

      docpad.log('debug', '[copy] writeAfter triggered');
      docpad.log('debug', '[copy] Plugin config:', config);

      // Default config if plugin config is empty
      const finalConfig =
        Object.keys(config).length === 0
          ? { default: { src: 'raw' } }
          : config;

      const tasks = new TaskGroup({ concurrency: 1 }).done((err) => {
        if (err) {
          docpad.log('error', `[copy] Copying error: ${err}`);
        } else {
          docpad.log('info', '[copy] Copying completed successfully');
        }

        if (typeof next === 'function') next();
      });

      eachr(finalConfig, (target, key) => {
        tasks.addTask((complete) => {
          const srcFull = path.join(srcPath, target.src);
          const outFull = target.out
            ? path.join(outPath, target.out)
            : outPath;

          const options =
            target.options && typeof target.options === 'object'
              ? target.options
              : {};

          docpad.log(
            'info',
            `[copy] Copying '${key}' → src: ${srcFull} → out: ${outFull}`
          );

          // PLATFORM DETECTION
          const WINDOWS = process.platform === 'win32';
          const OSX = process.platform === 'darwin';
          const CYGWIN = /cygwin/.test(process.env.PATH);
          const XCOPY = WINDOWS && !CYGWIN;

          let command;

          if (XCOPY) {
            // Windows xcopy
            command = ['xcopy', '/eDy', `${srcFull}\\*`, `${outFull}\\`];
          } else if (OSX) {
            // macOS
            command = ['rsync', '-a', `${srcFull}/`, `${outFull}/`];
          } else {
            // Linux / Unix
            command = ['cp', '-Ruf', `${srcFull}/.`, outFull];
          }

          safeps.spawn(
            command,
            { output: false },
            (err) => {
              if (err) {
                docpad.log('error', `[copy] Error copying '${key}': ${err}`);
                return complete(err);
              }

              docpad.log('debug', `[copy] Done copying '${key}'`);
              return complete();
            }
          );
        });
      });

      return tasks.run();
    }
  };
};
