xobjective 'it can be used standalone', ->

    it 'finds files and directories with dir()',

        (Index, done) ->

            Index.dir('../*')

            .then (r) ->

                done r.should.eql [

                    "../.git"
                    "../.gitignore"
                    "../.npmignore"
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

                done r.should.eql [

                    # "../.git"
                    "../.gitignore"
                    "../.npmignore"
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

                done r.should.eql [

                    "../.git"
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
