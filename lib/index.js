var Expander = require('./expander');
var sequence = require('when/sequence');
var promise = require('when').promise;
var multiple;

if (typeof $$in !== 'undefined') {
  
  $$in.expanders.dir = function(In, mask, maskN) {
    var args = Array.prototype.slice.call(arguments);
    return multiple(args.shift(), args, true, true);
  }
  $$in.expanders.files = function(In, mask) {
    var args = Array.prototype.slice.call(arguments);
    return multiple(args.shift(), args, true, false);
  }
  $$in.expanders.dirs = function(In, mask) {
    var args = Array.prototype.slice.call(arguments);
    return multiple(args.shift(), args, false, true);
  }
}

module.exports.dir = function(mask, maskN) {
  var In = {
    opts: {
      $$caller: Expander.getCaller()
    }
  }
  var masks = Array.prototype.slice.call(arguments);
  return multiple(In, masks, true, true);
}

module.exports.files = function(mask) {
  var In = {
    opts: {
      $$caller: Expander.getCaller()
    }
  }
  var masks = Array.prototype.slice.call(arguments);
  return multiple(In, masks, true, false);
}

module.exports.dirs = function(mask) {
  var In = {
    opts: {
      $$caller: Expander.getCaller()
    }
  }
  var masks = Array.prototype.slice.call(arguments);
  return multiple(In, masks, false, true);
}

multiple = function(In, masks, doFiles, doDirs) {
  return promise(function(resolve, reject, notify) {
    sequence(masks.map(function(mask) {
      return function() {
        return Expander.perform(In, mask, doFiles, doDirs);
      }
    })).then(
      function(results) {
        if (results.length == 1) {
          if (In.arg) {
            Object.defineProperty(In.arg, 'info', {
              value: results[0].info
            });
          }
          return resolve(results[0]);
        }
        var combined = [];
        var combinedInfo = [];
        results.forEach(function(array) {
          array.forEach(function(file) {
            var info = array.info.shift();
            info.i = combined.length;
            combined.push(file);
            combinedInfo.push(info);
          })
        })
        Object.defineProperty(combined, 'info', {
          value: combinedInfo
        });
        if (In.arg) {
          Object.defineProperty(In.arg, 'info', {
            value: combinedInfo
          });
        }
        resolve(combined);
      },
      reject,
      notify
    )
  });
}

