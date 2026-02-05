# Field Extractor

**Created**: 2026-02-03
**Status**: Design Phase (Partial Implementation)

## Context and Design Philosophy

The Field Extractor is the heart of the file renaming feature. It takes raw text extracted from a PDF and uses a local LLM (via Ollama) to identify structured fields that will form the basis of the new filename.

**Guiding principles:**
- **Local processing** - All LLM work happens on-device via Ollama; no cloud APIs
- **Structured extraction** - Request specific fields in a predictable JSON format
- **Graceful degradation** - Invalid responses trigger retries; complete failure falls back to manual input
- **Transparency** - Verbose mode exposes the raw LLM response for debugging

## Model Selection

**Model**: `qwen2.5:14b`

This is a capable model that follows structured extraction instructions well. It requires explicit prompting with examples to return JSON in the expected format.

## Input

String containing raw text extracted from a PDF by the TextExtractor component.

## Output

A Hash with the following keys (all values are strings):

| Field | Required | Description | Example |
|-------|----------|-------------|---------|
| `date` | Yes | Statement/document date in `YYYY.MM.DD` format | `"2026.01.31"` |
| `credit_card` | No | Card type for credit card statements | `"Visa"`, `"Master Card"`, `"American Express"` |
| `vendor` | No | Bank, company, or provider name | `"Fidelity"`, `"City of Burlingame"` |
| `account_number` | No | Account identifier | `"12345"`, `"****9876"` |
| `invoice_number` | No | Invoice or reference number | `"INV-2026-001"` |

All fields are always present in the output. Missing values are represented as empty strings `""`.

## Prompt Design

The prompt uses explicit instructions to request structured JSON output. Key insight: LLMs often ignore date format instructions unless given explicit conversion examples.

```
You are a document field extractor. Extract fields from the document below and return JSON.

IMPORTANT DATE FORMAT RULE:
The date field MUST use format YYYY.MM.DD (4-digit year DOT 2-digit month DOT 2-digit day).
If document shows "02/17/25" or "February 17, 2025", convert to "2025.02.17".
If document shows "Closing Date 02/17/25", the year is 2025, so output "2025.02.17".

Fields to extract:
- date: Statement/closing date in YYYY.MM.DD format (REQUIRED)
- credit_card: Card type like "Visa", "American Express" (if applicable)
- vendor: Company name like "Fidelity", "E*Trade", "Delta"
- account_number: Account number if present
- invoice_number: Invoice number if present

Use empty string "" for fields not found. Return ONLY valid JSON, no other text.

Example output:
{"date": "2025.02.17", "credit_card": "American Express", "vendor": "Delta", "account_number": "6-02008", "invoice_number": ""}

Document:
---
{text}
---
```

**Key prompt elements:**
- Role assignment ("You are a document field extractor")
- Explicit date format conversion rule with examples
- Realistic example output with actual values
- Document text delimited by `---` markers

## Response Parsing

The LLM response may contain:
- Clean JSON
- JSON wrapped in markdown code fences (` ```json ... ``` `)
- JSON embedded in explanatory text

**Parsing steps:**
1. Strip leading/trailing whitespace
2. Remove markdown code fences if present
3. Extract the first JSON object using regex: `/\{[^{}]*\}/`
4. Parse as JSON

**Error handling:**
- If parsing fails, return an error hash: `{ error: "...", raw: "...", message: "..." }`

## Retry Logic

When the LLM returns invalid JSON:

1. Retry the same request up to 3 times total
2. Each retry uses the same prompt (no modifications)
3. If all retries fail, return `nil` to signal fallback to manual input

**Verbose mode**: Display each retry attempt number.

## Incomplete Field Handling

When JSON is valid but fields are missing or empty:

- Empty strings are acceptable for optional fields
- The NameSuggestor handles missing fields by omitting them from the filename
- If the `date` field is missing/empty, NameSuggestor uses `"UNKNOWN"` as the date portion
- This is handled downstream, not in FieldExtractor

## Error Conditions

| Condition | Response |
|-----------|----------|
| LLM returns valid JSON | Return parsed hash |
| LLM returns invalid JSON | Retry up to 3 times |
| All retries exhausted | Return `nil` (triggers manual input) |
| Network/connection error | Raise exception (handled by CLI layer) |

## Verbose Output

When verbose mode is enabled:
- Display the raw LLM response before parsing
- Display retry attempt numbers (e.g., "Retry 2/3...")

## Implementation

Uses Ollama's HTTP API directly via `Net::HTTP`. No external LLM gems required.

### Ollama API

Ollama exposes a REST API at `http://localhost:11434`. We use the `/api/generate` endpoint:

