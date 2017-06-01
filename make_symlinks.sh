#!/bin/bash
shopt -s extglob
stow -t ~/bin -v !(boneyard)/
