# File Renaming Implementation Plan

**Created**: 2026-02-01
**Status**: Planning
**Design Doc**: `/docs/llds/file-renaming.md`
**EARS Specs**: `/docs/specs/file-renaming-specs.md`

## Overview

Implement the File Renaming feature, which extracts text from PDFs, uses Ollama to identify date/vendor/info fields, and renames files to the archivable pattern (`YYYY.MM.DD.Vendor.Info.pdf`).

## Success Criteria

- User can run `parkive rename <directory>` to rename PDFs
- Non-conforming PDFs are processed in alphabetical order
- User confirms, edits, or skips each rename
- Verbose mode shows extraction details
- All 38 EARS specs pass

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

- [ ] All deliverables implemented with @spec annotations
- [ ] Phase specs verified: REN-CLI-001 through REN-CLI-006 (6 total)
- [ ] Unit tests passing for Dependencies module
- [ ] CLI integration tests passing

---

### Phase 2: Directory Scanner

**Goal**: Find and filter PDFs that need renaming.

#### Deliverables

1. **DirectoryScanner Class**
   - **Specs**: REN-SCAN-001, REN-SCAN-002, REN-SCAN-003
   - `lib/parkive/directory_scanner.rb`
   - Find `.pdf` and `.PDF` files
   - Filter out already-conforming files
   - Sort alphabetically (case-insensitive)

2. **Commands Integration**
   - **Specs**: REN-SCAN-004, REN-SCAN-005, REN-PROC-003
   - `lib/parkive/commands/rename.rb` skeleton
   - Handle empty directory case
   - Handle all-conforming case
   - Display file list in verbose mode

#### Testing Requirements

- **REN-SCAN-001**: Test finds both `.pdf` and `.PDF` files
- **REN-SCAN-002**: Test filters out conforming files
- **REN-SCAN-003**: Test alphabetical sorting
- **REN-SCAN-004**: Test "no PDFs found" message
- **REN-SCAN-005**: Test "all files already named" message
- **REN-PROC-003**: Test verbose file list display

#### Definition of Done

- [ ] All deliverables implemented with @spec annotations
- [ ] Phase specs verified: REN-SCAN-001 through REN-SCAN-005, REN-PROC-003 (6 total)
- [ ] Unit tests passing for DirectoryScanner
- [ ] Integration tests for empty/all-conforming cases

---

### Phase 3: Text Extraction

**Goal**: Extract text content from PDF files using Poppler.

#### Deliverables

1. **TextExtractor Class**
   - **Specs**: REN-TEXT-001, REN-TEXT-002, REN-TEXT-003
   - `lib/parkive/text_extractor.rb`
   - Extract text using Poppler gem
   - Handle PDFs with no text layer
   - Verbose output (truncated to 500 chars)

#### Testing Requirements

- **REN-TEXT-001**: Test text extraction from valid PDF
- **REN-TEXT-002**: Test handling of PDF with no text layer
- **REN-TEXT-003**: Test verbose output truncation

#### Definition of Done

- [ ] All deliverables implemented with @spec annotations
- [ ] Phase specs verified: REN-TEXT-001 through REN-TEXT-003 (3 total)
- [ ] Unit tests passing with test PDF fixtures
- [ ] Manual test with real PDF file

---

### Phase 4: LLM Field Extraction

**Goal**: Use Ollama to extract date, vendor, and info from PDF text.

#### Deliverables

1. **FieldExtractor Class**
   - **Specs**: REN-LLM-001 through REN-LLM-008
   - `lib/parkive/field_extractor.rb`
   - Send prompt to Ollama via ruby-llm gem
   - Parse JSON response
   - Retry logic (up to 3 times)
   - Handle incomplete fields with `UNKNOWN`
   - Verbose output for raw response and retries

2. **ExtractionResult Struct**
   - Data structure for extraction results
   - `complete?` and `to_filename` methods

#### Testing Requirements

- **REN-LLM-001**: Test Ollama communication with correct model
- **REN-LLM-002**: Test JSON format in request
- **REN-LLM-003**: Test successful JSON parsing
- **REN-LLM-004**: Test retry on invalid JSON
- **REN-LLM-005**: Test fallback after 3 retries
- **REN-LLM-006**: Test UNKNOWN placeholder for missing fields
- **REN-LLM-007**: Test verbose raw response output
- **REN-LLM-008**: Test verbose retry attempt output

#### Definition of Done

- [ ] All deliverables implemented with @spec annotations
- [ ] Phase specs verified: REN-LLM-001 through REN-LLM-008 (8 total)
- [ ] Unit tests passing with mocked Ollama responses
- [ ] Manual test with real Ollama instance

---

### Phase 5: User Confirmation

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

- [ ] All deliverables implemented with @spec annotations
- [ ] Phase specs verified: REN-UI-001 through REN-UI-010 (10 total)
- [ ] Unit tests passing with mocked Prompts gem
- [ ] Manual test of full UI flow

---

### Phase 6: Integration and File Renaming

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
   - Process files in alphabetical order
   - Handle Ctrl+C abort

3. **End-to-End Testing**
   - Full flow from CLI to renamed files

#### Testing Requirements

- **REN-FILE-001**: Test file is renamed correctly
- **REN-FILE-002**: Test overwrite confirmation prompt
- **REN-FILE-003**: Test file stays in same directory
- **REN-PROC-001**: Test alphabetical processing order
- **REN-PROC-002**: Test Ctrl+C exits immediately

#### Definition of Done

- [ ] All deliverables implemented with @spec annotations
- [ ] Phase specs verified: REN-FILE-001 through REN-FILE-003, REN-PROC-001, REN-PROC-002 (5 total)
- [ ] All unit tests passing
- [ ] Integration tests passing
- [ ] Manual end-to-end test with real PDFs

---

## Requirements Traceability

| Phase | Specs | Count |
|-------|-------|-------|
| Phase 1: CLI and Dependencies | REN-CLI-001 to 006 | 6 |
| Phase 2: Directory Scanner | REN-SCAN-001 to 005, REN-PROC-003 | 6 |
| Phase 3: Text Extraction | REN-TEXT-001 to 003 | 3 |
| Phase 4: LLM Field Extraction | REN-LLM-001 to 008 | 8 |
| Phase 5: User Confirmation | REN-UI-001 to 010 | 10 |
| Phase 6: Integration | REN-FILE-001 to 003, REN-PROC-001 to 002 | 5 |
| **Total** | | **38** |

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
- [Low-Level Design](/docs/llds/file-renaming.md)
- [EARS Specifications](/docs/specs/file-renaming-specs.md)
