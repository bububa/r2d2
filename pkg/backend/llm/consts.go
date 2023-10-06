package llm

import "github.com/bububa/r2d2/pkg/backend"

const (
	LlamaModel          backend.ModelType = "llama"
	BloomzBackend                         = "bloomz"
	StarcoderBackend                      = "starcoder"
	GPTJBackend                           = "gptj"
	DollyBackend                          = "dolly"
	MPTBackend                            = "mpt"
	GPTNeoXBackend                        = "gptneox"
	ReplitBackend                         = "replit"
	Gpt2Backend                           = "gpt2"
	Gpt4AllLlamaBackend                   = "gpt4all-llama"
	Gpt4AllMptBackend                     = "gpt4all-mpt"
	Gpt4AllJBackend                       = "gpt4all-j"
	Gpt4All                               = "gpt4all"
	FalconBackend                         = "falcon"
	FalconGGMLBackend                     = "falcon-ggml"

	BertEmbeddingsBackend  = "bert-embeddings"
	RwkvBackend            = "rwkv"
	WhisperBackend         = "whisper"
	StableDiffusionBackend = "stablediffusion"
	PiperBackend           = "piper"
	LCHuggingFaceBackend   = "langchain-huggingface"
)
