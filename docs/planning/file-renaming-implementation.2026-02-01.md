# File Renaming Implementation Plan

**Created**: 2026-02-01
**Status**: In Progress (Phase 4)
**Design Docs**: `/docs/llds/file-renaming.md`, `/docs/llds/field-extractor.md`, `/docs/llds/name-suggestor.md`
**EARS Specs**: `/docs/specs/file-renaming-specs.md`

## Overview

Implement the File Renaming feature, which extracts text from PDFs, uses Ollama to identify date/vendor/info fields, and renames files to the archivable pattern (`YYYY.MM.DD.Vendor.Info.pdf`).

## Success Criteria

- User can run `parkive rename <directory>` to rename PDFs
- User confirms, edits, or skips each rename
- Verbose mode shows file list before processing
- All 43 EARS specs pass

## Implementation Phases

### Phase 1: CLI and Dependencies

**Goal**: Set up CLI command skeleton and dependency checking.

#### Deliverables

1. **Error Classes**
   - **Specs**: REN-CLI-002, REN-CLI-003, REN-CLI-004, REN-CLI-005
   - `NoSourceDirectoryError`
   - `PopplerNotInstalledError`
   - `OllamaNotInstalledError`
   - `OllamaNotRunningError`

2. **Dependencies Module**
   - **Specs**: REN-CLI-003, REN-CLI-004, REN-CLI-005
   - `Parkive::Dependencies.poppler_installed?`
   - `Parkive::Dependencies.ollama_installed?`
   - `Parkive::Dependencies.ollama_running?`

3. **CLI Command**
   - **Specs**: REN-CLI-001, REN-CLI-002, REN-CLI-006
   - `lib/cli/rename.rb` with Thor command
   - `--verbose` option
   - Directory validation and dependency checks

#### Testing Requirements

- **REN-CLI-001**: Test usage help when no directory provided
- **REN-CLI-002**: Test error when directory doesn't exist
- **REN-CLI-003**: Test error when Poppler not installed
- **REN-CLI-004**: Test error when Ollama not installed
- **REN-CLI-005**: Test error when Ollama not running
- **REN-CLI-006**: Test verbose flag is passed through

#### Definition of Done

- [x] All deliverables implemented with @spec annotations
- [x] Unit tests passing for Dependencies module
- [x] CLI integration tests passing
- [x] Phase specs verified:
  - [x] REN-CLI-001: Usage help when no directory provided
  - [x] REN-CLI-002: Error when directory doesn't exist
  - [x] REN-CLI-003: Error when Poppler not installed
  - [x] REN-CLI-004: Error when Ollama not installed
  - [x] REN-CLI-005: Error when Ollama not running
  - [x] REN-CLI-006: Verbose flag passed through

---

### Phase 2: Directory Scanner

**Goal**: Find and filter PDFs that need renaming.

#### Deliverables

1. **DirectoryScanner Class**
   - **Specs**: REN-SCAN-001, REN-SCAN-002
   - `lib/parkive/directory_scanner.rb`
   - Find `.pdf` and `.PDF` files (case-insensitive)
   - Filter out already-conforming files

2. **Commands Integration**
   - **Specs**: REN-SCAN-003, REN-SCAN-004, REN-PROC-003
   - `lib/parkive/commands/rename.rb` skeleton
   - Handle empty directory case
   - Handle all-conforming case
   - Display file list in verbose mode

#### Testing Requirements

- **REN-SCAN-001**: Test finds both `.pdf` and `.PDF` files
- **REN-SCAN-002**: Test filters out conforming files
- **REN-SCAN-003**: Test "no PDFs found" message
- **REN-SCAN-004**: Test "all files already named" message
- **REN-PROC-003**: Test verbose file list display

#### Definition of Done

- [x] All deliverables implemented with @spec annotations
- [x] Unit tests passing for DirectoryScanner
- [x] Integration tests for empty/all-conforming cases
- [x] Phase specs verified:
  - [x] REN-SCAN-001: Finds both .pdf and .PDF files
  - [x] REN-SCAN-002: Filters out conforming files
  - [x] REN-SCAN-003: "no PDFs found" message
  - [x] REN-SCAN-004: "all files already named" message
  - [x] REN-PROC-003: Verbose file list display

---

### Phase 3: Text Extraction

**Goal**: Extract text content from PDF files using Poppler.

#### Deliverables

1. **TextExtractor Class**
   - **Specs**: REN-TEXT-001, REN-TEXT-002
   - `lib/parkive/text_extractor.rb`
   - Extract text using Poppler gem
   - Handle PDFs with no text layer

#### Testing Requirements

