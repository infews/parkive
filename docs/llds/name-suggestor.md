# Name Suggestor

**Created**: 2026-02-01
**Status**: Design Phase

## Context and Design Philosophy

The Name Suggestor takes structured fields extracted by the LLM and builds a suggested filename that conforms to the archivable pattern. This is separated from the LLM extraction because the rules for building filenames may need iteration and are independent of how fields are extracted.

**Guiding principles:**
- **Predictable output** - Same input fields always produce the same filename
- **Safe filenames** - Never produce filenames with unsafe characters
- **Readable filenames** - Use dots as separators, omit empty fields

## Input

Hash of extracted fields from LLM:

| Field | Required | Example |
|-------|----------|---------|
| `date` | Yes | "2026.01.31" |
| `credit_card` | No | "Visa", "Master Card", "American Express" |
| `vendor` | No | "Fidelity", "City of Burlingame" |
| `account_number` | No | "12345" |
| `invoice_number` | No | "INV-2026-001" |
| `type` | No | "Bill", "Statement" |
| `other` | No | "Mortgage", "Lab Results" |

## Output

A filename string conforming to the archivable pattern: `YYYY.MM.DD.{rest}.pdf`

## Rules

### 1. Pattern Conformance

The filename must start with a valid date in `YYYY.MM.DD` format. If the date field is missing or invalid, use `UNKNOWN` as the date portion.

### 2. No Whitespace

All whitespace must be replaced with dots.

### 3. Dot Separators

All field values are joined with dots. Multiple consecutive dots are collapsed to a single dot.

### 4. Filesystem Safety

The following characters are removed or replaced:
- `/` `\` `:` `*` `?` `"` `<` `>` `|`

### 5. Empty Field Handling

Empty fields are omitted entirely from the filename.

## Field Ordering

Fields are concatenated in this order (empty fields skipped):

```
{date}.{credit_card}.{vendor}.{account_number}.{invoice_number}.{type}.{other}.pdf
```

## Examples

| Input Fields | Output Filename |
|--------------|-----------------|
| `date: "2026.01.31", vendor: "Fidelity", account_number: "12345"` | `2026.01.31.Fidelity.12345.pdf` |
| `date: "2026.02.15", credit_card: "Visa", vendor: "Costco", account_number: "9876"` | `2026.02.15.Visa.Costco.9876.pdf` |
| `date: "2026.03.01", vendor: "City of Burlingame", type: "Bill"` | `2026.03.01.City.of.Burlingame.Bill.pdf` |
| `date: "2026.01.15", credit_card: "American Express", type: "Statement"` | `2026.01.15.American.Express.Statement.pdf` |
| `date: "", vendor: "Unknown Corp"` | `UNKNOWN.Unknown.Corp.pdf` |

## Implementation

```ruby
# @spec REN-NAME-001 through REN-NAME-005
class NameSuggestor
  UNSAFE_CHARS = /[\/\\:*?"<>|]/
  FIELD_ORDER = [:date, :credit_card, :vendor, :account_number, :invoice_number, :type, :other]

  def self.suggest(fields)
    parts = FIELD_ORDER
      .map { |key| fields[key] }
      .compact
      .reject { |v| v.to_s.empty? }
      .map { |s| sanitize(s) }

    # Use UNKNOWN if date is missing
    parts[0] = "UNKNOWN" if parts.empty? || !valid_date?(parts[0])

    "#{parts.join('.')}.pdf"
  end

  def self.sanitize(str)
    str.to_s
       .gsub(/\s+/, '.')
       .gsub(UNSAFE_CHARS, '')
       .gsub(/\.+/, '.')
  end

  def self.valid_date?(str)
    str.to_s.match?(/^\d{4}\.\d{2}\.\d{2}$/)
  end
end
```

## Open Questions & Future Decisions

### Deferred

1. **Field abbreviations** - Should "American Express" become "Amex"? Should "Master Card" become "MC"? To be determined through testing.
2. **Maximum filename length** - Should we truncate very long filenames? What's the limit?
3. **Special character handling** - How to handle accented characters or non-ASCII text?

## References

- [High-Level Design](/docs/high-level-design.md)
- [File Renaming LLD](/docs/llds/file-renaming.md)
