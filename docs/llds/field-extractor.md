# Field Extractor

**Created**: 2026-02-03
**Updated**: 2026-02-08
**Status**: Implemented

## Context and Design Philosophy

The Field Extractor is the heart of the file renaming feature. It takes raw text extracted from a PDF and uses a local LLM (via Ollama) to identify structured fields that will form the basis of the new filename.

**Guiding principles:**
- **Local processing** - All LLM work happens on-device via Ollama; no cloud APIs
- **Schema-constrained output** - A JSON schema enforces the output format at the token level, eliminating most format errors
- **Simplified prompt** - The prompt focuses on *what* to extract; the schema handles *how* to format it
- **Few-shot examples** - Improve extraction accuracy for known document types
- **Graceful degradation** - Failed extraction falls back to manual input
- **Transparency** - Verbose mode exposes the raw LLM response for debugging

## Architecture

The Field Extractor uses **RubyLLM** with a **`DocumentFieldsSchema`** to extract structured fields. RubyLLM connects to Ollama's OpenAI-compatible API (`/v1/chat/completions`) and passes the schema as a `response_format` constraint. Ollama uses GBNF grammars to constrain token generation to match the JSON schema.

```
FieldExtractor.extract(text)
  → RubyLLM.chat(model, provider: :ollama)
    → .with_temperature(0)
    → .with_schema(DocumentFieldsSchema)
    → .ask(prompt + text)
      → Ollama /v1/chat/completions (with response_format: json_schema)
      → Returns parsed Hash automatically
```

### Why RubyLLM + Schema?

The previous approach used raw `Net::HTTP` to call Ollama's `/api/generate` endpoint with a hand-crafted prompt that included JSON format instructions. This required:
- Manual HTTP plumbing (~20 lines)
- Prompt engineering for format ("Return ONLY valid JSON, no other text")
- Response parsing (regex to strip markdown fences, extract JSON)
- Retry logic for format errors

The schema approach moves format enforcement from the prompt into the API layer. The result is simpler code (~90 lines vs ~150) and ~5x faster execution (the prompt is smaller without format instructions, and the OpenAI-compatible endpoint is faster than `/api/generate`).

## Model Selection

**Model**: `qwen2.5:14b`

Selected through experimentation:
- **qwen2.5:14b** - Best accuracy (7/7 fixtures), good speed (~22s avg). Strong general reasoning about financial documents.
- **llama3.1:8b** - Faster (~10s avg) but less accurate (6/7). Struggles with date extraction on some documents.
- **nuextract:latest** - Specialized extraction model but not suited for this use case. Cannot convert date formats and fails on longer documents.

## Input

String containing raw text extracted from a PDF by the TextExtractor component.

## Output

A Hash with the following keys (all values are strings):

| Field | Required | Description | Example |
|-------|----------|-------------|---------|
| `date` | Yes | Statement/document date in `YYYY.MM.DD` format | `"2026.01.31"` |
| `credit_card` | Yes | Card network (not product name) for credit card statements | `"Visa"`, `"American Express"` |
| `vendor` | Yes | Brand/product name on the statement | `"Delta SkyMiles"`, `"Fidelity"` |
| `account_number` | Yes | Primary account identifier (no sub-account suffixes) | `"12345"`, `"520-291109"` |
| `invoice_number` | Yes | Invoice or reference number | `"12950"` |

All fields are always present in the output. Missing values are represented as empty strings `""`.

## Schema Definition

The `DocumentFieldsSchema` defines the output structure using RubyLLM's Schema DSL:

```ruby
class DocumentFieldsSchema < RubyLLM::Schema
  description "Structured fields extracted from a financial document or invoice"

  string :date,
    description: "Statement or document date in YYYY.MM.DD format..."

  string :credit_card,
    description: "Credit card network or issuer: 'Visa', 'American Express'..."

  string :vendor,
    description: "The brand or product name on the statement..."

  string :account_number,
    description: "Primary account number, omit trailing sub-account suffixes..."

  string :invoice_number,
    description: "Invoice number with whitespace removed..."
end
```

The schema serves two purposes:
1. **Format enforcement** - Ollama constrains token generation to produce valid JSON matching this schema
2. **Field guidance** - The description on each field helps the model understand what to extract

