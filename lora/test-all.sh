#!/bin/bash

# Set up environment:
set -x
exec > >(tee -a test-all.log) 2>&1
#export MODEL_NAME="mistral-7B-instruct-v0.2"
#export MODEL_HF_NAMESPACE="mistralai"
#export MODEL_NAME="mistral-7B-v0.1-hf"
#export MODEL_HF_NAMESPACE="kittn"
export MODEL_NAME="Llama-2-7b-chat-hf"
export MODEL_HF_NAMESPACE="meta-llama"
export MODEL_PATH="$MODEL_HF_NAMESPACE/$MODEL_NAME"
export MODEL_FUSED="lora_fused_model"
export MODEL_SUFFIX="klingon"
export MODEL_PREFIX="ngs"
export MODEL_NAMESPACE="silmarillion"
export MODEL_Q="q4_0"
export TRAIN_ITERS=500
export TRAIN_DATA="./data-llama2/"
export MAX_TOKENS=50
cd ~/Projects/mlx-examples-ngs/lora
rm -rf mlx-model
rm -rf $MODEL_FUSED
rm adapters.npz
rm test-all.log
source ~/anaconda3/bin/activate mlx

# Convert:
echo "======================================================================="
echo "Converting model $MODEL_PATH to MLX format..." ; 
echo "======================================================================="
python convert.py \
  --hf-path $MODEL_PATH \
  --mlx-path $MODEL_PATH

# Train:
echo "======================================================================="
echo "Training model $MODEL_PATH..."
echo "======================================================================="
python lora.py \
  --model $MODEL_PATH \
  --data $TRAIN_DATA \
  --train \
  --batch-size 1 \
  --lora-layers 4 \
  --iters $TRAIN_ITERS

# Evaluate:
echo "======================================================================="
echo "Evaluating model $MODEL_PATH..."
echo "======================================================================="
python lora.py \
  --model $MODEL_PATH \
  --data $TRAIN_DATA \
  --test \

# Test:
echo "======================================================================="
echo "Testing base model $MODEL_PATH..."
echo "======================================================================="
cd ../llms
python -m mlx_lm.generate \
  --model $MODEL_PATH \
  --max-tokens $MAX_TOKENS \
  --prompt "Say HELLO WORLD in Klingon
A:"
cd ../lora

echo "======================================================================="
echo "Testing trained model $MODEL_PATH with adapters..."
echo "======================================================================="
python lora.py --model $MODEL_PATH \
  --adapter-file ./adapters.npz \
  --max-tokens $MAX_TOKENS \
  --prompt "Say HELLO WORLD in Klingon
A:"

# Fuse -> lora_fused_model folder:              
echo "======================================================================="
echo "Fusing model $MODEL_PATH..."
echo "======================================================================="
export MODEL_TEMP=$MODEL_PREFIX-$MODEL_NAME-$MODEL_SUFFIX
python fuse.py \
  --model $MODEL_PATH \
  --save-path $MODEL_FUSED \
  --adapter-file ./adapters.npz
  #--hf-path $MODEL_PATH \
  #--upload-name silmarillion/$MODEL_TEMP

# Convert to GGUF format:
echo "======================================================================="
echo "Converting model $MODEL_PATH to GGUF format..."
echo "======================================================================="
cd ~/Projects/ollama/llm/llama.cpp
source ~/anaconda3/bin/activate llama.cpp
python convert.py \
  --vocab-type hfft \
  --outfile ~/Projects/mlx-examples-ngs/lora/$MODEL_FUSED/$MODEL_TEMP.gguf \
    ~/Projects/mlx-examples-ngs/lora/$MODEL_FUSED

# Quantize:
echo "======================================================================="
echo "Quantizing model $MODEL_NAME to $MODEL_Q..."
echo "======================================================================="
export MODEL_FINAL=$MODEL_PREFIX-$MODEL_NAME-$MODEL_SUFFIX-$MODEL_Q
./quantize  \
    ~/Projects/mlx-examples-ngs/lora/$MODEL_FUSED/$MODEL_TEMP.gguf \
    ~/Projects/mlx-examples-ngs/lora/$MODEL_FUSED/$MODEL_FINAL.gguf \
    $MODEL_Q

# Import model into Ollama:
echo "======================================================================="
echo "Importing model $MODEL_FINAL into Ollama..."
echo "======================================================================="
cd ~/Projects/mlx-examples-ngs/lora/$MODEL_FUSED
echo "FROM ./$MODEL_FINAL.gguf
PARAMETER temperature 0.5 
PARAMETER stop \"[INST]\" 
PARAMETER stop \"[/INST]\" 
TEMPLATE \"\"\"
[INST] {{ .System }} {{ .Prompt }} [/INST]
\"\"\"" > modelfile
ollama create $MODEL_NAMESPACE/$MODEL_FINAL -f modelfile

# Copy to LM Studio
echo "======================================================================="
echo "Importing model $MODEL_FINAL into LM Studio..."
echo "======================================================================="
mkdir ~/.cache/lm-studio/models/$MODEL_NAMESPACE
mkdir ~/.cache/lm-studio/models/$MODEL_NAMESPACE/$MODEL_FINAL
cp -r $MODEL_FINAL.gguf ~/.cache/lm-studio/models/$MODEL_NAMESPACE/$MODEL_FINAL/$MODEL_FINAL.gguf

# Restore original environment:
cd ~/Projects/mlx-examples-ngs/lora
source ~/anaconda3/bin/activate mlx
set +x
