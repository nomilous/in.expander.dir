objective 'Expand directory', (should) ->

    beforeEach (fs) ->

        global.$$in =

            promise: require('when').promise
            sequence: require('when/sequence')
            InfusionError: Error

        fs.stub stat: (name, callback) -> callback null,

            if name.match /(f|g)(i|y)le/
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

            fs.does readdir: (dir) ->

                dir.should.equal '/once/upon/a/time/there'
                done()

            Expander.perform @In, './there/*'

            .catch done


    it 'deals ok with relative paths',

        (done, fs, Expander) ->

            fs.does readdir: (dir) ->

                dir.should.equal '/once/upon/a/there'
                done()

            Expander.perform @In, '../there/*'

            .catch done


    it 'handles wildcards everywhere',

        (done, fs, Expander) ->

            fs.does readdir: (dir) ->

                dir.should.equal '/once/upon/a/time/there'
                done()

            Expander.perform @In, './there/**/was/a*/*'

            .catch done


    it 'rejects on error',

        (done, fs, Expander) ->

            fs.does readdir: (_, cb) -> cb new Error 'Oh! No!'

            Expander.perform @In, './there/**/was/a*/*'
            .catch -> done()

    it 'does not allow partial deep wildcards',

        (done, fs, Expander) ->

            try
                Expander.perform @In, './there/**e/*'
            catch e
                e.toString().should.match /only accepts/
                done()

    it 'does not allow partial deep wildcards',

        (done, fs, Expander) ->

            try
                Expander.perform @In, './there/e**/*'
            catch e
                e.toString().should.match /only accepts/
                done()

    it 'does not allow partial deep wildcards',

        (done, fs, Expander) ->

            try
                Expander.perform @In, './there/**'
            catch e
                e.toString().should.match /only accepts/
                done()

    it 'does not allow partial deep wildcards',

        (done, fs, Expander) ->

            try
                Expander.perform @In, '**'
            catch e
                e.toString().should.match /only accepts/
                done()


    it 'can start at the beginning',

        (done, fs, Expander) ->

            fs.does readdir: (dir) ->

                dir.should.equal '/once/upon/a/time'
                done()

            Expander.perform @In, './*'
            .catch done

    it 'can start at the very beginning',

        (done, fs, Expander) ->

            fs.does readdir: (dir) ->

                dir.should.equal '/'
                done()

            Expander.perform @In, '/*'
            .catch done

    it 'restores relative filenames'


    xcontext 'windows?'



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

                Expander.perform @In, './there/**/*'

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

                Expander.perform @In, './there/**/fi*'

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

                Expander.perform @In, './there/**/*yl*'

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

                Expander.perform @In, './there/**/*.js'

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

                Expander.perform @In, './there/**/*il*j*'

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
                
                Expander.perform @In, './there/**/longer/**/f*'

                .then (r) ->

                    console.log RR: r

                .catch done




    context 'going short', ->

        beforeEach (fs) ->

            fs.does readdir: (path, cb) ->

                path.should.equal '/once/upon/a/time/there'
                cb null, ['file1.js', 'file2.js', 'file3.md', 'fyle4.js', 'was', 'dir.js', 'wasn\'t']


        it 'finds files with leading wildcard',

            (done, fs, Expander) ->

                Expander.perform @In, './there/*.js'

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

                Expander.perform @In, './there/f*'

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

                Expander.perform @In, './there/*i*1*s'

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

                Expander.perform @In, './there/*as/*.js'

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


                Expander.perform @In, './there/w*/*.js'

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

                Expander.perform @In, './there/w*s*t/*.js'

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

                Expander.perform @In, './there/w*s*t/g*.js*'

                .then (r) ->

                    r.should.eql [
                        "./there/wasn\'t/gile.jsx"
                    ]
                    done()

                .catch done


        it 'dir'

        it 'dirs'

        it 'files'

              
                









