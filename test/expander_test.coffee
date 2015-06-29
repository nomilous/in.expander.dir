objective 'Expand directory', (should) ->

    beforeEach (fs) ->

        global.$$in =

            promise: require('when').promise
            sequence: require('when/sequence')

        fs.stub stat: (name, callback) -> callback null,

            if name.match /file/
                isDirectory: -> false
                forName: name
            else 
                isDirectory: -> true
                forName: name

        @In = 
            opts:
                $$caller:
                    FileName: '/once/upon/a/time/file.js'


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

            fs.does readdir: (_, cb) -> cb null, ['file.js', 'dir1', 'dir2']

            Expander.perform @In, './there/*'

            .then (r) ->

                r.should.eql [
                    './there/file.js'
                    './there/dir1'
                    './there/dir2'
                ]
                done()


    it 'walks deeper on depth 1 wildcard with partial stripped',

        (done, fs, Expander) ->

            fs.does readdir: (path, cb) ->

                cb null, ['file.js', 'dir1', 'dir2']

            fs.does readdir: (path, cb) ->

                path.should.equal '/once/upon/a/time/there/dir1/an'
                cb null, []

            fs.does readdir: (path, cb) ->
                                                                # goes to dirname
                path.should.equal '/once/upon/a/time/there/dir2/an'
                cb null, []
                                                # partial 
            Expander.perform @In, './there/*/an/el*'

            .then (r) -> done()

            .catch (e) -> console.log EEE: e


    it 'walks deeper on depth 1 wildcard',

        (done, fs, Expander) ->

            fs.does readdir: (path, cb) ->

                cb null, ['file.js', 'was', 'will_be']

            fs.does readdir: (path, cb) ->

                path.should.equal '/once/upon/a/time/there/was/an/'
                cb null, []

            fs.does readdir: (path, cb) ->
    
                path.should.equal '/once/upon/a/time/there/will_be/an/'
                cb null, []

            Expander.perform @In, './there/*/an/*'

            .then (r) -> done()

            .catch (e) -> console.log EEE: e


    it 'walks even deeper on depth 1 wildcard',

        (done, fs, Expander) ->

            fs.does readdir: (path, cb) ->

                cb null, ['file.js', 'was']

            fs.does readdir: (path, cb) ->

                path.should.equal '/once/upon/a/time/there/was/an/'
                cb null, ['file.js', 'elephant']

            fs.does readdir: (path, cb) ->

                path.should.equal '/once/upon/a/time/there/was/an/elephant/in/the/'
                cb null, ['file.js']

            Expander.perform @In, './there/*/an/*/in/the/*'

            .then (r) -> 
                r.should.eql [
                    './there/was/an/elephant/in/the/file.js'
                ]
                done()

            .catch (e) -> console.log EEE: e



