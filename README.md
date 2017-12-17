mkpkg - build an archive including submodules 
=============================================

Overview
--------
There is a problem with build systems and github, any packages containing submodules
must be cloned to get the full source, an auto-generated archive will not include
the submodules nor the references to these.

Solution
--------
Build a .zip/.tar.gz from a cloned/checked out repository.

ex.
```
# git clone <url>
# cd <package>
# git checkout <tag>
# mkpkg.sh
# ls
...
package-tag.zip
package-tag.tar.gz
```

