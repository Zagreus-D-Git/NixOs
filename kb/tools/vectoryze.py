# ~/nixos-config/kb/tools/vectorize.py
from chromadb import Client
from sentence_transformers import SentenceTransformer
import glob, pathlib

client = Client(path="/kb/vectors")
collection = client.get_or_create_collection("nixos_kb")
model = SentenceTransformer('all-MiniLM-L6-v2')  # 80MB, fast

for txt in glob.glob("/kb/processed/*.txt"):
    content = pathlib.Path(txt).read_text()
    chunks = [content[i:i+500] for i in range(0, len(content), 400)]  # Overlap
    embeddings = model.encode(chunks)

    collection.add(
        documents=chunks,
        embeddings=embeddings,
        ids=[f"{txt}_{i}" for i in range(len(chunks))],
        metadatas=[{"source": txt, "chunk": i} for i in range(len(chunks))]
    )
print(f"Vectorized {len(glob.glob('/kb/processed/*.txt'))} documents")
