# gr38-convnotes
My Notes for Converting GNU Radio 3.7 OOT modules to 3.8

This is a collection of notes on finally successfully converting GNURadio OOT modules from 3.7 to 3.8.  I also include a setup script for Ubuntu 18 that installs GNU Radio 3.8 from the respective sources with versions of what I call standard modules for my installs including a ported OSMOSDR ported to 3.8. 

NOTE: The included install scripts have only been tested on Ubuntu 18 with any other GNU Radio versions removed first.  One script does complete install direct from source, and the other leverages pybombs as much as possible.
 


## Migration Process Notes

Porting guide: https://wiki.gnuradio.org/index.php/GNU_Radio_3.8_OOT_Module_Porting_Guide#API_Changes
 
* Most of the problems encountered appear to be related to makefile updates rather than code itself, such as missing library bindings.  So this process seems to work well:
 
### Prep
* Copy your current working 3.7 module somewhere "safe" (aka make a backup)
* Copy the current OOT to an OOT37 directory
* From the new OOT37 directory, run `gr_modtool update --complete` to migrate the grc/xml files over to YML

### Creating the new structure and copyng the files that can be directly copied
    gr_modtool newmod <oot name>
    cp <oot37>/include/<module>/* <oot>/include/<module>/
    cp <oot37>/grc/* <oot>/grc

Search `grc/yml` files for `vlen` and make sure it translated the variable name correctly.  If there’s a `vlen` if statement or something in the file, the `gr_modtool` isn’t picking up the name right and using it.  It’s defaulting to `vlen`, which may be wrong.
    
    cp <oot37>/lib/*.c* <oot>/lib/
    cp <oot37>/lib/*.h <oot>/lib/
    cp <oot37>/swig/<oot>_swig.i <oot>/swig
    cp <oot37>/README.MD  to your new <oot>
    cp <oot37>/LICENSE to your new <oot>
    cp <oot37>/examples to <oot>/examples
    
If you're tied to a git repo, also copy `<oot37>/.git` to `<oot>`.  This will preserve your `master` branch tie.  Later you'll create a new branch from your existing `<oot37>` code, so this will keep your tie to `master` (if that's what you want).

* Anything else unique to this module to address?

### Python Modules
The python directory you have to be a little more careful with.  Copy your `.py` module files but not the others `(__init__.py, etc.)`

Edit the new `__init__.py` and add in the custom module imports using a relative `.` Reference

If you have any python 2.7 `print “”` statements, convert them over to `print()` calls.  Python tool `2to3` automates 90% of conversion.

If you are using strings in any way with transmission mechanisms such as sockets, Python3 handles these differently.  You'll need to `strval.encode("UTF-8")` and `strval.decode("UTF-8")` where you just used straight strings before to convert them to/from bytes.  This can cause some significant issues if one side of the link is python2 and the other is python3.  For instance, using mprpc's `RPCClient` from python2 on one side to python3 on the other almost won't work due to the byte format change issue.  With that said, in most cases adding the `.encode()` and `.decodde()` will fix the issue.

### Lib Makefile

Go through `lib/CmakeLists.txt` and look for any libraries or `find_package` calls that are not standard.  Generally this will be around a line that looks like this:

    target_link_libraries(gnuradio-grnet gnuradio::gnuradio-runtime <ANY MISSING LIBRARIES/MODULES HERE>)

Add all library `.cc` files back into the `"list(APPEND <modulename>_sources"` list

At this point you can cmake/build/install

#### Notes
* If when testing in GR, it says `module-not-found`, the most common cause was a missed linked library in `lib/Cmake`.  For instance if you were using a gnuradio component that now isn't in your link list.

* Make sure in your `yml` files that parameters have a `dtype` defined.

* Any hide: attributes will no longer take `''`.  Change those to `none`.

* Once all is working, move the new `<oot>` directory to `<oot38>` and restore your old `<oot>` from the backup you first made (not the one you ran the `update --complete` in)
 

## Updating Github

### Prep:
In the 3.7 module copy the `.git` directory over to the new 3.8 directory (this will have the reference to `master` so we can make all the `master` add/update/deletes)


In the 3.7 module:
    
    git tag v3.7
    git checkout -b maint-3.7
    git push --set-upstream origin maint-3.7
 
In the new 3.8 module:
* Do a `git status` and resolve any not-added files (like the `yml's`, etc.)

* When ready do a `git commit` and `git push`.
