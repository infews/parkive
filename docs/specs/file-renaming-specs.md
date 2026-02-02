# File Renaming Specifications

## CLI Layer

- **REN-CLI-001**: When the user runs the rename command without a directory argument, the system shall display usage help.
- **REN-CLI-002**: If the specified directory does not exist, then the system shall raise `NoSourceDirectoryError`.
- **REN-CLI-003**: If Poppler is not installed, then the system shall raise `PopplerNotInstalledError` with installation instructions.
- **REN-CLI-004**: If Ollama is not installed, then the system shall raise `OllamaNotInstalledError` with installation instructions including `ollama pull llama3.1:8b`.
- **REN-CLI-005**: If Ollama is installed but not running, then the system shall raise `OllamaNotRunningError` with a message to start Ollama.
- **REN-CLI-006**: When the `--verbose` flag is provided, the system shall pass verbose mode to the Commands layer.

## Directory Scanner

- **REN-SCAN-001**: The system shall find all files with `.pdf` or `.PDF` extension in the specified directory.
- **REN-SCAN-002**: The system shall filter out files that already match the archivable pattern (`YYYY.MM.DD.*`).
- **REN-SCAN-003**: If no PDF files exist in the directory, then the system shall display "no PDFs found" and exit.
- **REN-SCAN-004**: If all PDF files already conform to the naming pattern, then the system shall display "all files already named" and exit.

## Text Extraction

- **REN-TEXT-001**: When processing a PDF, the system shall extract text content using Poppler.
- **REN-TEXT-002**: If a PDF has no text layer, then the system shall skip the file, report to the user, and continue to the next file.

## LLM Field Extraction

- **REN-LLM-001**: The system shall send extracted text to Ollama using the `llama3.1:8b` model.
- **REN-LLM-002**: The system shall request JSON output with `date`, `credit_card`, `vendor`, `account_number`, `invoice_number`, `type`, and `other` fields.
- **REN-LLM-003**: When Ollama returns valid JSON, the system shall parse all fields.
- **REN-LLM-004**: If Ollama returns invalid JSON, then the system shall retry up to 3 times.
- **REN-LLM-005**: If all retries fail, then the system shall fall back to manual input mode.
- **REN-LLM-006**: If Ollama returns valid JSON with missing or empty fields, then the system shall use `UNKNOWN` as a placeholder.
- **REN-LLM-007**: While verbose mode is enabled, the system shall display the raw Ollama response.
- **REN-LLM-008**: While verbose mode is enabled and retrying, the system shall display each retry attempt.

## Name Suggestor

- **REN-NAME-001**: The system shall build a filename from extracted fields in the order: date, credit_card, vendor, account_number, invoice_number, type, other.
- **REN-NAME-002**: The system shall omit empty fields from the filename.
- **REN-NAME-003**: The system shall replace whitespace with dots in field values.
- **REN-NAME-004**: The system shall remove filesystem-unsafe characters (/, \, :, *, ?, ", <, >, |) from field values.
- **REN-NAME-005**: The system shall collapse multiple consecutive dots into a single dot.
- **REN-NAME-006**: If the date field is missing or invalid, then the system shall use "UNKNOWN" as the date portion.
- **REN-NAME-007**: The system shall append ".pdf" to the generated filename.

## User Confirmation

- **REN-UI-001**: The system shall display the original filename and suggested new filename.
- **REN-UI-002**: The system shall offer three options: Confirm, Edit, and Skip.
- **REN-UI-003**: When the user chooses Confirm, the system shall proceed with renaming using the suggested filename.
- **REN-UI-004**: When the user chooses Edit, the system shall present an editable prompt with the suggested filename.
- **REN-UI-005**: When the user submits an edited filename, the system shall validate it conforms to the archivable pattern (`YYYY.MM.DD.*`).
- **REN-UI-006**: If the edited filename does not conform to the pattern, then the system shall display an error and prompt again.
- **REN-UI-007**: When the user chooses Skip, the system shall leave the file unchanged and proceed to the next file.
- **REN-UI-008**: When LLM extraction fails completely, the system shall prompt for manual filename entry.
- **REN-UI-009**: If the manually entered filename does not conform to the pattern, then the system shall display an error and prompt again.
- **REN-UI-010**: When in manual entry mode, if the user presses Enter without input, the system shall skip the file.

## File Renaming

- **REN-FILE-001**: When the user confirms or edits a filename, the system shall rename the file in place.
- **REN-FILE-002**: If a file with the target name already exists, then the system shall prompt for overwrite confirmation.
- **REN-FILE-003**: The system shall preserve the file's directory location when renaming.

## Processing Flow

- **REN-PROC-001**: The system shall process all non-conforming PDFs.
- **REN-PROC-002**: When the user aborts with Ctrl+C, the system shall exit immediately.
- **REN-PROC-003**: While verbose mode is enabled, the system shall display the list of files to be processed before starting.
