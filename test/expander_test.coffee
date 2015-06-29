objective 'Expand directory', (should) ->

    beforeEach (fs) ->

        global.$$in =

            promise: require('when').promise
            sequence: require('when/sequence')

        fs.stub stat: (name, callback) -> callback null,

            if name.match /dir/
                isDirectory: -> true
                forName: name
            else 
                isDirectory: -> false
                forName: name

        @defer = 
            resolve: ->
            reject: ->
            notify: ->

        @In = 
            opts:
                $$caller:
                    FileName: '/once/upon/a/time/caller.js'


    it 'reads the directory',

        (done, fs, Expander) ->

            trace.filter = true

            fs.does readdir: (dir) ->

                dir.should.equal '/once/upon/a/time/there/'
                done()

            Expander.perform @In, './there/*'


    it 'deals ok with relatives',

        (done, fs, Expander) ->

            fs.does readdir: (dir) ->

                dir.should.equal '/once/upon/a/there/'
                done()

            Expander.perform @In, '../there/*'


    it 'handles wildcards everywhere',

        (done, fs, Expander) ->

            fs.does readdir: (dir) ->

                dir.should.equal '/once/upon/a/time/there/'
                done()

            Expander.perform @In, './there/**/was/a*/*'


    it 'rejects on error',

        (done, fs, Expander) ->

            fs.does readdir: (_, cb) -> cb new Error 'Oh! No!'

            Expander.perform @In, './there/**/was/a*/*'
            .catch ->
                done()


    it 'includes files and directories if last is wildcard',

        (done, fs, Expander) ->

            trace.filter = true

            @defer.reject = (e) -> console.log e

            fs.does readdir: (_, cb) -> cb null, ['was.js', 'dir1', 'dir2']

            @defer.resolve = (r) -> console.log r:r

            Expander.perform @In, './there/*'
            .then (r) ->

                r.should.eql [
                    './there/was.js'
                    './there/dir1'
                    './there/dir2'
                ]
                done()



