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
rock $OOC_FLAGS -libfolder=source/core -dynamiclib=$LIBDIR/liboc-core.so $OOC_FLAGS || exit 2

echo "Compiling oc (launcher)"
rock $OOC_FLAGS -sourcepath=source -packagefilter=launcher launcher/main -L$LIBDIR -gc=dynamic -lrock-sdk -loc-core -lnagaqueen -o=bin/oc $OOC_FLAGS || exit 1