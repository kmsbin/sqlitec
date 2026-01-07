# SQL → Dart Type Map (Dart first, simple 2 columns)

| Dart type   | SQL type examples |
|-------------|-------------------|
| int         | integer, int, tinyint, smallint, bigint |
| double      | real, double, float, decimal, numeric |
| String      | text, varchar, char, datetime, timestamp, date |
| "List<int>"   | blob |
| dynamic     | any unrecognized type |

Notes
- Nullability: NOT NULL / PRIMARY KEY → non-nullable Dart type (e.g., int). Otherwise generated type is nullable (e.g., int?).
- Parameters:
  - Named :name → required named Dart params.
  - Positional ? → positional params ($arg1, $arg2, ...).
- For date/time values, prefer storing ISO 8601 strings for predictable behavior. Convert to DateTime in app code if needed.