#!/bin/bash
MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
for target in $MYDIR/*; do
    [[ -x $target && -f $target ]] || continue
    BASENAME=$(basename $target)
    [[ $BASENAME == make_symlinks.sh ]] && continue
    echo $BASENAME
    ln -sf $target ~/bin/$BASENAME
done
