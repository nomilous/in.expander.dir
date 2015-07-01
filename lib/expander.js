// tODO: enable regex in path mask maybe

module.exports = Expander;

var path = require('path');
var fs = require('fs');
var AnError = Error;
var promise = require('when').promise;
var sequence = require('when/sequence');

function Expander() {}


if (typeof $$in !== 'undefined') {
  AnError = $$in.InfusionError;

  $$in.expanders.dir = function(In, mask) {
    return Expander.perform(In, mask, true, true);
  }
  $$in.expanders.files = function(In, mask) {
    return Expander.perform(In, mask, true, false);
  }
  $$in.expanders.dirs = function(In, mask) {
    return Expander.perform(In, mask, false, true);
  }
}

Expander.dir = function(mask) {
  var In = {
    opts: {
      $$caller: Expander.getCaller()
    }
  }
  return Expander.perform(In, mask, true, true);
}

Expander.files = function(mask) {
  var In = {
    opts: {
      $$caller: Expander.getCaller()
    }
  }
  return Expander.perform(In, mask, true, false);
}

Expander.dirs = function(mask) {
  var In = {
    opts: {
      $$caller: Expander.getCaller()
    }
  }
  return Expander.perform(In, mask, false, true);
}

Object.defineProperty(Expander, 'getCaller', {
  value: function() {
    var prep = Error.prepareStackTrace;
    Error.prepareStackTrace = function(e, stack){return stack;}
    var e = new Error();
    var frame = e.stack[2];
    Error.prepareStackTrace = prep;
    return {
      FileName: frame.getFileName(),
      LineNumber: frame.getLineNumber(),
      ColumnNumber: frame.getColumnNumber()
    }
  }
});

Object.defineProperty(Expander, 'perform', {
  value: function(In, mask, includeFiles, includeDirs) {
    if (!mask.match(/\*+/))
      throw new AnError(
        'expand.dir() expects at least one wildcard');

    var valid = mask.split('**');
    if (valid.length > 1) {
      for (var i = 0; i < valid.length - 1; i++) {
        if (valid[i][valid[i].length - 1] !== path.sep 
          || valid[i+1][0] !== path.sep) {
          throw new AnError(
            'expand.dir() only accepts/**/alone')
        }
      }
    }

    var parts = mask.split(path.sep);
    var base = path.dirname(In.opts.$$caller.FileName);
    var Path;
    var relative = false;
    var depth, i;

    if (parts[0][0] == '.') {
      i = 0;
      var r = '';
      while (parts[i][0] == '.') {
        r = r + path.sep + parts[i]
        i++;
      }
      relative = true
      depth = i - 1;
      Path = path.normalize(base + path.sep + r);
    } else {
      Path = parts[0] + path.sep + (parts[1][0] !== '*' ? parts[1]: '');
      depth = 1;
    }

    var findings = [];
    var found = function(fullname, stat) {
      findings.push({filename: fullname, stat: stat})
    }
    var restore = function(found) {
      var restored;
      if (relative) {
        restored = path.normalize(path.relative(base, found.filename));
        if (restored[0] == '.') {
          // BUG: search for ../* finds 'this' directory and reports as '.'
          return restored;
        }
        return '.' + path.sep /* windows? */ + restored;
      }
      return path.normalize(found.filename);
    }

    return promise(function(resolve, reject, notify) {
      var jump, deeper;
      Expander.recurse(

        found,      // reports back()
        depth,      // ./from/start/../../how/far/in
        jump = 1,   // ./it/jumps/till/first/*
        deeper = 0, // ./for/controlling/ ** /recursion
        parts,
        Path,
        includeFiles,
        includeDirs

      ).then(
        function() {
          resolve(findings
            .filter(function(found) {
              if (found.stat.isDirectory()) {
                return includeDirs;
              } else {
                return includeFiles;
              }
            })
            .map(restore)
          )
        },
        reject,
        notify
      )
    });
  }
});

Object.defineProperty(Expander, 'recurse', {
  value: function(found, depth, jump, deeper, parts, Path) {
    return promise(function(resolve, reject, notify) {

      var next = parts[depth + jump];
      var match;

      if (deeper > 0) { // **
        jump = deeper;
        match = parts[depth + deeper + 1];
        next = parts[depth + deeper + 2];
      } else {
        if (next) {
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
      }

      fs.readdir(Path, function(err, files) {
        if (err) return reject(err);

        Expander.stats(Path, files).then(
          function(stats) {
            var keepStats = [];

            sequence(files

              .filter(function(name) {

                var stat;
                keepStats.push(stat = stats.shift());

                if (match == '**') {
                  if (stat.isDirectory()) return true;
                  if (deeper > 0) {
                    if (Expander.match(Path, name, depth, deeper, parts)) return true;
                  }
                } else {
                  if (Expander.match(Path, name, depth, jump - 1, parts)) return true;
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
                        found, depth, jump, deeper + 1, parts, nextPath
                      );
                    } else {
                      return Expander.recurse(
                        found, depth, jump, deeper, parts, nextPath
                      );
                    }
                  }
                  else if (parts.length - depth - jump - 2 > 0) {
                    // not last match part
                    // console.log({round: nextPath, depth: depth + 1, match: match})
                    
                    return Expander.recurse(
                      found, depth + 1, jump, 0, parts, nextPath
                    );
                  }
                  else {
                    return found(nextPath, stat);
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
});

Object.defineProperty(Expander, 'match', {
  value: function(Path, name, depth, jump, parts, stat) {
    var prev = parts[depth + jump + 1];
    var match = parts[depth + jump + 2];
    var regex;
                     // [/]extra/part
    if (Path[0] == '/' && parts[0] == '') match = parts[depth + jump];
    if (!match) match = prev; // dunno...
    regex = '^' + match.replace(/\*/g, '(.+)') + '$';
    return name.match(new RegExp(regex)) !== null;
  }
});


Object.defineProperty(Expander, 'stats', {
  value: function(Path, files) {
    return sequence( // ? parallel
      files.map(function(name) {
        return function() {
          return promise(function(resolve, reject) {
            fs.stat(Path + path.sep + name, function(err, stat) {
              if (err) return reject(err);
              resolve(stat);
            })
          })
        }
      })
    )
  }
});
