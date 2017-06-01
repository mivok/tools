# Tools

A collection of small scripts I've found useful

## Directories

* boneyard - old scripts that are no longer valid or useful any more
* grafana - tools for working with grafana
* misc - scripts that don't have a better place for them yet
* s3 - tools for working with s3 (s3_sign, s3shell, s3shorten)
* ssh - helpers for sshing into other machines - (ssh-via, knife-pssh)
* web - tools for working with the web (ssl-tool, check_redirect)

## Installation

The tools can be used directly, or can be installed to your ~/bin directory
using GNU stow:

```
# Requires shopt -s extglob in bash
stow -v -t ~/bin !(boneyard)/
# Or, for individual directories
stow -v -t ~/bin grafana misc s3 ssh web
```
