package llm

import "context"

type LLM interface {
	Busy() bool
	Lock()
	Unlock()
	Locking() bool
	Load(context.Context, string, *ModelOptions) error
	PredictStream(context.Context, string, *PredictOptions, chan string) error
	Embedding(context.Context, string, *PredictOptions) ([]float64, error)
	Tokenize(context.Context, string) ([]string, error)
	Encode(context.Context, string) ([]int, error)
	Decode(context.Context, []int) (string, error)
	Close()
	Ping(context.Context) error
}

type Request struct {
	Model    string `json:"model"`
	Prompt   string `json:"prompt"`
	System   string `json:"system"`
	Template string `json:"template"`
	Context  []int  `json:"context,omitempty"`

	Options map[string]interface{} `json:"options"`
}