```
POST http://localhost:11434/api/generate
Content-Type: application/json

{
  "model": "qwen2.5:14b",
  "prompt": "...",
  "stream": false,
  "options": {
    "temperature": 0,
    "num_ctx": 16384
  }
}
```

**Response:**
```json
{
  "response": "...",
  "done": true
}
```

### Ruby Implementation

```ruby
require "net/http"
require "json"
require "uri"

# @spec REN-LLM-001 through REN-LLM-007
module Parkive
  class FieldExtractor
    OLLAMA_URL = "http://localhost:11434/api/generate"
    MODEL = "qwen2.5:14b"
    MAX_RETRIES = 3

    def self.extract(text, verbose: false)
      attempts = 0

      loop do
        attempts += 1
        response = send_prompt(text)
        puts "Raw Ollama response: #{response}" if verbose

        result = parse_response(response)
        return result unless result.key?(:error) || result.key?("error")

        puts "Retry attempt #{attempts} failed: invalid JSON" if verbose && attempts < MAX_RETRIES
        return nil if attempts >= MAX_RETRIES
      end
    end

    def self.send_prompt(text)
      uri = URI(OLLAMA_URL)
      http = Net::HTTP.new(uri.host, uri.port)
      http.read_timeout = 120  # LLM responses can be slow

      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request.body = {
        model: MODEL,
        prompt: build_prompt(text),
        stream: false,
        options: { temperature: 0, num_ctx: 16384 }
      }.to_json

      response = http.request(request)
      JSON.parse(response.body)["response"]
    end

    def self.parse_response(content)
      cleaned = content.strip.gsub(/```json\s*/, "").gsub(/```\s*/, "")

      json_str = if (match = cleaned.match(/\{[^{}]*\}/))
        match[0]
      else
        cleaned
      end

      JSON.parse(json_str)
    rescue JSON::ParserError => e
      { error: "Failed to parse response", raw: content, message: e.message }
    end

    def self.build_prompt(text)
      # Uses few-shot examples loaded from lib/parkive/examples/
      <<~PROMPT
        You are a document field extractor. Extract fields from the document below and return JSON.

        IMPORTANT DATE FORMAT RULE:
        The date field MUST use format YYYY.MM.DD (4-digit year DOT 2-digit month DOT 2-digit day).
        If document shows "02/17/25" or "February 17, 2025", convert to "2025.02.17".

        Fields to extract:
        - date: Statement/closing date in YYYY.MM.DD format (REQUIRED)
        - credit_card: Card type like "Visa", "American Express" (if applicable)
        - vendor: Company name like "Fidelity", "E*Trade", "Delta Skymiles"
        - account_number: Account number, whitespace removed, if present
        - invoice_number: Invoice number, whitespace removed, if present

        Use empty string "" for fields not found. Return ONLY valid JSON, no other text.

        Examples:
        [Few-shot examples from lib/parkive/examples/]

        Document to Extract from:
        ---
        #{text}
        ---
      PROMPT
    end
  end
end
```

## Data Model

### ExtractionResult (Optional Wrapper)

If additional metadata about the extraction is needed:

```ruby
ExtractionResult = Struct.new(
  :date, :credit_card, :vendor, :account_number,
  :invoice_number, :raw_response,
  keyword_init: true
) do
  def complete?
    date && date != "UNKNOWN" && !date.empty?
  end

  def to_hash
    {
      date: date,
      credit_card: credit_card,
      vendor: vendor,
      account_number: account_number,
      invoice_number: invoice_number
    }
  end
end
```

## Dependencies

| Dependency | Type | Purpose |
|------------|------|---------|
| `net/http` | Ruby stdlib | HTTP client for Ollama API |
| `json` | Ruby stdlib | JSON parsing |
| `ollama` | CLI tool | Local LLM server (must be installed and running) |
| `qwen2.5:14b` | Ollama model | Capable LLM for extraction (`ollama pull qwen2.5:14b`) |

No external gems required for LLM communication.

## Open Questions & Future Decisions

### Resolved

1. **Model choice** - Use `qwen2.5:14b` for good extraction accuracy
2. **Retry count** - 3 retries maximum
3. **Fallback behavior** - Return `nil` to trigger manual input flow
4. **Fields** - Five fields only: date, credit_card, vendor, account_number, invoice_number

### Deferred

1. **Date format normalization** - FieldExtractor normalizes dates via prompt instructions
2. **Multi-page PDFs** - Should we limit text length sent to LLM? Current implementation sends all text.

## References

- [High-Level Design](/docs/high-level-design.md)
- [File Renaming LLD](/docs/llds/file-renaming.md)
- [Name Suggestor LLD](/docs/llds/name-suggestor.md)
- [EARS Specifications](/docs/specs/file-renaming-specs.md) (REN-LLM-001 through REN-LLM-007)
