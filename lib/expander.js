// tODO: enable regex in path mask maybe

module.exports = Expander;

var path = require('path');
var fs = require('fs');
var AnError = Error;
var promise = require('when').promise;
var sequence = require('when/sequence');

function Expander() {}

if (typeof $$in !== 'undefined') AnError = $$in.InfusionError;

Expander.perform = function(In, mask, includeFiles, includeDirs) {
  return promise(function(resolve, reject, notify) {

    if (Expander.invalid(mask, reject)) return;

    var absolute = path.isAbsolute(mask);
    var match, next, jump;
    var Path;
    var base;
    var parts;
    var depth;

    if (!absolute) {
      base = path.dirname(In.opts.$$caller.FileName);
      parts = (path.normalize(base + path.sep + mask)).split(path.sep);
      // mask = path.normalize(base + path.sep + mask);
    } else parts = mask.split(path.sep);
    
    Path = parts[0];
    if (Path == '') Path += path.sep;

    var findings = []
    var found = function(fullname, stat) {
      findings.push({filename: fullname, stat: stat})
    }
    var report = function() {
      return findings
      .filter(function(found) {
        if (found.stat.isDirectory()) return includeDirs
        else return includeFiles;
      })
      .map(function(found) {
        var restored;
        if (absolute) restored = path.normalize(found.filename);
        else if (mask[0] == '.') {
          if (mask[1] == '.') {
            restored = path.relative(base, found.filename);
                  //  ../thisdir
            if (restored == '' || restored == '.') restored = '..' + path.sep + base.split(path.sep).pop();
          }
          else restored = '.' + path.sep + path.relative(base, found.filename);
        } else {
          restored = path.relative(base, found.filename);
        }
        return restored;
      })
    }

    Expander.recurse(match, next, jump = 0, Path, parts, depth = 1, found)
    .then(
      function() {
        resolve(report());
      },
      reject,
      notify
    );
  });
}

Expander.invalid = function(mask, reject) {
  if (!mask.match(/\*+/)) {
    reject(new AnError(
      'expand.dir() expects at least one wildcard')
    );
    return true;
  }
  var valid = mask.split('**');
  if (valid.length > 1) {
    for (var i = 0; i < valid.length - 1; i++) {
      if (valid[i][valid[i].length - 1] !== path.sep 
        || valid[i+1][0] !== path.sep) {
        reject(new AnError(
          'expand.dir() only accepts/**/alone')
        );
        return true;
      }
    }
  }
  return false;
}

Expander.recurse = function(match, next, jump, Path, parts, depth, found) {
  return promise(function(resolve, reject, notify) {

    match = parts[depth];
    while (depth < parts.length && !match.match(/\*/)) {
      Path = path.normalize(Path + path.sep + match);
      match = parts[++depth];

    }
    next = parts[depth + 1];

    fs.readdir(Path, function(err, files) {
      if (err) return reject(err);

      Expander.stats(Path, files).then(
        function(stats) {
          var keeps = [];

          sequence(files
            .filter(Expander.filter(match, next, jump, stats, keeps))
            .map(Expander.mapper(match, next, jump, Path, parts, depth, stats = keeps, found))
          ).then(resolve, reject, notify);
        },
        reject,
        notify
      );
    });
  });
}

Expander.filter = function(match, next, jump, stats, keeps) {
  var regex = Expander.toRegex(match);
  return function(fileName) {
    var stat;
    keeps.push(stat = stats.shift());
    if (match == '**') {
      if (stat.isDirectory()) return true;
      if (next && jump > 0) return true;
    }
    else if (fileName.match(regex)) return true;
    keeps.pop();
    return false
  }
}

Expander.mapper = function(match, next, jump, Path, parts, depth, stats, found) {
  return function(fileName) {
    return function() {
      var prev;
      var stat = stats.shift();
      var nextPath = Path + path.sep + fileName;
      var regex;

      if (match == '**') {
        if(!next) return;
        if (jump > 0) {
          regex = Expander.toRegex(next);
          if (fileName.match(regex)) {
            if (stat.isDirectory()) {
              return Expander.recurse(match, next, 0, nextPath, parts, depth + 1, found);
            } else {
              return found(nextPath, stat)
            }
          } else {
            if (stat.isDirectory()) {
              return Expander.recurse(match, next, jump + 1, nextPath, parts, depth, found)
            }
          }
        } else {
          if (stat.isDirectory()) {
            return Expander.recurse(match, next, jump + 1, nextPath, parts, depth, found)
          }
        }       
      } else {
        if (!next) return found(nextPath, stat);
        if (!stat.isDirectory()) {
          if (match != '*') return found(nextPath, stat);
          return
        }
        return Expander.recurse(match, next, 0, nextPath, parts, depth + 1, found);
      }
    }
  }
}

Expander.toRegex = function(str) {
  str = str.replace(/\./g, '\\.');
  str = str.replace(/\*/g, '(.+)');
  return new RegExp('^' + str + '$');
}

Expander.stats = function(Path, files) {
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

Expander.getCaller = function() {
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

