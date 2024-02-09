#!/bin/bash

function show_help {
    echo "Usage: bash test-upload.sh [OPTIONS]"
    echo "Options:"
    echo "  -h, --help             Show this help message and exit"
    echo "  -u, --upload-name      Specify the upload name"
    echo "  -m, --hf-model-name    Specify the Hugging Face model name"
    echo "Example: bash test-upload.sh -u Mistral-7B-Trained-v0.1 -m mistralai/Mistral-7B-Instruct-v0.1"
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -u|--upload-name)
            UPLOAD_NAME=$2
            shift
            ;;
        -m|--hf-model-name)
            HF_MODEL_NAME=$2
            shift
            ;;
        *)
            echo "Invalid option: $1"
            show_help
            exit 1
            ;;
    esac
    shift
done

if [ -z "$UPLOAD_NAME" ] || [ -z "$HF_MODEL_NAME" ]; then
    echo "Both upload name and Hugging Face model name are required."
    show_help
    exit 1
fi

# huggingface-cli login
python fuse.py \
    --model "$UPLOAD_NAME" \
    --upload-name "$UPLOAD_NAME" \
    --hf-path "$HF_MODEL_NAME" \
    --save-path "fused-$UPLOAD_NAME"