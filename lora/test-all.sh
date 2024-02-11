#!/bin/bash

# Set up environment:
export MODEL_NAME="Mistral-7B-v0.1"
export MODEL_PATH="mistralai/$MODEL_NAME"
cd ~/Projects/mlx-examples-ngs/lora
rm -rf mlx-model
rm -rf lora_fused_model
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
  --data ./data2/ \
  --train \
  --batch-size 1 \
  --lora-layers 4 \
  --iters 600

# Test:
echo "Testing model $MODEL_PATH..."
python lora.py --model $MODEL_PATH \
  --max-tokens 150 \
  --prompt "Can I renew my contractor license online at Lake County Indiana? 
A:"

echo "Testing model $MODEL_PATH with adapters..."
python lora.py --model $MODEL_PATH \
  --adapter-file ./adapters.npz \
  --max-tokens 150 \
  --prompt "Can I renew my contractor license online at Lake County Indiana? 
A:"

# Fuse -> lora_fused_model folder:              
echo "Fusing model $MODEL_PATH..."
python fuse.py \
  --model $MODEL_PATH \
  --save-path lora_fused_model \
  --adapter-file ./adapters.npz

# Convert to GGUF format:
echo "Converting model $MODEL_PATH to GGUF format..."
cd ~/Projects/ollama/llm/llama.cpp
source ~/anaconda3/bin/activate llama.cpp
python convert.py \
  --vocab-type hfft \
  --outfile ~/Projects/mlx-examples-ngs/lora/lora_fused_model/$MODEL_NAME-trained.gguf \
    ~/Projects/mlx-examples-ngs/lora/lora_fused_model

# Quantize:
echo "Quantizing model $MODEL_NAME..."
export MODEL_FINAL=$MODEL_NAME-trained-q4_0
./quantize  \
    ~/Projects/mlx-examples-ngs/lora/lora_fused_model/$MODEL_NAME-trained.gguf \
    ~/Projects/mlx-examples-ngs/lora/lora_fused_model/$MODEL_FINAL.gguf \
    Q4_0

# Import model into Ollama:
echo "Importing model $MODEL_NAME into Ollama..."
cd ~/Projects/mlx-examples-ngs/lora/lora_fused_model
echo "FROM ./$MODEL_FINAL.gguf
PARAMETER temperature 0.8
PARAMETER top_k 500
PARAMETER top_p 0.9
SYSTEM \"\"\"
Embrace your role as a helpful employee of the Lake County Indiana Building Department.
\"\"\"" > modelfile
ollama create $MODEL_FINAL -f modelfile

# Restore original environment:
cd ~/Projects/mlx-examples-ngs/lora
source ~/anaconda3/bin/activate mlx
