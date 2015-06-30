// tODO: enable regex in path mask maybe

module.exports = Expander;

var path = require('path');
var fs = require('fs');

function Expander() {}


// Incase of require before in.

if (typeof $$in === 'undefined') global.$$in = {};
$$in.expanders = ($$in.expanders || {});

$$in.expanders.dir = function(In, mask) {
  return Expander.perform(In, mask, true, true);
}

$$in.expanders.files = function(In, mask) {
  return Expander.perform(In, mask, true, false);
}

$$in.expanders.dirs = function(In, mask) {
  return Expander.perform(In, mask, false, true);
}


Expander.perform = function(In, mask, includeFiles, includeDirs) {

  if (!mask.match(/\*+/)) 
    throw new $$in.InfusionError(
      'expand.dir() expects at least one wildcard');

  var valid = mask.split('**');
  if (valid.length > 1) {
    for (var i = 0; i < valid.length - 1; i++) {
      if (valid[i][valid[i].length - 1] !== path.sep 
        || valid[i+1][0] !== path.sep) {
        throw new $$in.InfusionError(
          'expand.dir() only accepts/**/alone')
      }
    }
  }

  var parts = mask.split(path.sep);
  var base = path.dirname(In.opts.$$caller.FileName);
  var Path;
  var relative = false;

  if (parts[0][0] == '.') {
    Path = path.normalize(base + path.sep + parts[0]);
    relative = true
  } else {
    Path = parts[0] + path.sep + (parts[1][0] !== '*' ? parts[1]: '');
  }

  var findings = [];
  var found = function(fullname, stat) {
    findings.push({filename: fullname, stat: stat})
  }
  var restore = function(filename) {
    var restored;
    if (relative) {
      restored = path.relative(base, filename);
      if (restored[0] == '.') return restored;
      return '.' + path.sep /* windows? */ + restored;
    }
    return filename;
  }

//   var restore = function(filename) {
//     var relative;
//     if (base) {
//       relative = path.relative(base, filename)
//       if (relative[0] == '.') return relative;
//       return '.' + path.sep /* windows? */ + relative;
//     }
//     return filename;
//   }

  return $$in.promise(function(resolve, reject, notify) {

    Expander.recurse(found, 0, 0, parts, Path, includeFiles, includeDirs)
    .then(
      function() {
        resolve(findings.map(function(found) {
          return restore(found.filename)
        }))
      },
      reject,
      notify
    )
  });
}

Expander.recurse = function(found, depth, deeper, parts, Path, includeFiles, includeDirs) {
  return $$in.promise(function(resolve, reject, notify) {

    var jump = 1;
    var next = parts[depth + jump];
    var match;

    if (deeper > 0) { // **
      jump = deeper;
      match = parts[depth + deeper + 1];
      next = parts[depth + deeper + 2];
    } else {
      if (next.indexOf('*') >= 0) {
        match = next;
      } else {
        while (
          parts.length > depth + jump + 1 && 
          parts[depth + jump + 1].indexOf('*') < 0) {
          next += path.sep + parts[depth + ++jump]
        }
        match = parts[depth + jump + 1];
        Path = Path + path.sep + next;
      }
    }

    fs.readdir(Path, function(err, files) {
      if (err) return reject(err);

      Expander.stats(Path, files).then(
        function(stats) {
          var keepStats = [];

          $$in.sequence(files

            .filter(function(name) {

              var stat;
              keepStats.push(stat = stats.shift());

              if (match == '**') {
                if (stat.isDirectory()) return true;
                if (deeper > 0) {
                  if (Expander.match(name, depth, deeper, parts)) return true;
                }
              } else {
                if (Expander.match(name, depth, jump - 1, parts)) return true;
              }
              keepStats.pop();
              return false;
            })

            .map(function(name) {

              return function() {
                var stat = keepStats.shift()
                nextPath = Path + path.sep + name;

                if (!stat.isDirectory()) {
                  return found(nextPath, stat)
                }
                if (match == '**') {
                  if (deeper == 0) {
                    return Expander.recurse(
                      found, depth, deeper + jump, parts, nextPath,
                      includeFiles, includeDirs
                    );
                  } else {
                    return Expander.recurse(
                      found, depth, deeper, parts, nextPath,
                      includeFiles, includeDirs
                    );
                  }
                }
                else if (parts.length - depth - jump - 2 > 0) {
                  // not last match part
                  return Expander.recurse(
                    found, depth + 1, 0, parts, nextPath,
                    includeFiles, includeDirs
                  );
                }
              }
            })
          ).then(resolve, reject, notify)
        },
        reject,
        notify
      )
    });
  });
}

Expander.match = function(name, depth, jump, parts, stat) {
  var prev = parts[depth + jump + 1];
  var match = parts[depth + jump + 2];
  var regex = '^' + match.replace(/\*/g, '(.+)') + '$';
  // console.log({name: name, match: match, regex: regex, prev: prev});
  return name.match(new RegExp(regex)) !== null;
}

Expander.stats = function(Path, files) {
  return $$in.sequence( // ? parallel
    files.map(function(name) {
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
