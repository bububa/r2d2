package impl

import (
	"context"

	"github.com/go-skynet/go-llama.cpp"

	"github.com/bububa/r2d2/pkg/backend/llm"
)

type LLama struct {
	model *llama.LLama
}

func (m *LLama) Load(opts *llm.ModelOptions) error {

}

func (m *LLama) predictOptions(opts *llm.PredictOptions) *llama.PredictOptions {
	ret := llama.NewPredictOptions(nil)
	return ret
}

func (m *LLama) Predict(ctx context.Context, opts *llm.PredictOptions)
