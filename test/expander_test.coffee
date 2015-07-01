objective 'Expand directory', (should) ->

    xcontext 'windows?', -> it 'might already support'

    trace.filter = true

    beforeEach (fs) ->

        global.$$in =

            promise: require('when').promise
            sequence: require('when/sequence')
            InfusionError: Error

        @includeFiles = true
        @includeDirs = false

        @In = opts: $$caller: FileName: '/once/upon/a/time/file.js'


        fs.stub stat: (name, callback) -> callback null,

            if name.match /(f|g)(i|y)le/
                isDirectory: -> false    # be a file, fyle, gile, gyle, le(.anything)
                forName: name
            else 
                isDirectory: -> true     # defalt as dir
                forName: name


    context 'expander.dir()', ->

        it 'includes files and directories',

            (done, fs, Expander) ->

                fs.stub readdir: (dir, cb) ->

                    if dir == '/once/upon/a/time/there'     then return cb null, ['file1', 'waS', 'iS']
                    if dir == '/once/upon/a/time/there/waS' then return cb null, ['file2', 'dir1', 'dir2']
                    if dir == '/once/upon/a/time/there/iS'  then return cb null, ['file3', 'dir3', 'dir4']

                    throw new Error 'Gone too far!'

                @includeDirs = true
                @includeFiles = true

                Expander.perform @In, './there/*S/*i*', @includeFiles, @includeDirs

                .then (r) ->
                    r.should.eql [
                        "./there/waS/file2"
                        "./there/waS/dir1"
                        "./there/waS/dir2"
                        "./there/iS/file3"
                        "./there/iS/dir3"
                        "./there/iS/dir4"
                    ]
                    done()

                .catch done


    context 'expander.dirs()', ->

        it 'includes only directories',

            (done, fs, Expander) ->

                fs.stub readdir: (dir, cb) ->

                    if dir == '/once/upon/a/time/there'     then return cb null, ['file1', 'was', 'is']
                    if dir == '/once/upon/a/time/there/was' then return cb null, ['file2', 'dir1', 'dir2']
                    if dir == '/once/upon/a/time/there/is'  then return cb null, ['file3', 'dir3', 'dir4']

                    throw new Error 'Gone too far!'

                @includeDirs = true
                @includeFiles = false

                Expander.perform @In, './there/*s/*i*', @includeFiles, @includeDirs

                .then (r) ->
                    r.should.eql [
                        # "./there/was/file2"
                        "./there/was/dir1"
                        "./there/was/dir2"
                        # "./there/is/file3"
                        "./there/is/dir3"
                        "./there/is/dir4"
                    ]
                    done()

                .catch done


    context 'expander.files()', ->

        it 'includes only files',

            (done, fs, Expander) ->

                fs.stub readdir: (dir, cb) ->

                    if dir == '/once/upon/a/time/there'     then return cb null, ['file1', 'was', 'is']
                    if dir == '/once/upon/a/time/there/was' then return cb null, ['file2', 'dir1', 'dir2']
                    if dir == '/once/upon/a/time/there/is'  then return cb null, ['file3', 'dir3', 'dir4']

                    throw new Error 'Gone too far!'

                @includeDirs = false
                @includeFiles = true

                Expander.perform @In, './there/*s/*i*', @includeFiles, @includeDirs

                .then (r) ->
                    r.should.eql [
                        "./there/was/file2"
                        # "./there/was/dir1"
                        # "./there/was/dir2"
                        "./there/is/file3"
                        # "./there/is/dir3"
                        # "./there/is/dir4"
                    ]
                    done()

                .catch done

    context 'general', ->

        it 'reads the directory',

            (done, fs, Expander) ->

                fs.does readdir: (dir) ->

                    dir.should.equal '/once/upon/a/time/there'
                    done()

                Expander.perform @In, './there/*', @includeFiles, @includeDirs

                .catch done


        it 'deals ok with relative paths',

            (done, fs, Expander) ->

                fs.does readdir: (dir) ->

                    dir.should.equal '/once/upon/a/there'
                    done()

                Expander.perform @In, '../there/*', @includeFiles, @includeDirs

                .catch done


        it 'handles wildcards everywhere',

            (done, fs, Expander) ->

                fs.does readdir: (dir) ->

                    dir.should.equal '/once/upon/a/time/there'
                    done()

                Expander.perform @In, './there/**/was/a*/*', @includeFiles, @includeDirs

                .catch done


        it 'rejects on error',

            (done, fs, Expander) ->

                fs.does readdir: (_, cb) -> cb new Error 'Oh! No!'

                Expander.perform @In, './there/**/was/a*/*', @includeFiles, @includeDirs
                .catch -> done()

        it 'does not allow partial deep wildcards',

            (done, fs, Expander) ->

                try
                    Expander.perform @In, './there/**e/*', @includeFiles, @includeDirs
                catch e
                    e.toString().should.match /only accepts/
                    done()

        it 'does not allow partial deep wildcards',

            (done, fs, Expander) ->

                try
                    Expander.perform @In, './there/e**/*', @includeFiles, @includeDirs
                catch e
                    e.toString().should.match /only accepts/
                    done()

        it 'does not allow partial deep wildcards',

            (done, fs, Expander) ->

                try
                    Expander.perform @In, './there/**', @includeFiles, @includeDirs
                catch e
                    e.toString().should.match /only accepts/
                    done()

        it 'does not allow partial deep wildcards',

            (done, fs, Expander) ->

                try
                    Expander.perform @In, '**', @includeFiles, @includeDirs
                catch e
                    e.toString().should.match /only accepts/
                    done()


        it 'can start at the beginning',

            (done, fs, Expander) ->

                fs.does readdir: (dir) ->

                    dir.should.equal '/once/upon/a/time'
                    done()

                Expander.perform @In, './*', @includeFiles, @includeDirs
                .catch done

        it 'can start at the very beginning',

            (done, fs, Expander) ->

                fs.does readdir: (dir) ->

                    dir.should.equal '/'
                    done()

                Expander.perform @In, '/*', @includeFiles, @includeDirs
                .catch done

        it 'restores relative filenames',

            (done, fs, Expander) ->

                fs.does readdir: (dir, cb) ->

                    dir.should.match '/'
                    cb null, ['file']

                Expander.perform @In, '../../../../*', @includeFiles, @includeDirs

                .then (r) -> 

                    r.should.eql ['../../../../file']
                    done()

                .catch done


        it 'goes no deeper than it should',

            (done, fs, Expander) ->

                fs.does readdir: (path, cb) -> 

                    path.should.equal '/'
                    cb null, ['file.js', 'dir']

                fs.spy readdir: (path, cb) ->

                    throw new Error ('No!') unless path == '/'

                @includeDirs = true

                Expander.perform @In, '/*', @includeFiles, @includeDirs

                .then (r) ->

                    r.should.eql [
                        '/file.js'
                        '/dir'
                    ]
                    done()

                .catch done


    context 'using **', ->

        beforeEach (fs) ->

            fs.does readdir: (dir, cb) ->

                cb null, ['was','wasn\'t']

            fs.does readdir: (dir, cb) ->

                dir.should.equal '/once/upon/a/time/there/was'
                cb null, ['a', 'file1']

            fs.does readdir: (dir, cb) ->

                dir.should.equal '/once/upon/a/time/there/was/a'
                cb null, ['file3.coffee', 'file3.js', 'fyle5.js']

            fs.does readdir: (dir, cb) ->

                dir.should.equal '/once/upon/a/time/there/wasn\'t'
                cb null, ['a', 'fyle2.js']

            fs.does readdir: (dir, cb) ->

                dir.should.equal '/once/upon/a/time/there/wasn\'t/a'
                cb null, ['fyle4.md', 'longer', 'shorter']

            fs.does readdir: (dir, cb) ->

                dir.should.equal '/once/upon/a/time/there/wasn\'t/a/longer'
                cb null, ['path']

            fs.does readdir: (dir, cb) ->

                dir.should.equal '/once/upon/a/time/there/wasn\'t/a/longer/path'
                cb null, ['fyle6.js']

            fs.does readdir: (dir, cb) ->

                dir.should.equal '/once/upon/a/time/there/wasn\'t/a/shorter'
                cb null, ['path']

            fs.does readdir: (dir, cb) ->

                dir.should.equal '/once/upon/a/time/there/wasn\'t/a/shorter/path'
                cb null, ['file7.js', 'file8.js']



        it 'keeps looking',

            (done, fs, Expander) ->

                Expander.perform @In, './there/**/*', @includeFiles, @includeDirs

                .then (r) -> 

                    r.should.eql [
                        './there/was/a/file3.coffee'
                        './there/was/a/file3.js'
                        './there/was/a/fyle5.js'
                        './there/was/file1'
                        "./there/wasn't/a/fyle4.md"
                        "./there/wasn't/a/longer/path/fyle6.js"
                        "./there/wasn't/a/shorter/path/file7.js"
                        "./there/wasn't/a/shorter/path/file8.js"
                        "./there/wasn't/fyle2.js"
                    ]
                    done()

                .catch done


        it 'matches with trailing *',

            (done, fs, Expander) ->

                Expander.perform @In, './there/**/fi*', @includeFiles, @includeDirs

                .then (r) ->

                    r.should.eql [
                        './there/was/a/file3.coffee'
                        './there/was/a/file3.js'
                        './there/was/file1'
                        "./there/wasn't/a/shorter/path/file7.js"
                        "./there/wasn't/a/shorter/path/file8.js"
                    ]
                    done()

                .catch done

        it 'matches with mid *',

            (done, fs, Expander) ->

                Expander.perform @In, './there/**/*yl*', @includeFiles, @includeDirs

                .then (r) ->

                    r.should.eql [
                        './there/was/a/fyle5.js'
                        './there/wasn\'t/a/fyle4.md'
                        "./there/wasn't/a/longer/path/fyle6.js"
                        './there/wasn\'t/fyle2.js'
                    ]
                    done()

                .catch done


        it 'matches with leading *',

            (done, fs, Expander) ->

                Expander.perform @In, './there/**/*.js', @includeFiles, @includeDirs

                .then (r) ->

                    r.should.eql [
                        "./there/was/a/file3.js"
                        './there/was/a/fyle5.js'
                        "./there/wasn't/a/longer/path/fyle6.js"
                        "./there/wasn't/a/shorter/path/file7.js"
                        "./there/wasn't/a/shorter/path/file8.js"
                        './there/wasn\'t/fyle2.js'
                    ]
                    done()

                .catch done


        it 'matches with jolly *',

            (done, fs, Expander) ->

                Expander.perform @In, './there/**/*il*j*', @includeFiles, @includeDirs

                .then (r) ->

                    r.should.eql [
                        "./there/was/a/file3.js"
                        "./there/wasn't/a/shorter/path/file7.js"
                        "./there/wasn't/a/shorter/path/file8.js"
                    ]
                    done()

                .catch done


        xit 'supports more than one **',

            (done, fs, Expander) ->
                
                Expander.perform @In, './there/**/longer/**/f*', @includeFiles, @includeDirs

                .then (r) ->

                    console.log RR: r

                .catch done


    context 'using *', ->

        beforeEach (fs) ->

            fs.does readdir: (path, cb) ->

                path.should.equal '/once/upon/a/time/there'
                cb null, ['file1.js', 'file2.js', 'file3.md', 'fyle4.js', 'was', 'dir.js', 'wasn\'t']




        it 'finds files with leading wildcard',

            (done, fs, Expander) ->

                Expander.perform @In, './there/*.js', @includeFiles, @includeDirs

                .then (r) ->

                    r.should.eql [
                        './there/file1.js'
                        './there/file2.js'
                        "./there/fyle4.js"
                    ]
                    done()

                .catch done

        it 'finds files with trailing wildcard',

            (done, fs, Expander) ->

                Expander.perform @In, './there/f*', @includeFiles, @includeDirs

                .then (r) ->

                    r.should.eql [
                        './there/file1.js'
                        './there/file2.js'
                        './there/file3.md'
                        "./there/fyle4.js"
                    ]
                    done()

                .catch done


        it 'finds files with jolly wildcard',

            (done, fs, Expander) ->

                Expander.perform @In, './there/*i*1*s', @includeFiles, @includeDirs

                .then (r) ->

                    r.should.eql [
                        './there/file1.js'
                    ]
                    done()

                .catch done


        it 'handles partial dir match with leading wildcard',

            (done, fs, Expander) ->

                fs.does readdir: (path, cb) ->

                    path.should.equal '/once/upon/a/time/there/was'
                    cb null, ['file.js', 'file.jsx', 'dir.js', 'dir2']

                Expander.perform @In, './there/*as/*.js', @includeFiles, @includeDirs

                .then (r) ->

                    r.should.eql [
                        "./there/was/file.js"
                    ]
                    done()

                .catch done


        it 'handles partial dir match with trailing wildcard',

            (done, fs, Expander) ->

                fs.does readdir: (path, cb) ->

                    path.should.equal '/once/upon/a/time/there/was'
                    cb null, ['file1.js', 'file.jsx', 'dir.js', 'dir2']

                fs.does readdir: (path, cb) ->

                    path.should.equal '/once/upon/a/time/there/wasn\'t'
                    cb null, ['file2.js', 'dir', 'file3.jsx']


                Expander.perform @In, './there/w*/*.js', @includeFiles, @includeDirs

                .then (r) ->

                    r.should.eql [
                        "./there/was/file1.js"
                        "./there/wasn't/file2.js"
                    ]
                    done()

                .catch done


        it 'handles partial dir match with jolly wildcard',

            (done, fs, Expander) ->

                fs.does readdir: (path, cb) ->

                    path.should.equal '/once/upon/a/time/there/wasn\'t'
                    cb null, ['file.js', 'file.jsx', 'dir.js', 'dir2']

                Expander.perform @In, './there/w*s*t/*.js', @includeFiles, @includeDirs

                .then (r) ->

                    r.should.eql [
                        "./there/wasn\'t/file.js"
                    ]
                    done()

                .catch done


        it 'handles partial dir match with even jollier wildcard',

            (done, fs, Expander) ->

                fs.does readdir: (path, cb) ->

                    path.should.equal '/once/upon/a/time/there/wasn\'t'
                    cb null, ['file.js', 'gile.jsx', 'dir.js', 'dir2']

                Expander.perform @In, './there/w*s*t/g*.js*', @includeFiles, @includeDirs

                .then (r) ->

                    r.should.eql [
                        "./there/wasn\'t/gile.jsx"
                    ]
                    done()

                .catch done

