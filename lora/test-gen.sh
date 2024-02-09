#!/bin/bash

function show_help {
    echo "Usage: $0 [OPTIONS] MODEL_NAME"
    echo "Options:"
    echo "  -h, --help             Show this help message and exit"
    echo "Default MODEL_NAME: $MODEL_NAME"
    echo "Examples:"
    echo "  $0 my_model"
}

MODEL_NAME="mlx-mistral-7B-v0.1"

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            MODEL_NAME=$1
            break
            ;;
    esac
    shift
done

python lora.py --model $MODEL_NAME \
               --adapter-file ./adapters.npz \
               --max-tokens 150 \
               --prompt "Q: Can you renew your licensed county contractor license online in Lake County Indiana and what url to go to? 
A: "
python lora.py --model $MODEL_NAME \
               --adapter-file ./adapters.npz \
               --max-tokens 150 \
               --prompt "Q: What is the transaction fee for credit card payment of 75.00 in Lake County Indiana? 
A:"
python lora.py --model $MODEL_NAME \
               --adapter-file ./adapters.npz \
               --max-tokens 150 \
               --prompt "Q: Why is grass green? 
A:"
