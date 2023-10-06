package backend

import "context"

type Options struct {
	model   ModelType
	threads uint32
	context context.Context
}

type Option func(*Options)

func WithModel(modelType ModelType) Option {
	return func(o *Options) {
		o.model = modelType
	}
}

func WithContext(ctx context.Context) Option {
	return func(o *Options) {
		o.context = ctx
	}
}

func WithThreads(threads uint32) Option {
	return func(o *Options) {
		o.threads = threads
	}
}

func NewOptions(opts ...Option) *Options {
	o := new(Options)
	for _, opt := range opts {
		opt(o)
	}
	return o
}
