// Modern ES6+ version of docpad-plugin-copy

module.exports = function(BasePlugin) {
  class Copy extends BasePlugin {
    constructor(...args) {
      super(...args);
    }

    get name() {
      return 'copy';
    }

    writeAfter(opts, next) {
      const eachr = require('eachr');
      const pathUtil = require('path');
      const docpad = this.docpad;
      const config = this.getConfig();
      const docpadConfig = this.docpad.getConfig();
      const outPath = pathUtil.normalize(docpad.getPath('out'));
      const srcPath = pathUtil.normalize(docpad.getPath('source'));

      console.log('Copy Plugin: writeAfter called');
      console.log('Current Config:', config);
      console.log('DocpadConfig:', docpadConfig);
      // Set default config if empty
      if (Object.keys(config).length === 0) {
        config.default = {
          src: 'raw'
        };
      }

      const TaskGroup = require('taskgroup').TaskGroup;
      const tasks = new TaskGroup({
        concurrency: 1
      }).done((err, results) => {
        if (!err) {
          docpad.log('info', 'Copying completed successfully');
        } else {
          docpad.log('error', `Copying error ${err}`);
        }

        if (typeof next === 'function') {
          next();
        }
      });

      eachr(config, (target, key) => {
        tasks.addTask((complete) => {
          const src = pathUtil.join(srcPath, target.src);
          let out = outPath;

          if (target.out != null) {
            out = pathUtil.join(outPath, target.out);
          }

          const options = (target.options != null && typeof target.options === 'object')
            ? target.options
            : {};

          docpad.log('info', `Copying ${key} out: ${out}, src: ${src}`);

          const WINDOWS = /win32/.test(process.platform);
          const OSX = /darwin/.test(process.platform);
          const CYGWIN = /cygwin/.test(process.env.PATH);
          const XCOPY = WINDOWS && !CYGWIN;

          let command;
          if (XCOPY) {
            command = ['xcopy', '/eDy', `${src}\\*`, `${out}\\`];
          } else if (OSX) {
            command = ['rsync', '-a', `${src}/`, `${out}/`];
          } else {
            command = ['cp', '-Ruf', `${src}/.`, out];
          }

          const safeps = require('safeps');

          return safeps.spawn(command, {
            output: false
          }, (err) => {
            if (err) {
              return complete(err);
            }

            docpad.log('debug', `Done copying ${key}`);
            return complete();
          });
        });
      });

      return tasks.run();
    }
  }

  return Copy;
};
