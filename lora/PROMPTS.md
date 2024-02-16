
## Inspecting a model using Ollama ##

```
ollama show phi --modelfile
```

## Example prompts ##

capybarahermes-2.5-mistral-75.Q4_K_M.gguf uses CHATML prompt standard:
```
echo "FROM ./$MODEL_FINAL.gguf
PARAMETER temperature 0.8
PARAMETER top_k 500
PARAMETER top_p 0.9
PARAMETER stop \"<|im_start|>\"
PARAMETER stop \"<|im_end|>\"
TEMPLATE \"\"\"
<|im_start|>system
{system_message}<|im_end|>
<|im_start|>user
{prompt}<|im_end|>
<|im_start|>assistant
\"\"\"" > modelfile
```

mistral:
```
echo "FROM ./$MODEL_FINAL.gguf
PARAMETER temperature 0.5 
PARAMETER stop \"[INST]\" 
PARAMETER stop \"[/INST]\" 
TEMPLATE \"\"\"
[INST] {{ .System }} {{ .Prompt }} [/INST]
\"\"\""
```