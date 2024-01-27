FROM nvidia/cuda:11.3.1-devel-ubuntu20.04
# 11.3 required for openfold

ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Create the user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    #
    # [Optional] Add sudo support. Omit if you don't need to install software after connecting.
    && apt-get update \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Install zsh and ohmyzsh
RUN apt-get update && apt-get install -yq zsh sudo curl wget jq vim git-core gnupg locales && apt-get clean
# RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" || true
# Default powerline10k theme, no plugins installed
RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v1.1.5/zsh-in-docker.sh)" -- \
    -t robbyrussell
RUN sudo chsh -s /bin/zsh

# credits: @pangyuteng
# refer to: https://gist.github.com/pangyuteng/f5b00fe63ac31a27be00c56996197597
# Use the above args during building https://docs.docker.com/engine/reference/builder/#understand-how-arg-and-from-interact
ARG CONDA_VER=latest
ARG OS_TYPE=x86_64
# Install miniconda to /miniconda
RUN curl -LO "http://repo.continuum.io/miniconda/Miniconda3-${CONDA_VER}-Linux-${OS_TYPE}.sh"
RUN bash Miniconda3-${CONDA_VER}-Linux-${OS_TYPE}.sh -p /miniconda -b
RUN rm Miniconda3-${CONDA_VER}-Linux-${OS_TYPE}.sh
ENV PATH=/miniconda/bin:${PATH}
RUN conda update -y conda

# Cleanup
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN conda clean -a -y && pip cache purge

# ********************************************************
# * Anything else you want to do like clean up goes here *
# ********************************************************

# [Optional] Set the default user. Omit if you want to keep the default as root.
USER $USERNAME
# add user to sudo group
RUN sudo usermod -aG sudo $USERNAME

# install oh-my-zsh for vscode
RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v1.1.5/zsh-in-docker.sh)" -- \
    -t robbyrussell

# ------------------- install OpenFold and ESM2 -------------------
RUN pip install gdown==5.0.1
# add gdown to PATH
ENV PATH="/home/vscode/.local/bin:${PATH}"
WORKDIR /home/vscode
RUN gdown --fuzzy --no-cookies --no-check-certificate -O openfold.tar.gz 1PvZLs4zeh3g_JajIsbeQmhOewoI_Stll \
    && gdown --fuzzy --no-cookies --no-check-certificate -O esm-main.tar.gz 1YE_CEOUc5FYxrEnNiQcLgttnNxUXqQj-
COPY create-env.sh /home/vscode/create-env.sh
# install openfold conda env
RUN tar -zxvf /home/vscode/openfold.tar.gz -C /home/vscode && \
    rm /home/vscode/openfold.tar.gz && \
    chown -R vscode:vscode /home/vscode/openfold && \
    chmod -R 777 /home/vscode/openfold && \
    cd /home/vscode/openfold && \
    conda env create -f /home/vscode/openfold/environment.yml
# install esm-fold command
RUN zsh /home/vscode/create-env.sh

# # copy esm-fold checkpoints
# COPY esm2_t36_3B_UR50D-contact-regression.pt  /home/vscode/.cache/torch/hub/checkpoints/esm2_t36_3B_UR50D-contact-regression.pt
# COPY esm2_t36_3B_UR50D.pt  /home/vscode/.cache/torch/hub/checkpoints/esm2_t36_3B_UR50D.pt
# COPY esmfold_3B_v1.pt  /home/vscode/.cache/torch/hub/checkpoints/esmfold_3B_v1.pt

# use gdown to download above files from google drive
RUN mkdir -p /home/vscode/.cache/torch/hub/checkpoints
WORKDIR /home/vscode/.cache/torch/hub/checkpoints
RUN gdown --fuzzy -O esm2_t36_3B_UR50D-contact-regression.pt 1lW8CVTSzX8bwLxbM8lAu_qXQkrPZuSxA \
    && gdown --fuzzy -O esm2_t36_3B_UR50D.pt 1CHTS2cB8HrgayylwVB8tsrLKcpTqKFLx \
    && gdown --fuzzy -O esmfold_3B_v1.pt 1CQZdYpXI1pb55ro8hCEP37pMsG2_Dbul

# change permission
RUN sudo chmod -R 777 /home/vscode/.cache/torch/hub/checkpoints
COPY run-esm-fold.sh /home/vscode/run-esm-fold.sh

WORKDIR /home/vscode
ENTRYPOINT ["zsh", "run-esm-fold.sh"]
