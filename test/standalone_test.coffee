objective 'it can be used standalone', (should) ->

    xit 'keeps going on no access but notifies',

        (Index, done) ->

            @timeout 6000

            Index.dir('/**/*').then(
                (r) ->
                    console.log r
                done
                (notify) -> console.log notify.error
            )


    it 'can find with multiple masks',

        (Index, done) ->

            Index.dir('../test/*', '../lib/*')

            .then (r) ->

                done r.should.eql [
                    '_functional_test.coffee'
                    'expander_test.coffee'
                    'standalone_test.coffee'
                    '../lib/expander.js'
                    '../lib/index.js'
                ]

            .catch done


    it 'finds files and directories with dir()',

        (Index, done) ->

            Index.dir('../*')

            .then (r) ->

                done r.should.eql [

                    "../.git"
                    "../.gitignore"
                    "../.npmignore"
                    "../.travis.yml"
                    "../LICENSE"
                    "../README.md"
                    "../lib"
                    "../node_modules"
                    "../objective.coffee"
                    "../objective.coffee.json"
                    "../package.json"
                    "../test"   # BUG(ish)  ../thisdir
                    "../test.tree"
                ]

            .catch done


    it 'finds only files with files()',

        (Index, done) ->

            Index.files('../*')

            .then (r) ->

                # .git is sometimes a file and sometimes a directory

                r.shift() if r[0] == '../.git'

                done r.should.eql [

                    # "../.git"
                    "../.gitignore"
                    "../.npmignore"
                    "../.travis.yml"
                    "../LICENSE"
                    "../README.md"
                    # "../lib"
                    # "../node_modules"
                    "../objective.coffee"
                    "../objective.coffee.json"
                    "../package.json"
                    # "."   
                    # "../test.tree"
                ]

            .catch done


    it 'finds only directories with dirs()',

        (Index, done) ->

            Index.dirs('../*')

            .then (r) ->

                r.shift() if r[0] == '../.git'

                done r.should.eql [

                    # "../.git"
                    # "../.gitignore"
                    # "../.npmignore"
                    # "../LICENSE"
                    # "../README.md"
                    "../lib"
                    "../node_modules"
                    # "../objective.coffee"
                    # "../objective.coffee.json"
                    # "../package.json"
                    "../test"
                    "../test.tree"
                ]

            .catch done


    it 'provides ex info', 

        (Index, done) ->

            Index.files('../node_modules/**/*.*')

            .then (r) ->

                done should.exist r.info
                

            .catch done


