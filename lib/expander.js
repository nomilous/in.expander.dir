module.exports = Expander;

var path = require('path');
var fs = require('fs');

function Expander() {}


// Incase of require before in.

if (typeof $$in === 'undefined') global.$$in = {};
$$in.expanders = ($$in.expanders || {});

$$in.expanders.dir = function() {
  return Expander.perform.apply(this, arguments);
}


Expander.perform = function(In, mask) {

  var base, startIn;

  if (!mask.match(/\*+/)) throw new $$in.InfusionError('expand.dir() expects at least one wildcard');

  if (mask[0] == '.') {
    base = path.dirname(In.opts.$$caller.FileName);
    startIn = path.normalize(base + path.sep + mask);
  } else {
    startIn = path.normalize(mask);
  }

  var matchParts = startIn.split(/\*+/);
  var matchDepth = startIn.match(/(\*+)/g);  // ['**', '*', ..] or ['*', '*', ..]

  var founds = [];
  var found = function(fullname, stat) {
    founds.push({filename: fullname, stat: stat})
  }

  var restore = function(filename) {
    var relative;
    if (base) {
      relative = path.relative(base, filename)
      if (relative[0] == '.') return relative;
      return '.' + path.sep /* windows? */ + relative;
    }
    return filename;
  }

  return $$in.promise(function(resolve, reject, notify) {
    Expander.recurse(found, matchDepth, matchParts)
    .then(
      function() {
        resolve(founds.map(function(found) {
          return restore(found.filename)
        }))
      },
      reject,
      notify
    );
  })
}

Expander.recurse = function(found, matchDepth, matchParts, Path) {
  return $$in.promise(function(resolve, reject, notify) {

    var depth = matchDepth.shift().length;
    var part = matchParts.shift();
    var next = matchParts[0];

    if (typeof Path === 'undefined') Path = part;
    else {
      // ...
    }

    fs.readdir(Path, function(err, array) {
      if (err) return reject(err);

      Expander.stats(Path, array).then(function(stats){
                     // on *, not **
        if (depth == 1) {

          if (next == '') { // ended/in/only/*
            array.forEach(function(name) {
              found(Path + path.sep + name, stats.shift());
            });
            return resolve()
                                 // is windows sep 2 chars... ? uggggfsh
          } else if (next[0] == path.sep) { // we/are/here/*/with/more/path

            $$in.sequence( // ? parallel                 |
              array.filter(function(){
                return stats.shift().isDirectory()
              }).map(function(name) {

                return function() {
                  var nextPath = path.normalize(Path + path.sep + name + next);
                  if (next[next.length - 1] != path.sep) nextPath = path.dirname(nextPath);
                  return Expander.recurse(
                    found,               // may be a 'cheaper way'?
                    matchDepth.slice(), // need new copy into each directory
                    matchParts.slice(),
                    nextPath
                  )
                }
              })
            ).then(resolve, reject, notify);
          
          } else {

            console.log({next: next});

          }
        }
      }, reject, notify);
    });
  });
}

Expander.stats = function(Path, contents) {
  return $$in.sequence( // ? parallel
    contents.map(function(name) {
      return function() {
        return $$in.promise(function(resolve, reject) {
          fs.stat(Path + path.sep + name, function(err, stat) {
            if (err) return reject(err);
            resolve(stat);
          })
        })
      }
    })
  )
}
