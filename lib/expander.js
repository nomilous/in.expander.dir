// tODO: enable regex in path mask maybe
// TODO: notify every n

module.exports = Expander;

var path = require('path');
var fs = require('fs');
var AnError = Error;
var promise = require('when').promise;
var sequence = require('when/sequence');
var merge = require('merge');

function Expander() {}

if (typeof $$in !== 'undefined') AnError = $$in.InfusionError;

Expander.perform = function(In, mask, doFiles, doDirs) {
  return promise(function(resolve, reject, notify) {

    if (Expander.invalid(mask, reject)) return;

    var absolute = path.isAbsolute(mask);
    var home = mask[0] == '~';
    var findings = [];
    var exinfo = {};
    var found;
    var report;
    var match, next, jump;
    var Path;
    var base;
    var parts;
    var depth;
    var maskParts;

    if (home) {
      base = process.env[(process.platform == 'win32') ? 'USERPROFILE' : 'HOME'];
      parts = (path.normalize(base + path.sep + mask.substr(1))).split(path.sep);
      maskParts = (path.normalize(base + path.sep + mask)).split(/\*+/);
    } else if (!absolute) {
      base = path.dirname(In.opts.$$caller.FileName);
      parts = (path.normalize(base + path.sep + mask)).split(path.sep);
      maskParts = (path.normalize(base + path.sep + mask)).split(/\*+/);
    } else {
      parts = mask.split(path.sep);
      maskParts = mask.split(/\*+/);
    }

    Path = parts[0];
    if (Path == '') Path += path.sep;

    found = Expander.found(findings, exinfo, parts);
    report = Expander.report(doFiles, doDirs, absolute, home, mask, base, findings);

    exinfo.depth = 0;
    exinfo.m = [];
    Expander.recurse(match, next, jump = 0, Path, parts, depth = 1, exinfo, found)
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
          'expand.dir() invalid use of **')
        );
        return true;
      }
    }
  }
  return false;
}

Expander.found = function(findings, exinfo, parts) {
  return function(fullname, stat, depth, matchedNext) {
    var detail;
    var regex;
    var match;

    findings.push(detail = {
      fullname: fullname,
      stat: stat,
      matches: [],
    });

    for (var i = exinfo.m.length; i >= 0; i--) {
      if (matchedNext && i == depth + 1) {
        exinfo.m[i-1][exinfo.m[i-1].length - 1] = undefined;
        regex = Expander.toRegex(parts[depth + 1]);
        if (match = matchedNext.match(regex)) {
          match.slice(1).reverse().forEach(function(m) {
            detail.matches.push(m);
          })
        }
      }
      if (!(exinfo.m[i] instanceof Array)) continue;
      if (parts[i] == '**') {
        detail.matches.push(exinfo.m[i].filter(function(m){
          return !!m;
        }).join(path.sep));
      } else {
        regex = Expander.toRegex(parts[i]);        
        if (match = exinfo.m[i][0].match(regex)) {
          match.slice(1).reverse().forEach(function(m) {
            detail.matches.push(m);
          })
        }
      }
    }
  }
}

Expander.report = function(doFiles, doDirs, absolute, home, mask, base, findings) {
  return function() {
    var exinfo = [];
    var result = findings
    .filter(function(found) {
      if (found.stat.isDirectory()) return doDirs
      else return doFiles;
    })
    .map(function(found) {
      var info;
      var restored;
      var i = 1;
      if (absolute) restored = path.normalize(found.fullname);
      else if (mask[0] == '.') {
        if (mask[1] == '.') {
          restored = path.relative(base, found.fullname);
                //  ../thisdir
          if (restored == '' || restored == '.') restored = '..' + path.sep + base.split(path.sep).pop();
        }
        else restored = '.' + path.sep + path.relative(base, found.fullname);
      } else {
        restored = path.relative(base, found.fullname);
      }
      if (home) {
        restored = '~' + path.sep + restored;
      }
      info = {value: restored};
      info.fullname = found.fullname;
      merge(info, path.parse(found.fullname));
      info.m = found.matches;
      merge(info, found.stat);
      exinfo.push(info);
      return restored;
    })
    Object.defineProperty(result, 'info', {
      value: exinfo
    });
    return result;
  }
}

