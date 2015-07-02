objective 'Expand directory', (should) ->

    xcontext 'windows?', -> it 'might already support'

    trace.filter = true

    beforeEach (fs) ->

        @doFiles = true
        @doDirs = false

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

                @doDirs = true
                @doFiles = true

                Expander.perform @In, './there/*S/*i*', @doFiles, @doDirs

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

                @doDirs = true
                @doFiles = false

                Expander.perform @In, './there/*s/*i*', @doFiles, @doDirs

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

                @doDirs = false
                @doFiles = true

                Expander.perform @In, './there/*s/*i*', @doFiles, @doDirs

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


    context 'perform()', ->

        it 'calls recurse with parts, depth and jump',

            (done, Expander) ->

                Expander.does recurse: (match, next, jump, Path, parts, depth, exinfo, found) ->

                    parts.should.eql ['', '*']
                    depth.should.equal 1   #
                    done()
                    then: ->

                Expander.perform @In, '/*', @doFiles, @doDirs

                .catch done


        it 'fills . relative path',
    
            (done, Expander) ->

                Expander.does recurse: (match, next, jump, Path, parts, depth, exinfo, found) ->

                    parts.should.eql ['', 'once', 'upon', 'a', 'time', '*']
                    done()
                    then: ->

                Expander.perform @In, './*', @doFiles, @doDirs

                .catch done

        it 'normalizes .. relative path',
    
            (done, Expander) ->

                Expander.does recurse: (match, next, jump, Path, parts, depth, exinfo, found) ->

                    parts.should.eql ['', 'once', 'upon', 'a', '*']
                    done()
                    then: ->

                Expander.perform @In, '../*', @doFiles, @doDirs

                .catch done


    context 'recurse()', ->

        it 'calls readdir with path',

            (done, fs, Expander) ->

                fs.does readdir: (path, cb) ->

                    path.should.equal '/var/log'
                    done()

                Expander.recurse null, null, jump = 0, '/', ['', 'var', 'log', '*', '*.log'], depth = 1, exinfo = {}, (->)


        it 'calls stat for each file/dir',

            (done, fs, Expander) ->

                fs.does readdir: (path, cb) ->

                    cb null, ['app1', 'app2', 'app3']

                fs.does stat: (path, cb) ->

                    path.should.equal '/var/log/app1'
                    cb null, isDirectory: ->

                fs.does stat: (path, cb) ->

                    path.should.equal '/var/log/app2'
                    cb null, isDirectory: ->

                fs.does stat: (path, cb) ->

                    path.should.equal '/var/log/app3'
                    cb null, isDirectory: ->
                    done()

                Expander.recurse null, null, jump = 0, '/', ['', 'var', 'log', '*', '*.log'], depth = 1, exinfo = {count: 0}, (->)

                .catch (e) -> console.log EE: e


        it 'runs each found file/dir through a filter',

            (done, fs, Expander) ->

                fs.does readdir: (path, cb) ->

                    cb null, ['app1', 'app2', 'app3']

                Expander.stub mapper: -> -> ->

                Expander.does filter: (match, next, jump, Path, parts, depth, stats, keeps) ->

                    # console.log match, next, Path

                    (fileName) -> 

                        return true
                        # console.log fileName

                Expander.recurse null, null, jump = 0, '/', ['', 'var', 'log', '*', '*.log'], depth = 1, exinfo = {count: 0}, (->)

                done()


        context 'filter()', ->

            it 'filters out names that dont match',

                (done, Expander) ->

                    filter = Expander.filter match = '*', next = '*', jump = 0, [], []
                    filter('name').should.equal true

                    filter = Expander.filter match = 'n*', next = '*', jump = 0, [], []
                    filter('name').should.equal true

                    filter = Expander.filter match = 'n*m*', next = '*', jump = 0, [], []
                    filter('name').should.equal true

                    filter = Expander.filter match = 'n*e', next = '*', jump = 0, [], []
                    filter('name').should.equal true

                    filter = Expander.filter match = 'e*', next = '*', jump = 0, [], []
                    filter('name').should.equal false

                    filter = Expander.filter match = '*e', next = '*', jump = 0, [], []
                    filter('name').should.equal true

                    filter = Expander.filter match = '*e*', next = '*', jump = 0, [], []
                    filter('name').should.equal false

                    done()


            it 'filters out files (keeps dirs) if match is ** and jump is 0',

                (done, Expander) ->

                    filter = Expander.filter(
                        match = '**'
                        next = '*'
                        jump = 0
                        stats = [
                            {isDirectory: -> true}
                            {isDirectory: -> false}
                            {isDirectory: -> true}
                        ]
                        keeps = []
                    )

                    filter('lib').should.equal true
                    filter('file').should.equal false
                    filter('log').should.equal true

                    keeps.length.should.equal 2
                    done()

            it 'keeps files if match is ** and jump is greater than 0',

                (done, Expander) ->

                    filter = Expander.filter(
                        match = '**'
                        next = '*'
                        jump = 1
                        stats = [
                            {isDirectory: -> true}
                            {isDirectory: -> false}
                            {isDirectory: -> true}
                        ]
                        keeps = []
                    )

                    filter('lib').should.equal true
                    filter('file').should.equal true
                    filter('log').should.equal true

                    keeps.length.should.equal 3
                    done()

        it 'runs each found file/dir through a mapper',

            (done, fs, Expander) ->

                fs.does readdir: (path, cb) ->

                    cb null, ['app1', 'app2', 'app3']

                Expander.does

                    exinfo: (match, next, jump, Path, parts, depth, stats, exinfo, found) ->

                        (fileName) -> ->

                Expander.recurse null, null, jump = 0, '/', ['', 'var', 'log', '*', '*.log'], depth = 1, {}, (->)
                done()


        context 'mapper()', ->

            it 'calls found if next is undefined',

                (done, Expander) ->

                    findings = []

                    mapper = Expander.exinfo(
                        match = '*.log'
                        next = undefined
                        jump = 0
                        Path = '/var/log'
                        parts = ['', 'var', 'log', '*.log']
                        depth = 3
                        stats = [
                            {for: 'my.log', isDirectory: -> false}
                            {for: 'dir', isDirectory: -> true}
                        ]
                        exinfo = count: 0
                        found = (filename, stat) ->
                            findings.push filename
                    )

                    mapper('my.log')()
                    mapper('dir')()

                    done findings.should.eql [
                        "/var/log/my.log"
                        "/var/log/dir"
                    ]

            context 'recurses with new path', ->

                it 'and depth if next is defined and match IS NOT **',

                    (done, Expander) ->

                        mapper = Expander.exinfo(
                            match = '*'
                            next = 'dir'
                            jump = 0
                            Path = '/var/log'
                            parts = ['', 'var', '*', 'dir', '*']
                            depth = 2
                            stats = [
                                {for: 'my.log', isDirectory: -> false}
                                {for: 'dir', isDirectory: -> true}
                            ]
                            exinfo = count: 0
                            found = ->
                        )

                        Expander.does recurse: (match, next, jump, Path, parts, depth, exinfo, found) ->

                            Path.should.equal '/var/log/dir'
                            depth.should.equal 3
                            jump.should.equal 0
                            done()


                        mapper('my.log')()
                        mapper('dir')()



                it 'and same depth if next is defined and match IS **',

                    (done, Expander) ->

                        mapper = Expander.exinfo(
                            match = '**'
                            next = 'dir'
                            jump = 0
                            Path = '/var/log'
                            parts = ['', 'var', '**', 'dir', '*']
                            depth = 2
                            stats = [
                                {for: 'my.log', isDirectory: -> false}
                                {for: 'dir', isDirectory: -> true}
                            ]
                            exinfo = count: 0
                            found = ->
                        )

                        Expander.does recurse: (match, next, jump, Path, parts, depth, exinfo, found) ->

                            Path.should.equal '/var/log/dir'
                            depth.should.equal 2
                            jump.should.equal 1
                            done()


                        mapper('my.log')()
                        mapper('dir')()


                it 'and next depth if match IS ** and jump is bigger than 0 and next matches',

                    (done, Expander) ->

                        mapper = Expander.exinfo(
                            match = '**'
                            next = 'dir'
                            jump = 1
                            Path = '/var/log/moo'
                            parts = ['', 'var', '**', 'dir', '*']
                            depth = 2
                            stats = [
                                {for: 'my.log', isDirectory: -> false}
                                {for: 'dir', isDirectory: -> true}
                            ]
                            exinfo = count: 0
                            found = ->
                        )

                        Expander.does recurse: (match, next, jump, Path, parts, depth, exinfo, found) ->

                            Path.should.equal '/var/log/moo/dir'
                            depth.should.equal 3
                            jump.should.equal 0
                            done()


                        mapper('my.log')()
                        mapper('dir')()


                it 'same depth if match IS ** and jump is bigger than 0 and next does not match',

                    (done, Expander) ->

                        mapper = Expander.exinfo(
                            match = '**'
                            next = 'dir'
                            jump = 1
                            Path = '/var/log/moo'
                            parts = ['', 'var', '**', 'dir', '*']
                            depth = 2
                            stats = [
                                {for: 'my.log', isDirectory: -> false}
                                {for: 'dirr', isDirectory: -> true}
                            ]
                            exinfo = count: 0
                            found = ->
                        )

                        Expander.does recurse: (match, next, jump, Path, parts, depth, exinfo, found) ->

                            Path.should.equal '/var/log/moo/dirr'
                            depth.should.equal 2
                            jump.should.equal 2
                            done()


                        mapper('my.log')()
                        mapper('dirr')()


    context 'general', ->

        it 'reads the directory',

            (done, fs, Expander) ->

                fs.does readdir: (dir) ->

                    dir.should.equal '/once/upon/a/time/there'
                    done()

                Expander.perform @In, './there/*', @doFiles, @doDirs

                .catch done


        it 'deals ok with relative paths',

            (done, fs, Expander) ->

                fs.does readdir: (dir) ->

                    dir.should.equal '/once/upon/a/there'
                    done()

                Expander.perform @In, '../there/*', @doFiles, @doDirs

                .catch done


        it 'handles wildcards everywhere',

            (done, fs, Expander) ->

                fs.does readdir: (dir) ->

                    dir.should.equal '/once/upon/a/time/there'
                    done()

                Expander.perform @In, './there/**/was/a*/*', @doFiles, @doDirs

                .catch done


        it 'rejects on error',

            (done, fs, Expander) ->

                fs.does readdir: (_, cb) -> cb new Error 'Oh! No!'

                Expander.perform @In, './there/**/was/a*/*', @doFiles, @doDirs
                .catch -> done()

        it 'does not allow partial deep wildcards',

            (done, fs, Expander) ->

                Expander.perform @In, './there/**e/*', @doFiles, @doDirs
                .catch (e) ->
                    e.toString().should.match /invalid use of/
                    done()

        it 'does not allow partial deep wildcards',

            (done, fs, Expander) ->

                Expander.perform @In, './there/e**/*', @doFiles, @doDirs
                .catch (e) ->
                    e.toString().should.match /invalid use of/
                    done()

        it 'does not allow partial deep wildcards',

            (done, fs, Expander) ->

                Expander.perform @In, './there/**', @doFiles, @doDirs
                .catch (e) ->
                    e.toString().should.match /invalid use of/
                    done()

        it 'does not allow partial deep wildcards',

            (done, fs, Expander) ->

                Expander.perform @In, '**', @doFiles, @doDirs
                .catch (e) ->
                    e.toString().should.match /invalid use of/
                    done()


        it 'can start at the beginning',

            (done, fs, Expander) ->

                fs.does readdir: (dir) ->

                    dir.should.equal '/once/upon/a/time'
                    done()

                Expander.perform @In, './*', @doFiles, @doDirs
                .catch done

        it 'can start at the very beginning',

            (done, fs, Expander) ->

                fs.does readdir: (dir) ->

                    dir.should.equal '/'
                    done()

                Expander.perform @In, '/*', @doFiles, @doDirs
                .catch done

        it 'restores relative filenames',

            (done, fs, Expander) ->

                fs.does readdir: (dir, cb) ->

                    dir.should.match '/'
                    cb null, ['file']

                Expander.perform @In, '../../../../*', @doFiles, @doDirs

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

                @doDirs = true

                Expander.perform @In, '/*', @doFiles, @doDirs

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
                cb null, ['a', 'file1.js']

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

                Expander.perform @In, './there/**/*.*', @doFiles, @doDirs

                .then (r) ->

                    r.should.eql [
                        './there/was/a/file3.coffee'
                        './there/was/a/file3.js'
                        './there/was/a/fyle5.js'
                        './there/was/file1.js'
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

                Expander.perform @In, './there/**/fi*', @doFiles, @doDirs

                .then (r) ->

                    r.should.eql [
                        './there/was/a/file3.coffee'
                        './there/was/a/file3.js'
                        './there/was/file1.js'
                        "./there/wasn't/a/shorter/path/file7.js"
                        "./there/wasn't/a/shorter/path/file8.js"
                    ]
                    done()

                .catch done

        it 'matches with mid *',

            (done, fs, Expander) ->

                Expander.perform @In, './there/**/*yl*', @doFiles, @doDirs

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

                Expander.perform @In, './there/**/*.js', @doFiles, @doDirs

                .then (r) ->

                    r.should.eql [
                        "./there/was/a/file3.js"
                        './there/was/a/fyle5.js'
                        "./there/was/file1.js"
                        "./there/wasn't/a/longer/path/fyle6.js"
                        "./there/wasn't/a/shorter/path/file7.js"
                        "./there/wasn't/a/shorter/path/file8.js"
                        './there/wasn\'t/fyle2.js'
                    ]
                    done()

                .catch done


        it 'matches with jolly *',

            (done, fs, Expander) ->

                Expander.perform @In, './there/**/*il*j*', @doFiles, @doDirs

                .then (r) ->

                    r.should.eql [
                        "./there/was/a/file3.js"
                        "./there/was/file1.js"
                        "./there/wasn't/a/shorter/path/file7.js"
                        "./there/wasn't/a/shorter/path/file8.js"
                    ]
                    done()

                .catch done


        xit 'supports more than one **',

            (done, fs, Expander) ->
                
                Expander.perform @In, './there/**/longer/**/f*', @doFiles, @doDirs

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

                Expander.perform @In, './there/*.js', @doFiles, @doDirs

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

                Expander.perform @In, './there/f*', @doFiles, @doDirs

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

                Expander.perform @In, './there/*i*1*s', @doFiles, @doDirs

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

                Expander.perform @In, './there/*as/*.js', @doFiles, @doDirs

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


                Expander.perform @In, './there/w*/*.js', @doFiles, @doDirs

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

                Expander.perform @In, './there/w*s*t/*.js', @doFiles, @doDirs

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

                Expander.perform @In, './there/w*s*t/g*.js*', @doFiles, @doDirs

                .then (r) ->

                    r.should.eql [
                        "./there/wasn\'t/gile.jsx"
                    ]
                    done()

                .catch done