### Key schema design decisions

- **credit_card** is the payment *network* (American Express, Visa), not the card *product name* (Delta SkyMiles Reserve Card). This distinction required explicit description language.
- **account_number** omits trailing sub-account suffixes like "-201". This was taught via few-shot examples.
- All fields are required (always present), with empty string for missing values.

## Prompt Design

With the schema handling format enforcement, the prompt focuses purely on extraction instructions:

```
Extract the key fields from this financial document.

Date format: Convert all dates to YYYY.MM.DD format.
- "02/17/25" becomes "2025.02.17"
- "February 17, 2025" becomes "2025.02.17"
- Use the statement closing date, not today's date.

Use empty string "" for any field not found in the document.

For credit card statements: credit_card is the payment NETWORK (American Express, Visa, Mastercard),
not the card product name. The card product name (e.g. Delta SkyMiles) goes in vendor.

Examples:
[Few-shot examples from lib/parkive/examples/]

Document to extract from:
---
{text}
---
```

**Key prompt elements:**
- Date conversion rules with examples (LLMs ignore format instructions without examples)
- Explicit credit card network vs product name distinction
- Few-shot examples showing expected outputs for real documents
- No JSON format instructions (schema handles this)

## Few-Shot Examples

Examples are loaded from `lib/parkive/examples/` and included in the prompt. Each shows a truncated document (first 200 chars) and the expected output.

| Example | Document Type | Key Fields |
|---------|---------------|------------|
| amex | Credit card statement | credit_card: "American Express", vendor: "Delta SkyMiles" |
| apple | Credit card statement | credit_card: "Apple Card", vendor: "Goldman" |
| etrade | Brokerage statement | vendor: "E*Trade", account_number: "520-291109" |
| etrade_2 | Brokerage statement | vendor: "E*Trade", account_number: "520-852519" |
| sal | Invoice | vendor: "Sals Landscaping", invoice_number: "12950" |

Examples are critical for accuracy. Without them, the model misidentifies fields (e.g., swapping credit_card and vendor) and includes unwanted suffixes in account numbers.

## Retry Logic

When the LLM returns a response that isn't a valid Hash:

1. Attempt to parse it as a JSON string (fallback for edge cases)
2. If that fails, retry the same request up to 3 times total
3. If all retries fail, return `nil` to signal fallback to manual input

With schema enforcement, format errors are rare. Retries primarily guard against network failures or edge-case model behavior.

## Error Conditions

| Condition | Response |
|-----------|----------|
| LLM returns valid Hash | Return normalized hash |
| LLM returns parseable JSON string | Parse and return normalized hash |
| LLM returns unparseable response | Retry up to 3 times |
| All retries exhausted | Return `nil` (triggers manual input) |
| Network/connection error | Retry up to 3 times, then return `nil` |

## Verbose Output

When verbose mode is enabled:
- Display the raw LLM response before normalization
- Display retry attempt numbers and error messages

## RubyLLM Configuration

```ruby
RubyLLM.configure do |config|
  config.ollama_api_base = "http://localhost:11434/v1"
end
```

Configuration is done once (lazy initialization on first `extract` call).

## Dependencies

| Dependency | Type | Purpose |
|------------|------|---------|
| `ruby_llm` | Gem | LLM client with schema support |
| `ruby_llm-schema` | Gem | Schema DSL for defining structured output |
| `ollama` | CLI tool | Local LLM server (must be installed and running) |
| `qwen2.5:14b` | Ollama model | LLM for extraction (`ollama pull qwen2.5:14b`) |

## Performance

Benchmarked against 7 document fixtures:

| Metric | Value |
|--------|-------|
| Average extraction time | ~22 seconds |
| Accuracy (exact match) | 7/7 fixtures |
| Speedup vs previous approach | ~5x |

## References

- [High-Level Design](/docs/high-level-design.md)
- [File Renaming LLD](/docs/llds/file-renaming.md)
- [Name Suggestor LLD](/docs/llds/name-suggestor.md)
- [EARS Specifications](/docs/specs/file-renaming-specs.md) (REN-LLM-001 through REN-LLM-007)
