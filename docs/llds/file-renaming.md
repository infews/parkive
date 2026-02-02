# File Renaming

**Created**: 2026-02-01
**Status**: Design Phase

## Context and Design Philosophy

The File Renaming feature transforms arbitrarily-named PDFs into consistently-named files following the `YYYY.MM.DD.Vendor.Info.pdf` pattern. This enables the File Storing feature to archive them correctly.

**Guiding principles:**
- **User in the loop** - Never rename without confirmation; always allow edits
- **Fail gracefully** - Missing dependencies, unreadable PDFs, or LLM failures should not crash the tool
- **Transparency** - With --verbose, show what's happening under the hood

## Processing Flow

The rename command processes a directory through five sequential stages. First, the Directory Scanner identifies PDFs that don't conform to the naming pattern—if none exist, we exit early with a message. Second, for each non-conforming PDF, the Text Extractor uses Poppler to pull text content. Third, the LLM Extractor sends that text to Ollama, which returns structured JSON with date, vendor, and info fields. Fourth, the User Confirmation stage presents the suggested filename and waits for the user to confirm, edit, or skip. Finally, if confirmed or edited, the File Renamer performs the actual rename operation.

Each stage can fail independently: Poppler might not be installed, a PDF might lack text, Ollama might return garbage. The error handling strategy ensures each failure mode has a defined recovery path that keeps the user informed and in control.

## Components

### Directory Scanner

**Responsibility:** Find all PDFs in the input directory that need renaming.

**Input:** Directory path from command line

**Output:** Array of file paths

**Logic:**
1. Glob for `*.pdf` and `*.PDF` in the directory (case-insensitive)
2. Filter out files already matching the pattern `YYYY.MM.DD.*`
3. Return the list (may be empty)

**Pattern matching:** Use the same date extraction logic from `ArchivablePathname` to determine if a file already conforms. A file conforms if `Date.strptime(basename, "%Y.%m.%d")` succeeds.

### PDF Text Extractor

**Responsibility:** Extract text content from a PDF file.

**Input:** File path to a single PDF

**Output:** String containing extracted text, or nil if no text found

**Implementation:**
- Use the `poppler` gem (Ruby bindings for Poppler)
- The `pdftotext` command-line tool must also be installed

**Dependency check:** Before processing any files, verify Poppler is available:
```ruby
system("which pdftotext > /dev/null 2>&1")
```
If not found, exit with a message telling the user to install it.

### LLM Field Extractor

**Responsibility:** Extract structured fields from PDF text using Ollama.

**Input:** String containing PDF text

**Output:** Hash with keys:
- `:date` (required) - Statement date in YYYY.MM.DD format
- `:credit_card` (optional) - Card type (e.g., "Visa", "Master Card")
- `:vendor` (optional) - Bank or provider name
- `:account_number` (optional) - Account identifier
- `:invoice_number` (optional) - Invoice identifier
- `:type` (optional) - Document type (e.g., "Bill", "Statement")
- `:other` (optional) - Any other relevant information

**Implementation:**
- Use the `ruby-llm` gem to communicate with Ollama
- Model: `llama3.1:8b`
- Request JSON output format

**Prompt structure:**
```
Extract the following from this document text. Return ALL fields, using empty string "" for any field not found.

Required:
- date: The statement/document date in YYYY.MM.DD format

Optional:
- credit_card: Card type if this is a credit card statement (e.g., "Visa", "Master Card", "American Express")
- vendor: The bank or provider name (e.g., "Fidelity", "Health Equity", "City of Burlingame")
- account_number: Account number if present
- invoice_number: Invoice number if present
- type: Document type (e.g., "Bill", "Statement", "Escrow Statement")
- other: Any other relevant identifying information

Return ONLY valid JSON in this exact format:
{"date": "YYYY.MM.DD", "credit_card": "", "vendor": "", "account_number": "", "invoice_number": "", "type": "", "other": ""}

Document text:
---
{text}
---
```

