objective 'Directory expander for `in.`', (recurse) ->

    ### search for files to watch / run tests on changes ###

    recurse ['lib', 'test'], createDir: true
    .then ->
