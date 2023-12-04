# Build Image for running ESMFold 

- Date: Sunday, Dec 3, 2023
- Author: ChuNan Liu 
- Email: chunan.liu@ucl.ac.uk

## Build Image
```shell
$ docker build -t $USER/esmfold:base .
```
- `-t $USER/esmfold:base`: tag the image with the name `$USER/esmfold` and the tag `base`.
  - You can ommit `$USER` if you want

## Details 

This image is based on the [nvidia/cuda:11.3.1-devel-ubuntu20.04](https://hub.docker.com/layers/nvidia/cuda/11.3.1-devel-ubuntu20.04/images/sha256-83c286510046d7bd291c20ec19f4a8ed5995cc8fdfd8f18b58c5330b0cf2b20f?context=explore) image.

You might already have noticed there are some packages installed in the Dockerfile are downloaded using `gdown` which is a python package that downloads files from Google Drive. These files are:
- **openfold.tar.gz**: the official release of OpenFold 
  - My modifications: I commented out the flash-attn package from the default environemnt.yml file because it's not compatible with the latest version of ESM. 
- **esm-main.tar.gz**: the official release of ESM.
- **esm2_t36_3B_UR50D.pt** : the pretrained ESM2 model.
- **esm2_t36_3B_UR50D-contact-regression.pt**: the pretrained ESM2 model with contact regression.
- **esmfold_3B_v1.pt**: the pretrained ESMFold model.
Even though the three `.pt` chedckpoint files are downloaded upon first run of the container, it's better to have them in the image to avoid downloading them every time the container is run. 

The Google Drive folder for the above files are [esmfold](https://drive.google.com/drive/folders/1voN-GketdgO_tGL84DoV0es_87LphuGW?usp=sharing). 

## Run Image
The default entrypoint for the image, as specified in the Dockerfile, is 
```Dockerfile 
ENTRYPOINT ["zsh", "run-esm-fold.sh"]
```

content of `run-esm-fold.sh`:
```shell
#!/bin/zsh 

# init conda
source $HOME/.zshrc 

# activate py39-esmfold
conda activate py39-esmfold

# run esm-fold
esm-fold $@
```

### Help information 
Run the following command to see the help information of `esm-fold`:
```shell
$ docker run --rm esmfold:base --help 
```

stdout: 
```shell
usage: esm-fold [-h] -i FASTA -o PDB [-m MODEL_DIR]
                [--num-recycles NUM_RECYCLES]
                [--max-tokens-per-batch MAX_TOKENS_PER_BATCH]
                [--chunk-size CHUNK_SIZE] [--cpu-only] [--cpu-offload]

optional arguments:
  -h, --help            show this help message and exit
  -i FASTA, --fasta FASTA
                        Path to input FASTA file
  -o PDB, --pdb PDB     Path to output PDB directory
  -m MODEL_DIR, --model-dir MODEL_DIR
                        Parent path to Pretrained ESM data directory.
  --num-recycles NUM_RECYCLES
                        Number of recycles to run. Defaults to number used in
                        training (4).
  --max-tokens-per-batch MAX_TOKENS_PER_BATCH
                        Maximum number of tokens per gpu forward-pass. This
                        will group shorter sequences together for batched
                        prediction. Lowering this can help with out of memory
                        issues, if these occur on short sequences.
  --chunk-size CHUNK_SIZE
                        Chunks axial attention computation to reduce memory
                        usage from O(L^2) to O(L). Equivalent to running a for
                        loop over chunks of of each dimension. Lower values
                        will result in lower memory usage at the cost of
                        speed. Recommended values: 128, 64, 32. Default: None.
  --cpu-only            CPU only
  --cpu-offload         Enable CPU offloading
```

### Run ESMFold with fasta file as input 
```shell
$ docker run --rm --gpus all \
    -v ./example/input:/input \
    -v ./example/output:/output \
    esmfold:base \
    -i /input/1a2y-HLC.fasta -o /output > ./example/logs/pred.log 2>./example/logs/pred.err \
```
- `-i /input/1a2y-HLC.fasta`: input fasta file
- `-o /output`: path to output predicted structure 
- `> ./example/logs/pred.log 2>./example/logs/pred.err`: redirect stdout and stderr to log files
other flags 
- `--num-recycles NUM_RECYCLES`: Number of recycles to run. Defaults to number used in training (default is 4).
- `--max-tokens-per-batch MAX_TOKENS_PER_BATCH`: Maximum number of tokens per gpu forward-pass. This will group shorter sequences together for batched prediction. Lowering this can help with out of memory issues, if these occur on short sequences.
- `--chunk-size CHUNK_SIZE`: Chunks axial attention computation to reduce memory usage from O(L^2) to O(L). Equivalent to running a for loop over chunks of of each dimension. Lower values will result in lower memory usage at the cost of speed. Recommended values: 128, 64, 32. Default: None.
- `--cpu-only`: CPU only
- `--cpu-offload`: Enable CPU offloading

### Overwrite entrypoint 
If you want to overwrite the entrypoint, you can do so by adding the following to the end of the `docker run` command:
```shell
$ docker run --rm --gpus all --entrypoint "/bin/zsh" esmfold:base -c "echo 'hello world'"
```

### Test GPU 
```shell
$ docker run --rm --gpus all --entrypoint "nvidia-smi" esmfold:base 
```