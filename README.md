# oc

oc is an [ooc](http://ooc-lang.org) compiler written in ooc. It focuses on clean design, flexibility and scalability. oc is planned to replace [rock](http://github.com/nddrylliog/rock), the current standard ooc compiler.

## Building & installing

You can install oc easily in only 42 steps:

  * Install boehm-gc, **with thread support** (e.g. 'threads' USEflag on Gentoo). Make sure it's recent, too.
  * Make yourself a favor and [grab hub](http://defunkt.io/hub/) while you're at it.
  * Then go all like:

> export OOC_DIR=~/ooc  
> mkdir -p $OOC_DIR && cd $OOC_DIR  
> hub clone nddrylliog/rock && cd rock  
> make rescue && sudo make install  

  * This should end with 'Congrats! You have a rock in bin/rock. If it does nawt, [report an issue](https://github.com/nddrylliog/rock/issues).
  * Now it's time to get greg and nagaqueen!

> cd $OOC_DIR
> hub clone nddrylliog/greg && cd greg
> make && sudo make install

> cd $OOC_DIR
> hub clone nddrylliog/nagaqueen

  * Now we'll grab oc, along with a frontend and a backend, and compile the shiznit out of it:

> cd $OOC_DIR
> hub clone nddrylliog/oc
> hub clone nddrylliog/oc-nagaqueen
> hub clone nddrylliog/oc-c89
> export PREFIX=$OOC_DIR/oc/prefix
> cd oc-nagaqueen && ./make && cd ..
> cd oc-c89 && ./make && cd ..
> cd oc && ./make && sudo make install

  * If everything went fine, you should now be the happy owner of an oc setup!
  * Since oc is entirely modular, feel free to write another frontend, or another
    backend, and only recompile your code, not the main compiler. Yes, rock has
    some pretty awesome sides as well.

## About the transition

Oh who am I kidding, I'm changing ideas every 15 minutes anyway. We do thoroughly love zeromq lately, though :)