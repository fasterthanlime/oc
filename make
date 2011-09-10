#!/bin/bash
mkdir -p bin .libs

if [[ ! -e $PREFIX ]]; then
    export PREFIX=$PWD/prefix
    mkdir -p $PREFIX
fi

if [[ ! -e $LIBDIR ]]; then
    export LIBDIR=$PREFIX/lib
    mkdir -p $LIBDIR
fi

echo Library directory is $LIBDIR

export OOC_LIBS=..
OOC_FLAGS="-v -g -nolines +-rdynamic"

echo "Compiling sdk"
if [[ ! -e $ROCK_DIST ]]; then
    ROCK_DIST=../rock
fi

#FIXME: *nix-specific (.so)
rock $OOC_FLAGS -libfolder=$ROCK_DIST/sdk -dynamiclib=$LIBDIR/librock-sdk.so || exit 1

echo "Compiling oc (core)"
BUILD_DATE="\"$(date '+%Y-%m-%d at %H:%M')\""
rock $OOC_FLAGS -libfolder=source/core -dynamiclib=$LIBDIR/liboc-core.so +-DBUILD_DATE="$(BUILD_DATE)" || exit 2

echo "Compiling oc (launcher)"
rock $OOC_FLAGS -sourcepath=source -packagefilter=launcher launcher/main -L$LIBDIR -gc=dynamic -lrock-sdk -loc-core -lnagaqueen -o=bin/oc $OOC_FLAGS || exit 3

echo "Compiling pseudo backend"
rock $OOC_FLAGS -libfolder=source/pseudo-backend -dynamiclib=plugins/pseudo_backend.so || exit 4
