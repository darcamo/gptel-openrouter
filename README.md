# gptel-openrouter

`gptel-openrouter.el` is an Emacs package designed to retrieve and process model information from OpenRouter's API. It allows Emacs users to fetch detailed annotations about available models, including descriptions, context lengths, prices, and more. This information is formatted for compatibility with `gptel`, an Emacs package facilitating communication with AI models.

## Features

- Download and cache model information from OpenRouter's API.
- Generate the plist you need to pass to `gptel-make-openai` to register an "OpenRouter" backend.

## Installation

Clone the repository or download `gptel-openrouter.el` and place it in your Emacs `load-path`. Then, require the package in your Emacs configuration:

```emacs-lisp
(add-to-list 'load-path "/path/to/gptel-openrouter")
(require 'gptel-openrouter)
```

## Usage

1. Run `gptel-openrouter-download-model-data` once to fetch the OpenRouter model metadata. The JSON cache is saved to the directory given by `gptel-openrouter-json-cache-location`.

2. Call `gptel-openrouter-get-annotated-models` when registering OpenRouter models in gptel. For example:

```emacs-lisp
(gptel-make-openai "OpenRouter"
  :host "openrouter.ai"
  :endpoint "/api/v1/chat/completions"
  :stream t
  :key "your-api-key"
  :models (gptel-openrouter-get-annotated-models
           '(openai/gpt-4o
             openai/gpt-5
             openai/gpt-5-codex
             anthropic/claude-sonnet-4
             qwen/qwen3-coder
             moonshotai/kimi-k2
             google/gemini-2.5-pro
             google/gemini-2.5-flash)))
```

**Note**: After calling `gptel-openrouter-download-model-data` to fetch the model data, you will need to register the models again by calling `gptel-make-openai` to see any changes.

## Contributions

Contributions and feedback are welcome! Feel free to open issues or pull requests on the [GitHub repository](https://github.com/yourusername/gptel-openrouter).

## License

`gptel-openrouter.el` is licensed under the GNU General Public License v3.0. See the LICENSE file for more details.
