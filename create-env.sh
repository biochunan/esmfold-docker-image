#!/bin/zsh

# init conda
conda init zsh

# source .zshrc to activate conda
source $HOME/.zshrc

# install openfold
cd /home/vscode/openfold && \
    conda activate openfold-venv && \
    pip install . && \
    cd /home/vscode && \
    rm -rf /home/vscode/openfold

# install fair-esm based on openfold conda env
conda create -n py39-esmfold --clone openfold-venv && \
    conda activate py39-esmfold && \
    pip install "fair-esm[esmfold]" && \
    pip install biotite && \
    conda clean -a -y && \
    pip cache purge

# ------------------- install esmfold command -------------------
# install esm-fold command
tar -zxvf /home/vscode/esm-main.tar.gz -C /home/vscode && \
    rm /home/vscode/esm-main.tar.gz && \
    chown -R vscode:vscode /home/vscode/esm-main && \
    chmod -R 777 /home/vscode/esm-main && \
    cd /home/vscode/esm-main && \
    pip install . && \
    cd /home/vscode && \
    rm -rf /home/vscode/esm-main
