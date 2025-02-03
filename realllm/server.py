from llama_cpp import Llama
import os

model_path = "/app/models/deepseek-r1-7b-Q4_K_M.gguf"

llm = Llava(
    model_path=model_path,
    n_ctx=4096,        # Context window
    n_threads=os.cpu_count(),  # Use all cores
    n_gpu_layers=0     # Force CPU-only
)


def handle_query(prompt):
    return llm.create_chat_completion(
        messages=[{"role": "user", "content": prompt}],
        max_tokens=512,
        temperature=0.7
    )
