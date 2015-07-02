var Expander = require('./expander');

if (typeof $$in !== 'undefined') {
  
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

module.exports.dir = function(mask) {
  var In = {
    opts: {
      $$caller: Expander.getCaller()
    }
  }
  return Expander.perform(In, mask, true, true);
}

module.exports.files = function(mask) {
  var In = {
    opts: {
      $$caller: Expander.getCaller()
    }
  }
  return Expander.perform(In, mask, true, false);
}

module.exports.dirs = function(mask) {
  var In = {
    opts: {
      $$caller: Expander.getCaller()
    }
  }
  return Expander.perform(In, mask, false, true);
}
