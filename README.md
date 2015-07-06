# in.expander.dir

Directory expander for [in.](https://github.com/nomilous/in.)

## Using standalone

`npm install in.expander.dir --save`

```javascript
var ex = require('in.expander.dir');
```

### It returns a promise.

```javascript
ex.dir('./*.md')
.then(function(arrayOfNames){})
.catch(function(e){});
```

### It provides extended info

```javascript
ex.dir('./*.md')
.then(function(arrayOfNames){
  arrayOfNames.info.forEach(function(file) {
    file.value === './README.md'; // the value in arrayOfNames
    file.fullname === '/ect/etc/.../README.md';
    file.dir === '/etc/etc/etc'
    file.uid === 919;
    file.size === 28856;
    file.isSymbolicLink() === false;
    //etc...
  })
});
```

### It can search for only files

__`.files()`__

```javascript
ex.files('./node_modules/**/*')
.then(function(arrayOfFileNames){})
```

### It can search for only dirs

__`.dirs()`__

```javascript
ex.dirs('./node_modules/**/*')
.then(function(arrayOfDirNames){})
```


## Using with in.

This expander comes bundled with `in.`

`npm install in. --save`

### Basic

```javascript
require('in.');

$$in(function(
  filenames // in. {{ $$files('./**/*.json') }}
){
  filenames instanceof Array // of filenames
  // filenames.info
});
```

```javascript
$$in(function(
  files // in. {{ $$files('./**/*.json').info }}
){
  files instanceof Array // of full file info
});
```


### Advanced

Files in local directory modified in last 10 seconds

```javascript
$$in(function(
  names /* in. {{ $$files('*').info
                  .filter ({mtime}) -> mtime > Date.now() - 10 * 1000
                  .map ({value}) -> value
                }} */
){
  console.log(names)
});
```

Combine name and file size

```javascript
$$in(function(
  details // in. {{ name: f.name, size: f.size for f in $$files('*').info }}
){
  details[0] === { name: 'file_name', size: 919 };
});
```

### And finally

```javascript
$$in(function(movies) { // in. {{ $$files('~/Desktop/**/*.avi').info }}
  movies[4].m[0] === 'Her';
  movies[4].m[1] === 'untitled folder/stuff/untitled folder/movies/from clive/';
});
```

