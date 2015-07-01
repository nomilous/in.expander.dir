# in.expander.dir

Directory expander for [in.](https://github.com/nomilous/in.)

`npm install in.expander.dir --save`

## Using standalone

```javascript
var ex = require('in.expander.dir');
```

### It return a promise.

```javascript
ex.dir('./*.md')
.then(function(arrayOfNames){})
.catch(function(e){});
```

### It can search for only files

`.files()`

```javascript
ex .files('./node_modules/**/*')
.then(function(arrayOfFileNames){})
.catch(function(e){});
```

### It can search for only dirs

`.dirs()`

```javascript
ex .dirs('./node_modules/**/*')
.then(function(arrayOfDirNames){})
.catch(function(e){});
```


## Using with in.

### Basic


### Advanced