#!/bin/bash

function show_help {
    echo "Usage: $0 [OPTIONS] <model> <data>"
    echo "Options:"
    echo "  --help                     Show this help message and exit"
    echo "  --model <value>            Specify the model (default: mlx-mistral-7B-v0.1)"
    echo "  --data <value>             Specify the data directory (default: ./data2/)"
    echo "Example: $0 --model custom-model --data ./custom-data/"
}

MODEL="mlx-mistral-7B-v0.1"
DATA="./data2/"

while [[ $# -gt 0 ]]; do
    case $1 in
        --help)
            show_help
            exit 0
            ;;
        --model)
            MODEL=$2
            shift
            ;;
        --data)
            DATA=$2
            shift
            ;;
        *)
            break
            ;;
    esac
    shift
done

python lora.py \
    --model "$MODEL" \
    --train \
    --data "$DATA" \
    --lora-layers 4 \
    --batch-size 1 \
    --iters 600

