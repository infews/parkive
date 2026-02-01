# Parkive 

Parkive is for managing the archiving of PDF files. It contains features for:

- Making a standardized set of directories for a given year
- Moving PDF files into those directories based on a date-based filename pattern
- Renaming PDF files according to the pattern based on the PDF's contents

## Project Overview

This is a Ruby command line script, using the Thor gem for command line handling, and delegating to do the real work.

All code is test-driven using RSpec. The Thor code is minimal, creating objects in the `Parkive:Commands` namespace for the real work. The RSpec tests are in the directory `./spec`, while the design and EARS specs are in the `./docs` directory.

### Non-Goals

The following are explicitly out of scope for Parkive:

- **OCR for scanned PDFs** - If a PDF has no text layer, Parkive stops. It will not attempt OCR to extract text from images.
- **Non-PDF files** - Only PDFs are handled. No support for images, Word docs, or other formats.
- **Automatic file retrieval** - Users must provide the PDFs. No downloading from email, banks, or cloud services.
- **Search or indexing** - Parkive organizes files into folders but does not provide search, tagging, or a database.
- **Duplicate detection** - No checking for existing similar documents in the archive.
- **GUI** - CLI only.
- **Cloud storage integration** - Works with local filesystem. No direct Dropbox, Google Drive, or S3 support (though the archive root could be a synced folder).
- **PDF modification** - Renames and moves files, never modifies PDF contents.
- **Multi-user/permissions** - Personal use tool, no access control.

## Feature: Directory Creation (Implemented)

This feature creates a standardized directory structure for archiving files for a given year. The structure is:

```
{archive_root}/{year}/
├── 01.Jan/
├── 02.Feb/
├── 03.Mar/
├── 04.Apr/
├── 05.May/
├── 06.Jun/
├── 07.Jul/
├── 08.Aug/
├── 09.Sep/
├── 10.Oct/
├── 11.Nov/
├── 12.Dec/
├── {year}.Media/
└── {year}.Tax/
```

The Thor command takes an `archive_root` path and a `year`, then creates all directories using `FileUtils.mkdir_p`.

## Feature: File Storing (Implemented)

This feature moves PDF files into the archive directory structure based on a date prefix in the filename. Files must follow the naming pattern:

```
YYYY.MM.DD.{rest-of-filename}.pdf
```

For example, `2026.01.15.WellsFargo.Statement.pdf` would be moved to `{archive_root}/2026/01.Jan/`.

### Processing Rules

- Only files matching the date pattern are considered "archivable"
- Files are moved to `{archive_root}/{year}/{month}/` based on the date in their filename
- If a file already exists in the destination, the user is prompted to confirm overwrite
- A `--force` flag skips the overwrite prompt and overwrites all
- A `--verbose` flag shows each file as it's moved

## Feature: File Renaming 

This feature takes a PDF, extracts its text, and renames the file according to a specific pattern. That pattern is:

[Date].[Vendor].[Info].pdf

- Date should be the statement date, in the format of `YYYY.MM.DD`
- Vendor is the company, bank, utility, that generated the file
- Info is some context about the PDF; this could be an account number, invoice number, or something else

This prompts the user with a suggested filename, which the user can edit. Once the filename is agreed upon, the file is renamed in place. 

### Processing Steps and Rules

#### Directory

The Thor command should take a directory as input. If there are no PDFs in the directory, it should report that to the user and do nothing. If all of the PDFs in the directory already conform to the filename pattern, it should report that to the user and do nothing. It should only proceed when there are PDFs in the directory that do not conform to the filename pattern.

When processing, it should automatically iterate through all non-conforming PDFs, prompting the user for confirmation on each file. If the user aborts (Ctrl+C), exit immediately with no special handling. The order of processing non-conforming PDFs does not matter.

A `--verbose` flag shows additional detail during processing, such as the extracted text and raw Ollama response.

#### Poppler

To extract the text, this uses the poppler command line tool and the Ruby poppler gem. If the command line tool is not present, the Thor command should stop and tell the user to install it before continuing.

#### Ollama

To process the text, and find the useful text for the renaming, this uses Ollama with the `llama3.1:8b` model and the Ruby-llm gem. If Ollama is not present, the Thor command should stop and tell the user to install it and pull the model (`ollama pull llama3.1:8b`) before continuing. If Ollama is present but not running, the Thor command should stop and tell the user to run it before continuing.

#### Getting Text from the PDF

At this point, it attempts to find text in the PDF. If there is no text in the PDF, it should stop and report this to the user.

If there is text in the PDF, it should continue.

#### Extracting Desired Fields from the Text

This is the heart of the work. We have a PDF, it has a text layer, and now we need to use Ollama to find the desired information from the text.

The script sends a prompt to Ollama, with the text, to attempt to extract:

- The Desired Date (in the format: `YYYY.MM.DD`)
- The Vendor Name, without spaces (e.g., `PGE`, `WellsFargo`, or `CityOfBurlingame`)
- Remaining interesting information from the file

There are some special Cases of Vendor name. There are probably others - we will figure this out during the testing of this part of the code.

1. Credit Cards - these statements should list the card type first, then the bank (e.g., `MC.Apple` or `Visa.Costco`)
2. American Express - these credit card statements should just return the vendor name as Amex

The returned name should come back from Ollama as JSON of the form:

```JSON
{
    "date": "2026.01.31",
    "vendor": "MC.Apple",
    "info": "132412352"
}
```

#### Error Handling

**Malformed JSON response:** If Ollama returns invalid JSON, retry the request up to 3 times. If all retries fail, fall back to manual input - show the user the raw response and prompt them to enter the filename manually.

**Incomplete extraction:** If Ollama returns valid JSON but one or more fields are missing or empty, use `UNKNOWN` as a placeholder for the missing fields. The user can then edit the suggested filename in the confirmation step.

#### Suggesting the Name and Confirming with the User

The script should offer the suggested filename to the user with three options:

1. **Confirm** - Accept the suggested name and rename the file
2. **Edit** - Modify the suggested name, then rename the file
3. **Skip** - Leave this file unchanged and move to the next one

This section of the code should use the `Prompts` gem for user input, the same as other commands.