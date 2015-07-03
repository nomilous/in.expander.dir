// tODO: enable regex in path mask maybe

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

    if (!absolute) {
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
    report = Expander.report(doFiles, doDirs, absolute, mask, base, findings);

    exinfo.count = 0;
    exinfo.depth = 1;
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
  return function(fullname, stat) {
    var detail;
    findings.push(detail = {
      fullname: fullname,
      stat: stat,
      matches: [],
    });

    Object.keys(exinfo).forEach(function(key) {
      if (!key.match(/^m\d/)) return;
      var part;
      var depth = exinfo[key].depth;
      var regex;
      var matches;
      var last;
      if (parts[depth] == '**') {
        regex = /(.+)/
        if (key == 'm' + exinfo.count) {
          last = exinfo[key].parts.pop();
        }
      } else {
        regex = Expander.toRegex(parts[depth]);
      }
      part = exinfo[key].parts.join(path.sep);
      if (matches = part.match(regex)) {
        for (var i = 1; i < matches.length; i++) {
          detail.matches.push(matches[i])
        }
      }
      if (last) {
        regex = Expander.toRegex(parts[parts.length - 1]);
        if (matches = last.match(regex)) {
          for (var i = 1; i < matches.length; i++) {
            detail.matches.push(matches[i])
          }
        }
      }
    })
  }
}

Expander.report = function(doFiles, doDirs, absolute, mask, base, findings) {
  return function() {
    var ex = [];
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
      info = {found: restored};
      info.filename = found.fullname;
      merge(info, path.parse(found.fullname));
      info.m = found.matches;
      info.stat = found.stat;
      ex.push(info);
      return restored;
    })
    Object.defineProperty(result, 'ex', {
      value: ex
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
      if (err) return reject(err);
      Expander.stats(Path, files).then(
        function(stats) {
          var keeps = [];
          sequence(files
            .filter(Expander.filter(match, next, jump, stats, keeps))
            .map(Expander.exinfo(match, next, jump, Path, parts, depth, stats = keeps, exinfo, found))
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

Expander.exinfo = function(match, next, jump, Path, parts, depth, stats, exinfo, found) {
  // expensive, perhaps make optional
  return function(fileName) {
    return function() {
      return promise(function(resolve, reject, notify) {

        if (depth != exinfo.depth) {
          if (depth > exinfo.depth) {
            exinfo.count++;
            exinfo['m'+exinfo.count] = {
              depth: depth,
              parts: [fileName]
            };
            exinfo.depth = depth;
          } else {
            Object.keys(exinfo).forEach(function(key) {
              if (!key.match(/^m\d/)) return;
              if (exinfo[key].depth < depth) {
                delete exinfo[key];
                exinfo.count--;
              } else if (exinfo[key].depth == depth) {
                exinfo.count--;
                if (exinfo['m'+exinfo.count]) {
                  exinfo['m'+exinfo.count].parts.pop();
                  exinfo['m'+exinfo.count].parts.push(fileName);
                } else {
                  exinfo['m'+exinfo.count] = {
                    depth: depth,
                    parts: [fileName]
                  };
                }
              }
            });
            exinfo.depth = depth;
          }
        } else {
          if (exinfo.count != 0) {
            exinfo['m'+exinfo.count].parts.push(fileName);
          }
        }

        var promise = Expander.mapper(
          fileName, match, next, jump, 
          Path, parts, depth, stats, exinfo, found
        );
        if (promise && typeof promise.then == 'function') {
          return promise.then(
            function() {
              if (exinfo.count != 0) {
                exinfo['m'+exinfo.count].parts.pop();
              }
              resolve();
            },
            reject,
            notify
          );
        }
        if (exinfo.count != 0) {
          exinfo['m'+exinfo.count].parts.pop();
        }
        resolve();
      });
    }
  }
}

Expander.mapper = function(fileName, match, next, jump, Path, parts, depth, stats, exinfo, found) {
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
          return Expander.recurse(match, next, 0, nextPath, parts, depth + 1, exinfo, found);
        } else {
          return found(nextPath, stat)
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
    if (!next) return found(nextPath, stat);
    if (!stat.isDirectory()) {
      if (match != '*') return found(nextPath, stat);
      return
    }
    return Expander.recurse(match, next, 0, nextPath, parts, depth + 1, exinfo, found);
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