**Dependency checks:** Before processing any files:
1. Check if Ollama is installed: `system("which ollama > /dev/null 2>&1")`
2. Check if Ollama is running: `system("ollama list > /dev/null 2>&1")`

If not installed, tell user to install and run `ollama pull llama3.1:8b`.
If not running, tell user to start Ollama.

**Response parsing:**
1. Attempt to parse response as JSON
2. If parsing fails, retry up to 3 times
3. If all retries fail, return nil (triggers manual input flow)

**Incomplete fields:** If JSON is valid but a field is missing or empty, use `"UNKNOWN"` as placeholder.

### Name Suggestor

See [Name Suggestor LLD](/docs/llds/name-suggestor.md) for detailed design.

**Responsibility:** Build a suggested filename from extracted fields.

**Input:** Hash of extracted fields from LLM

**Output:** Filename conforming to `YYYY.MM.DD.{rest}.pdf` pattern

### User Confirmation

**Responsibility:** Present suggested filename and get user decision.

**Input:**
- Original filename
- Suggested new filename (constructed from extracted fields)

**Output:** One of:
- `:confirm` with the suggested filename
- `:edit` with user-modified filename
- `:skip`

**Implementation:** Use the `Prompts` gem (same as other commands).

**Display format:**
```
Original:  quarterly-statement-jan.pdf
Suggested: 2026.01.31.WellsFargo.1234.pdf

[C]onfirm  [E]dit  [S]kip
```

**Edit flow:** If user chooses Edit, present the suggested filename in an editable prompt. Validate that the result conforms to the archivable pattern (starts with `YYYY.MM.DD`). If it doesn't, show an error and prompt the user to edit again.

**Manual input flow:** When LLM extraction completely fails (after retries), show:
```
Original:  quarterly-statement-jan.pdf
Could not extract fields automatically.

Enter new filename (or press Enter to skip):
```

The same validation applies: if the entered filename doesn't conform to the archivable pattern, show an error and prompt again.

### File Renamer

**Responsibility:** Rename a file in place.

**Input:** Original path, new filename

**Output:** Success/failure

**Implementation:**
```ruby
File.rename(original_path, File.join(File.dirname(original_path), new_filename))
```

**Edge cases:**
- If target filename already exists, the Prompts gem should ask for confirmation before overwriting
- Preserve the directory—only the filename changes

## Data Models

### ExtractionResult

Represents the output of LLM extraction:

```ruby
ExtractionResult = Struct.new(
  :date, :credit_card, :vendor, :account_number,
  :invoice_number, :type, :other, :raw_response,
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
      invoice_number: invoice_number,
      type: type,
      other: other
    }
  end
end
```

### RenameDecision

Represents user's choice at confirmation:

```ruby
RenameDecision = Struct.new(:action, :filename, keyword_init: true)
# action is one of: :confirm, :edit, :skip
# filename is present for :confirm and :edit, nil for :skip
```

## Error Handling Strategy

| Stage | Error | Recovery |
|-------|-------|----------|
| CLI | Directory doesn't exist | Raise `NoSourceDirectoryError` |
| CLI | Poppler not installed | Raise `PopplerNotInstalledError` with install instructions |
| CLI | Ollama not installed | Raise `OllamaNotInstalledError` with install instructions |
| CLI | Ollama not running | Raise `OllamaNotRunningError` with "start Ollama" message |
| Commands | No PDFs in directory | Exit with "no PDFs found" message |
| Commands | All PDFs already conform | Exit with "all files already named" message |
| Text Extraction | PDF has no text layer | Skip file, report to user, continue to next |
| LLM Extraction | Invalid JSON (retries exhausted) | Fall back to manual input |
| LLM Extraction | Incomplete fields | Use UNKNOWN placeholders |
| User Confirmation | User chooses Skip | Move to next file |
| User Confirmation | User aborts (Ctrl+C) | Exit immediately |
| File Rename | Target exists | Prompt for overwrite confirmation |

