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

  var base, startIn, matchParts;

  if (!mask.match(/\*+/)) throw new $$in.InfusionError('expand.dir() expects at least one wildcard');

  if (mask[0] == '.') {
    base = path.dirname(In.opts.$$caller.FileName);
    startIn = path.normalize(base + path.sep + mask);
  } else {
    startIn = path.normalize(mask);
  }

  var matchParts = startIn.split(/\*+/);
  var matchDepth = startIn.match(/(\*+)/g);  // ['**', '*', ..] or ['*', '*', ..]
  var doneParts = [];

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
    
    Expander.recurse(found, matchDepth, matchParts, doneParts)
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

Expander.recurse = function(found, matchDepth, matchParts, doneParts, Path) {
  return $$in.promise(function(resolve, reject, notify) {

    var depth = matchDepth.shift().length;
    var part = matchParts.shift();
    var next = matchParts[0];
    doneParts.push(part);

    if (typeof Path === 'undefined') Path = part;
    else {
      // ...
    }

    fs.readdir(Path, function(err, array) {
      if (err) return reject(err);

      Expander.stats(Path, array).then(function(stats){

        if (next == '') { // ended/in/only/*
          array.forEach(function(name) {
            found(Path + path.sep + name, stats.shift());
          });
          return resolve()
        }


      }, reject);
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
