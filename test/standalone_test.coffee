xobjective 'it can be used standalone', ->

    it 'finds files and directories with dir()',

        (Expander, done) ->

            Expander.dir('../*')

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
                    "."   # BUG(ish)  ../thisdir
                    "../test.tree"
                ]

            .catch done


    it 'finds only files with files()',

        (Expander, done) ->

            Expander.files('../*')

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
                    # "."   # BUG(ish)  ../thisdir
                    # "../test.tree"
                ]

            .catch done


    it 'finds only directories with dirs()',

        (Expander, done) ->

            Expander.dirs('../*')

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
                    "."   # BUG(ish)  ../thisdir
                    "../test.tree"
                ]

            .catch done
