#!/bin/bash

# Set up environment:
export MODEL_NAME="Mistral-7B-v0.1"
export MODEL_NAMESPACE="mistralai"
export MODEL_PATH="$MODEL_NAMESPACE/$MODEL_NAME"
export MODEL_FUSED="lora_fused_model"
export MODEL_SUFFIX="trained"
export MODEL_PREFIX="ngs"
export MODEL_Q="q4_0"
export TRAIN_ITERS=100
export TRAIN_DATA="./data2/"
export MAX_TOKENS=250
cd ~/Projects/mlx-examples-ngs/lora
rm -rf mlx-model
rm -rf $MODEL_FUSED
rm adapters.npz
source ~/anaconda3/bin/activate mlx

# Convert:
echo "Converting model $MODEL_PATH to MLX format..." ; \
python convert.py \
  --hf-path $MODEL_PATH \
  --mlx-path $MODEL_PATH \
  --q-bits 4 \
  --dtype float16

# Train:
echo "Training model $MODEL_PATH..."
python lora.py \
  --model $MODEL_PATH \
  --data $TRAIN_DATA \
  --train \
  --batch-size 1 \
  --lora-layers 4 \
  --iters $TRAIN_ITERS

# Test:
echo "Testing base model $MODEL_PATH..."
cd ../llms
python -m mlx_lm.generate \
  --model $MODEL_PATH \
  --max-tokens $MAX_TOKENS \
  --prompt "Tell me a Linux joke
A:"
cd ../lora

echo "Testing trained model $MODEL_PATH with adapters..."
python lora.py --model $MODEL_PATH \
  --adapter-file ./adapters.npz \
  --max-tokens $MAX_TOKENS \
  --prompt "Tell me a Linux joke
A:"

# Fuse -> lora_fused_model folder:              
echo "Fusing model $MODEL_PATH..."
python fuse.py \
  --model $MODEL_PATH \
  --save-path $MODEL_FUSED \
  --adapter-file ./adapters.npz

# Convert to GGUF format:
echo "Converting model $MODEL_PATH to GGUF format..."
export MODEL_TEMP=$MODEL_PREFIX-$MODEL_NAME-$MODEL_SUFFIX
cd ~/Projects/ollama/llm/llama.cpp
source ~/anaconda3/bin/activate llama.cpp
python convert.py \
  --vocab-type hfft \
  --outfile ~/Projects/mlx-examples-ngs/lora/$MODEL_FUSED/$MODEL_TEMP.gguf \
    ~/Projects/mlx-examples-ngs/lora/$MODEL_FUSED

# Quantize:
echo "Quantizing model $MODEL_NAME..."
export MODEL_FINAL=$MODEL_PREFIX-$MODEL_NAME-$MODEL_SUFFIX-$MODEL_Q
./quantize  \
    ~/Projects/mlx-examples-ngs/lora/$MODEL_FUSED/$MODEL_TEMP.gguf \
    ~/Projects/mlx-examples-ngs/lora/$MODEL_FUSED/$MODEL_FINAL.gguf \
    $MODEL_Q

# Import model into Ollama:
echo "Importing model $MODEL_FINAL into Ollama..."
cd ~/Projects/mlx-examples-ngs/lora/$MODEL_FUSED
echo "FROM ./$MODEL_FINAL.gguf
PARAMETER temperature 0.5 
PARAMETER stop \"[INST]\" 
PARAMETER stop \"[/INST]\" 
TEMPLATE \"\"\"
[INST] {{ .System }} {{ .Prompt }} [/INST]
\"\"\"" > modelfile
ollama create $MODEL_FINAL -f modelfile

# Restore original environment:
cd ~/Projects/mlx-examples-ngs/lora
source ~/anaconda3/bin/activate mlx
