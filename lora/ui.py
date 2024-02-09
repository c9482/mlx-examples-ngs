import gradio as gr
import mlx.core as mx
from mlx_lm import load, generate


def predict(message, history):

    model, tokenizer = load("./lora_fused_model")

    response = generate(model, tokenizer, prompt=message, verbose=True, max_tokens=512)

    return response

gr.ChatInterface(predict).launch()