Expander.recurse = function(match, next, jump, Path, parts, depth, exinfo, found) {
  return promise(function(resolve, reject, notify) {

    match = parts[depth];
    while (depth < parts.length && !match.match(/\*/)) {
      Path = path.normalize(Path + path.sep + match);
      match = parts[++depth];

    }
    next = parts[depth + 1];

    fs.readdir(Path, function(err, files) {
      if (err) {
        if (err.code == 'EACCES') {
          var message = {
            type: 'error.ignored',
            error: err
          };
          notify(message);
          console.error(err.toString()); //TODO: nolog on notify heed
          return resolve();
        }
        return reject(err);
      }
      Expander.stats(Path, files).then(
        function(stats) {
          var keeps = [];
          sequence(files
            .filter(Expander.filter(match, next, jump, stats, keeps))
            .map(Expander.exinfo(match, next, jump, Path, parts, depth, stats = keeps, exinfo, found))
          ).then(resolve, reject, notify);
        },
        function(err) {
          console.log(err);
          reject(err);
        },
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
    if (stat) {
      if (match == '**') {
        if (stat.isDirectory()) return true;
        if (next && jump > 0) return true;
      }
      else if (fileName.match(regex)) return true;
    }
    keeps.pop();
    return false
  }
}

Expander.exinfo = function(match, next, jump, Path, parts, depth, stats, exinfo, found) {
  return function(fileName) {
    return function() {
      return promise(function(resolve, reject, notify) {

        if (depth != exinfo.depth) {
          exinfo.m.length = depth + 1;
          if (!exinfo.m[depth]) exinfo.m[depth] = [];
          exinfo.depth = depth;
        }
        if (depth < exinfo.m.length - 1) {
          exinfo.m.length = depth + 1;
        }
        exinfo.m[depth].push(fileName);

        Expander.mapper(
          fileName, match, next, jump, 
          Path, parts, depth, stats, exinfo, found
        ).then(
          function() {
            exinfo.m[depth].pop();
            resolve();
          },
          reject,
          notify
        );
      });
    }
  }
}

Expander.mapper = function(fileName, match, next, jump, Path, parts, depth, stats, exinfo, found) {
  var prev;
  var stat = stats.shift();
  var nextPath = path.normalize(Path + path.sep + fileName);
  var regex;
  var matchedNext;
  var then = {then: function(resolve) {resolve(matchedNext);}}

  if (match == '**') {
    if (jump > 0) {
      regex = Expander.toRegex(next);
      if (fileName.match(regex)) {
        if (stat.isDirectory()) {
          if (next == '*') {
            // keep going on /**/*  ??
            return Expander.recurse(match, next, jump + 1, nextPath, parts, depth, exinfo, found);
          }
          return Expander.recurse(match, next, 0, nextPath, parts, depth + 1, exinfo, found);
        } else {
          if (!parts[depth + 1 + 1]) {
            found(nextPath, stat, depth, matchedNext = fileName);
            return then;
          }
        }
      } else {
        if (stat.isDirectory()) {
          return Expander.recurse(match, next, jump + 1, nextPath, parts, depth, exinfo, found);
        }
      }
    } else {
      if (stat.isDirectory()) {
        return Expander.recurse(match, next, jump + 1, nextPath, parts, depth, exinfo, found);
      }
    }       
  } else {
    if (!next) {
      found(nextPath, stat, depth);
      return then;
    }
    if (!stat.isDirectory()) return then;
    return Expander.recurse(match, next, 0, nextPath, parts, depth + 1, exinfo, found);
  }
  return then;
}

Expander.toRegex = function(str) {
  str = str.replace(/\./g, '\\.');
  str = str.replace(/\*/g, '(.+)');
  return new RegExp('^' + str + '$');
}

Expander.stats = function(Path, files) {
  return sequence(
    files.map(function(name) {
      return function() {
        return promise(function(resolve, reject, notify) {
          fs.lstat(Path + path.sep + name, function(err, stat) {
            if (err) {
              if (err.code == 'EBADF') {
                var message = {
                  type: 'error.ignored',
                  error: err
                };
                notify(message);
                console.error(err.toString());
                return resolve();
              }
              return reject(err);
            }
            // if (stat.isSymbolicLink()) {
            //   if (stat.isDirectory()) {
            //     return resolve();
            //   }
            // }
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