- **REN-TEXT-001**: Test text extraction from valid PDF
- **REN-TEXT-002**: Test handling of PDF with no text layer

#### Definition of Done

- [x] All deliverables implemented with @spec annotations
- [x] Unit tests passing with test PDF fixtures
- [ ] Manual test with real PDF file
- [x] Phase specs verified:
  - [x] REN-TEXT-001: Text extraction from valid PDF
  - [x] REN-TEXT-002: Handling of PDF with no text layer

---

### Phase 4: LLM Field Extraction

**Goal**: Use Ollama to extract structured fields from PDF text.

**Design Doc**: `/docs/llds/field-extractor.md`

#### Deliverables

1. **FieldExtractor Class**
   - **Specs**: REN-LLM-001 through REN-LLM-007
   - `lib/parkive/field_extractor.rb`
   - Send prompt to Ollama via direct HTTP (`Net::HTTP`) to `/api/generate`
   - Model: `llama3.1:8b`
   - Parse JSON response with fields: date, credit_card, vendor, account_number, invoice_number
   - Retry logic (up to 3 times)
   - Verbose output for raw response and retries

2. **ExtractionResult Struct** (optional)
   - Data structure for extraction results
   - `complete?` method to check if required fields are present

#### Testing Requirements

- **REN-LLM-001**: Test Ollama communication with correct model
- **REN-LLM-002**: Test JSON format in request includes all fields
- **REN-LLM-003**: Test successful JSON parsing of all fields
- **REN-LLM-004**: Test retry on invalid JSON
- **REN-LLM-005**: Test fallback after 3 retries
- **REN-LLM-006**: Test verbose raw response output
- **REN-LLM-007**: Test verbose retry attempt output

#### Definition of Done

- [x] All deliverables implemented with @spec annotations
- [x] Unit tests passing with mocked Ollama responses
- [ ] Manual test with real Ollama instance
- [x] Phase specs verified:
  - [x] REN-LLM-001: Ollama communication with correct model
  - [x] REN-LLM-002: JSON format in request includes all fields
  - [x] REN-LLM-003: Successful JSON parsing of all fields
  - [x] REN-LLM-004: Retry on invalid JSON
  - [x] REN-LLM-005: Fallback after 3 retries
  - [x] REN-LLM-006: Verbose raw response output
  - [x] REN-LLM-007: Verbose retry attempt output

---

### Phase 5: Name Suggestor

**Goal**: Build suggested filenames from extracted fields.

**Design Doc**: `/docs/llds/name-suggestor.md`

#### Deliverables

1. **NameSuggestor Class**
   - **Specs**: REN-NAME-001 through REN-NAME-007
   - `lib/parkive/name_suggestor.rb`
   - Build filename from fields in order: date, credit_card, vendor, account_number, invoice_number
   - Omit empty fields
   - Replace whitespace with dots
   - Remove filesystem-unsafe characters
   - Collapse multiple dots
   - Handle missing date with UNKNOWN

#### Testing Requirements

- **REN-NAME-001**: Test field ordering in filename
- **REN-NAME-002**: Test empty fields are omitted
- **REN-NAME-003**: Test whitespace replaced with dots
- **REN-NAME-004**: Test unsafe characters removed
- **REN-NAME-005**: Test multiple dots collapsed
- **REN-NAME-006**: Test UNKNOWN used for missing date
- **REN-NAME-007**: Test .pdf extension appended

#### Definition of Done

- [x] All deliverables implemented with @spec annotations
- [x] Unit tests passing
- [ ] Examples from LLD verified
- [x] Phase specs verified:
  - [x] REN-NAME-001: Field ordering in filename
  - [x] REN-NAME-002: Empty fields are omitted
  - [x] REN-NAME-003: Whitespace replaced with dots
  - [x] REN-NAME-004: Unsafe characters removed
  - [x] REN-NAME-005: Multiple dots collapsed
  - [x] REN-NAME-006: UNKNOWN used for missing date
  - [x] REN-NAME-007: .pdf extension appended

---

### Phase 6: User Confirmation

**Goal**: Implement the confirm/edit/skip UI flow.

#### Deliverables

1. **RenamePrompter Class**
   - **Specs**: REN-UI-001 through REN-UI-010
   - `lib/parkive/rename_prompter.rb`
   - Display original and suggested filenames
   - Confirm/Edit/Skip selection
   - Editable filename prompt
   - Validation against archivable pattern
   - Manual input mode when LLM fails
   - Skip on empty input in manual mode

2. **RenameDecision Struct**
   - Data structure for user decision
   - Action (`:confirm`, `:edit`, `:skip`) and filename

