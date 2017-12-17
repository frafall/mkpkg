#!/bin/bash
#
# mkpkg - create an archive of a local git repository
#
# Run the mkpkg in a cloned and checked out repository
# The result will be a .zip and .tar.gz
#

# For generic packing I should clone the package, checkout tag and clone the submodules
# Then run this code.. make a command with options? Move to Python?
#
# To do that we need <package_url> and <tag>
# mkpkg <url> <tag>

# Check if we are in a git repository
git status > /dev/null 2>&1
if [ $? -ne 0 ]; then
   echo "Current directory is not a git!"
   exit 2
fi

# Check if any submodules exist and are cloned
git submodule | { 
   let count=0
   while read sha1 path version; do

      # Any submodules not cloned, incorrect version or in conflict?
      if [[ "${sha1#-}" != "${sha1}" ]] || [[ "${sha1#+}" != "${sha1}" ]] || [[ "${sha1#U}" != "${sha1}" ]]; then
         exit 255
      fi
      let count=count+1
   done
   
   # Submodules found and are cloned
   if [ $count -gt 0 ]; then
      exit 0
   fi

   # No submodules
   exit 254
}
return=$?

if [ $return -eq 255 ]; then
   echo "Some or all submodules in packages have not been cloned correctly:"
   git submodule status
   exit 2
fi

if [ $return -eq 254 ]; then
   echo "No submodules in packages, github's archive works without mkpkg"
   exit 2
fi

# Build the needed variables
PACKAGE=`git config --local remote.origin.url | sed -n 's#.*/\([^.]*\)\.git#\1#p'`
VERSION=`git symbolic-ref -q --short HEAD || git describe --tags --exact-match`
PREFIX=${PACKAGE}-${VERSION}

echo "Packing ${PREFIX}"

# Create a temporary directory
WORK=`mktemp -d`
#WORK=`mktemp -d --tmpdir=.`
PACKAGE_DIR=${PWD}

# Create tarball
git archive --prefix "${PREFIX}/" "${VERSION}" --format "tar" --output "${WORK}/repo-output.tar" 

# Get the tarball of submodules
git submodule -q foreach --recursive \
    'git archive --prefix='${PREFIX}'/${path} --format tar "${sha1}" --output "'${WORK}'/repo-output-sub-${sha1}.tar"'

# Concatinate archives
(
   cd ${WORK}
   if ls repo-output-sub*.tar 1> /dev/null 2>&1; then
      tar --concatenate --file repo-output.tar repo-output-sub*.tar
      rm -rf repo-output-sub*.tar
   fi

   # Unpack the tar
   tar -xf repo-output.tar

   # Build a zip
   zip -rq ${PREFIX}.zip ${PREFIX}

   # compress it and place where we want it
   gzip --quiet --force repo-output.tar
)
   
mv ${WORK}/repo-output.tar.gz ./${PREFIX}.tar.gz
mv ${WORK}/${PREFIX}.zip ./${PREFIX}.zip

# Clean up
rm -rf ${WORK}
exit 0

