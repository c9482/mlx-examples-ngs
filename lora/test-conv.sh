  #!/bin/bash

function show_help {
    echo "Usage: $0 [OPTIONS] <model-name>"
    echo "Options:"
    echo "  --help                 Show this help message and exit"
    echo "Example: $0 mistral-7B-v0.1"
}

MODEL_NAME="mistral-7B-v0.1"
while [[ $# -gt 0 ]]; do
    case $1 in
        --help)
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

MODEL_NAME=$1

python convert.py \
    -q \
    --hf-path "$MODEL_NAME" \
    --q-bits "4" \
    --dtype "float16" \
    --mlx-path "mlx-$MODEL_NAME"

  