#### Testing Requirements

- **REN-UI-001**: Test display of original and suggested filenames
- **REN-UI-002**: Test three options are presented
- **REN-UI-003**: Test confirm action
- **REN-UI-004**: Test edit prompt with suggested filename
- **REN-UI-005**: Test validation of edited filename
- **REN-UI-006**: Test error and re-prompt on invalid filename
- **REN-UI-007**: Test skip action
- **REN-UI-008**: Test manual input mode
- **REN-UI-009**: Test validation in manual input mode
- **REN-UI-010**: Test skip on empty manual input

#### Definition of Done

- [x] All deliverables implemented with @spec annotations
- [x] Unit tests passing with mocked Prompts gem
- [ ] Manual test of full UI flow
- [x] Phase specs verified:
  - [x] REN-UI-001: Display of original and suggested filenames
  - [x] REN-UI-002: Three options are presented
  - [x] REN-UI-003: Confirm action
  - [x] REN-UI-004: Edit prompt with suggested filename
  - [x] REN-UI-005: Validation of edited filename
  - [x] REN-UI-006: Error and re-prompt on invalid filename
  - [x] REN-UI-007: Skip action
  - [x] REN-UI-008: Manual input mode
  - [x] REN-UI-009: Validation in manual input mode
  - [x] REN-UI-010: Skip on empty manual input

---

### Phase 7: Integration and File Renaming

**Goal**: Wire all components together and implement file renaming.

#### Deliverables

1. **File Rename Logic**
   - **Specs**: REN-FILE-001, REN-FILE-002, REN-FILE-003
   - Rename file in place
   - Handle existing file conflict
   - Preserve directory location

2. **Commands.rename Integration**
   - **Specs**: REN-PROC-001, REN-PROC-002
   - Wire all components together
   - Process all non-conforming files
   - Handle Ctrl+C abort

3. **End-to-End Testing**
   - Full flow from CLI to renamed files

#### Testing Requirements

- **REN-FILE-001**: Test file is renamed correctly
- **REN-FILE-002**: Test overwrite confirmation prompt
- **REN-FILE-003**: Test file stays in same directory
- **REN-PROC-001**: Test all non-conforming PDFs are processed
- **REN-PROC-002**: Test Ctrl+C exits immediately

#### Definition of Done

- [ ] All deliverables implemented with @spec annotations
- [ ] All unit tests passing
- [ ] Integration tests passing
- [ ] Manual end-to-end test with real PDFs
- [ ] Phase specs verified:
  - [ ] REN-FILE-001: File is renamed correctly
  - [ ] REN-FILE-002: Overwrite confirmation prompt
  - [ ] REN-FILE-003: File stays in same directory
  - [ ] REN-PROC-001: All non-conforming PDFs are processed
  - [ ] REN-PROC-002: Ctrl+C exits immediately

---

## Requirements Traceability

| Phase | Specs | Count |
|-------|-------|-------|
| Phase 1: CLI and Dependencies | REN-CLI-001 to 006 | 6 |
| Phase 2: Directory Scanner | REN-SCAN-001 to 004, REN-PROC-003 | 5 |
| Phase 3: Text Extraction | REN-TEXT-001 to 002 | 2 |
| Phase 4: LLM Field Extraction | REN-LLM-001 to 007 | 7 |
| Phase 5: Name Suggestor | REN-NAME-001 to 007 | 7 |
| Phase 6: User Confirmation | REN-UI-001 to 010 | 10 |
| Phase 7: Integration | REN-FILE-001 to 003, REN-PROC-001 to 002 | 5 |
| **Total** | | **42** |

## Risk Assessment

### Medium Risk

**1. Ollama response variability**
- **Risk**: LLM may return inconsistent JSON formats across different PDFs
- **Mitigation**: Robust parsing with retries; fallback to manual input
- **Fallback**: User can always manually enter filename

**2. Poppler installation complexity**
- **Risk**: Users may have difficulty installing Poppler on their system
- **Mitigation**: Clear error messages with platform-specific install instructions
- **Fallback**: Document installation in README

### Low Risk

**3. PDF text extraction quality**
- **Risk**: Some PDFs may have poor text extraction
- **Mitigation**: LLM can work with imperfect text; user can edit result
- **Fallback**: Manual input mode

## References

- [High-Level Design](/docs/high-level-design.md)
- [File Renaming LLD](/docs/llds/file-renaming.md)
- [Field Extractor LLD](/docs/llds/field-extractor.md)
- [Name Suggestor LLD](/docs/llds/name-suggestor.md)
- [EARS Specifications](/docs/specs/file-renaming-specs.md)
