# Export Plugin
module.exports = (BasePlugin) ->

    # Return a subclass using DocPad's required extend() method
    BasePlugin.extend({

        name: 'copy'

        # Writing all files has finished
        writeAfter: (opts, next) ->

            eachr = require('eachr')
            pathUtil = require('path')
            safeps = require('safeps')
            TaskGroup = require('taskgroup').TaskGroup

            docpad = @docpad
            config = @getConfig()
            docpadConfig = @docpad.getConfig()

            outPath = pathUtil.normalize(docpad.getPath('out'))
            srcPath = pathUtil.normalize(docpad.getPath('source'))

            console.log 'Copy Plugin: writeAfter called'
            console.log 'Current Config:', config
            console.log 'DocpadConfig:', docpadConfig

            # Default config
            if Object.keys(config).length is 0
                config.default = src: 'raw'

            tasks = new TaskGroup(concurrency: 1).done (err) ->
                if err?
                    docpad.log 'error', "Copying error #{err}"
                else
                    docpad.log 'info', 'Copying completed successfully'
                next?()

            eachr config, (target, key) ->
                tasks.addTask (complete) ->

                    src = pathUtil.join(srcPath, target.src)
                    out = if target.out? then pathUtil.join(outPath, target.out) else outPath

                    docpad.log 'info', "Copying #{key} out: #{out}, src: #{src}"

                    WINDOWS = /win32/.test(process.platform)
                    OSX     = /darwin/.test(process.platform)
                    CYGWIN  = /cygwin/.test(process.env.PATH)
                    XCOPY   = WINDOWS and not CYGWIN

                    command =
                        if XCOPY
                            ['xcopy', '/eDy', "#{src}\\*", "#{out}\\"]
                        else if OSX
                            ['rsync', '-a', "#{src}/", "#{out}/"]
                        else
                            ['cp', '-Ruf', "#{src}/.", out]

                    safeps.spawn command, {output: false}, (err) ->
                        return complete(err) if err
                        docpad.log 'debug', "Done copying #{key}"
                        complete()

            tasks.run()

    })
