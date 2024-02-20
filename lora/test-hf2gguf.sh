#!/bin/bash

# Set up environment:
#set -x
#exec > >(tee -a test-hf2gguf.log) 2>&1
#export MODEL_NAME="mistral-7B-instruct-v0.2"
#export MODEL_HF_NAMESPACE="mistralai"
#export MODEL_NAME="mistral-7B-v0.1-hf"
#export MODEL_HF_NAMESPACE="kittn"
export MODEL_NAME="llama-2-7b-chat-hf"
export MODEL_HF_NAMESPACE="meta-llama"
export MODEL_PATH="$MODEL_HF_NAMESPACE/$MODEL_NAME"
export MODEL_SUFFIX=""
export MODEL_PREFIX=""
export MODEL_NAMESPACE="silmarillion"
export MAX_TOKENS=50
export MODEL_Q="q4_0"

cd ~/Projects/mlx-examples-ngs/lora
rm test-hf2gguf.log
source ~/anaconda3/bin/activate mlx

# Convert:
echo "======================================================================="
echo "Converting model $MODEL_PATH to MLX format..." ; 
echo "======================================================================="
python convert.py \
  --hf-path $MODEL_PATH \
  --mlx-path $MODEL_PATH


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

# Convert to GGUF format:
echo "======================================================================="
echo "Converting model $MODEL_PATH to GGUF format..."
echo "======================================================================="
export MODEL_TEMP=${MODEL_PREFIX}${MODEL_NAME}${MODEL_SUFFIX}
cd ~/Projects/ollama/llm/llama.cpp
source ~/anaconda3/bin/activate llama.cpp
python convert.py \
  --vocab-type hfft \
  --outfile ~/Projects/mlx-examples-ngs/lora/$MODEL_PATH/$MODEL_TEMP.gguf \
    ~/Projects/mlx-examples-ngs/lora/$MODEL_PATH

# Quantize:
echo "======================================================================="
echo "Quantizing model $MODEL_NAME to $MODEL_Q..."
echo "======================================================================="
export MODEL_FINAL=$MODEL_TEMP-$MODEL_Q
./quantize  \
    ~/Projects/mlx-examples-ngs/lora/$MODEL_PATH/$MODEL_TEMP.gguf \
    ~/Projects/mlx-examples-ngs/lora/$MODEL_PATH/$MODEL_FINAL.gguf \
    $MODEL_Q

# Import model into Ollama:
echo "======================================================================="
echo "Importing model $MODEL_FINAL into Ollama..."
echo "======================================================================="
cd ~/Projects/mlx-examples-ngs/lora/$MODEL_PATH
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
