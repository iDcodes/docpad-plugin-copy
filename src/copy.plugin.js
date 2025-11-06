// Modernized ES6+ version of docpad-plugin-copy

const eachr = require("eachr");
const pathUtil = require("path");
const { TaskGroup } = require("taskgroup");
const safeps = require("safeps");

module.exports = function (BasePlugin) {
  class Copy extends BasePlugin {
    constructor(...args) {
      super(...args);
      this.name = "copy";
    }

    async writeAfter(opts, next) {
      const docpad = this.docpad;
      const config = this.getConfig();

      const outPath = pathUtil.normalize(docpad.getPath('out'));
      const srcPath = pathUtil.normalize(docpad.getPath('source'));

      // Default config if none provided
      if (Object.keys(config).length === 0) {
        config.default = { src: "raw" };
      }

      const tasks = new TaskGroup({ concurrency: 1 })
        .done((err) => {
          if (!err) docpad.log("info", "Copying completed successfully");
          else docpad.log("error", "Copying error: " + err);

          if (typeof next === "function") next();
        });

      eachr(config, (target, key) => {
        tasks.addTask((complete) => {
          const src = pathUtil.join(srcPath, target.src);
          let out = outPath;

          if (target.out) {
            out = pathUtil.join(outPath, target.out);
          }

          const options =
            target.options && typeof target.options === "object"
              ? target.options
              : {};

          docpad.log("info", `Copying ${key} → out: ${out}, src: ${src}`);

          const WINDOWS = process.platform === "win32";
          const OSX = process.platform === "darwin";
          const CYGWIN = /cygwin/i.test(process.env.PATH);
          const XCOPY = WINDOWS && !CYGWIN;

          const command = XCOPY
            ? ["xcopy", "/eDy", src + "\\*", out + "\\"]
            : OSX
            ? ["rsync", "-a", src + "/", out + "/"]
            : ["cp", "-Ruf", src + "/.", out];

          safeps.spawn(
            command,
            { output: false },
            (err) => {
              if (err) return complete(err);
              docpad.log("debug", `Done copying ${key}`);
              complete();
            }
          );
        });
      });

      tasks.run();
    }
  }

  return Copy;
};