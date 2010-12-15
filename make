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

if [[ ! -e $NAGAQUEEN_DIST ]]; then
    export NAGAQUEEN_DIST=../nagaqueen
fi

if [[ ! -e .libs/NagaQueen.o ]]; then
  echo "Compiling nagaqueen"
  greg $NAGAQUEEN_DIST/grammar/nagaqueen.leg > .libs/NagaQueen.c || exit
  gcc -fPIC -w -c -std=c99 -D__OOC_USE_GC__ .libs/NagaQueen.c -O3 -o .libs/NagaQueen.o $C_FLAGS || exit 1
  rock -v -libfolder=$NAGAQUEEN_DIST/source .libs/NagaQueen.o -dynamiclib=$LIBDIR/libnagaqueen.so || exit 1
fi

export OOC_LIBS=..
OOC_FLAGS="-v -g -nolines +-rdynamic"

echo "Compiling sdk"
if [[ ! -e $ROCK_DIST ]]; then
    ROCK_DIST=../rock
fi

#FIXME: *nix-specific (.so)
rock $OOC_FLAGS -libfolder=$ROCK_DIST/sdk -dynamiclib=$LIBDIR/librock-sdk.so || exit 1

echo "Compiling oc (core)"
rock $OOC_FLAGS -libfolder=source/core -dynamiclib=$LIBDIR/liboc-core.so $OOC_FLAGS || exit 1

echo "Compiling oc (launcher)"
rock $OOC_FLAGS -sourcepath=source -packagefilter=launcher launcher/main -L$LIBDIR -gc=dynamic -lrock-sdk -loc-core -lnagaqueen -o=bin/oc $OOC_FLAGS || exit 1
