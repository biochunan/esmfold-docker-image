#!/bin/zsh 

# init conda
source $HOME/.zshrc 

# activate py39-esmfold
conda activate py39-esmfold

# run esm-fold
esm-fold $@