## Verbose Output

When `--verbose` is enabled, output additional information:

- List of files to be processed (before starting)
- Raw Ollama response
- Retry attempts for malformed JSON

## Class Structure

Following the existing pattern in the codebase, the implementation is split between the CLI layer (Thor) and the Commands layer (business logic).

### CLI Layer

**File:** `lib/cli/rename.rb`

```ruby
module Parkive
  class CLI < Thor
    desc "rename DIR", "Renames PDFs in DIR based on their content"
    method_option :verbose, type: :boolean, default: false, desc: "Verbose output"

    def rename(directory)
      raise NoSourceDirectoryError.new(directory) unless Dir.exist?(directory)
      raise PopplerNotInstalledError unless Dependencies.poppler_installed?
      raise OllamaNotInstalledError unless Dependencies.ollama_installed?
      raise OllamaNotRunningError unless Dependencies.ollama_running?

      Parkive::Commands.rename(
        directory: directory,
        prompt: Prompts::SelectPrompt,  # or appropriate Prompts class
        verbose: options[:verbose]
      )
    end
  end
end
```

**Responsibilities:**
- Define Thor command and options
- Validate that the input directory exists
- Check external dependencies (Poppler, Ollama) and fail fast with clear messages
- Pass control to `Commands.rename` with parsed options

### Commands Layer

**File:** `lib/parkive/commands/rename.rb`

```ruby
module Parkive
  module Commands
    def self.rename(directory:, prompt:, verbose: false)
      # Find non-conforming PDFs
      # Iterate through each, extract text, get LLM fields, confirm, rename
    end
  end
end
```

**Responsibilities:**
- Orchestrate the full rename flow
- Delegate to helper classes for specific tasks

### Supporting Classes

```
Parkive::Dependencies
  - Checks for external dependencies (Poppler, Ollama)
  - Located in lib/parkive/dependencies.rb

Parkive::DirectoryScanner
  - Finds and filters PDFs
  - Located in lib/parkive/directory_scanner.rb

Parkive::TextExtractor
  - Wraps Poppler text extraction
  - Located in lib/parkive/text_extractor.rb

Parkive::FieldExtractor
  - Wraps Ollama communication
  - Handles retries and parsing
  - Located in lib/parkive/field_extractor.rb

Parkive::RenamePrompter
  - Handles user confirmation UI (confirm/edit/skip)
  - Uses Prompts gem
  - Located in lib/parkive/rename_prompter.rb
```

## Dependencies

| Dependency | Type | Purpose |
|------------|------|---------|
| `poppler` | Gem | Ruby bindings for PDF text extraction |
| `pdftotext` | CLI tool | Poppler command-line tool (must be installed separately) |
| `ruby-llm` | Gem | LLM client for Ollama communication |
| `ollama` | CLI tool | Local LLM server (must be installed and running) |
| `prompts` | Gem | User input handling (already used by other commands) |

## Open Questions & Future Decisions

### Resolved

1. **Processing order** - Order does not matter (decided in HLD)
2. **Abort handling** - Exit immediately, no special handling (decided in HLD)
3. **Incomplete extraction** - Use UNKNOWN placeholders (decided in HLD)
4. **Malformed JSON** - Retry 3x, then manual input (decided in HLD)
5. **Filename validation** - User-edited filenames must conform to the archivable pattern (`YYYY.MM.DD.*`). If invalid, show error and prompt again.
6. **Case sensitivity** - `*.PDF` files are treated the same as `*.pdf`.

### Deferred

1. **Info field heuristics** - What should Ollama prioritize extracting for the "info" field? To be determined through testing.

## References

- [High-Level Design](/docs/high-level-design.md)
- [Poppler documentation](https://poppler.freedesktop.org/)
- [ruby-llm gem](https://github.com/crmne/ruby-llm)
