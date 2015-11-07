#!/bin/bash

# In my installation, I have a symbolic link
# from /usr/local/bin/_qswitch to qswitch.pl 

qsw() {
    _qswitch $@ > /tmp/qsw.bash
    source /tmp/qsw.bash
}

_qsw_complete() {
    COMPREPLY=($(COMP_CWORD=$COMP_CWORD perl /usr/local/bin/_qswitch ${COMP_WORDS[@]:0} ))
}

complete -F _qsw_complete qsw
