
## 1. Add Dependencies

Add `sqlitec` and `build_runner` to your `dev_dependencies` in `pubspec.yaml`. See more on [installation page](./installation.md)

```sh
dart pub add build_runner
dart pub add sqlitec
```
---

## 2. Add Your SQL Files

Place your `.sql` files (schema and queries) under the `lib/` directory.  
Each SQL statement should be preceded by a comment directive (see [Basic Usage](usage.md)).

---

## 3. Run the Code Generator

Fetch dependencies and run the builder to generate Dart code from your SQL files:

```sh
dart pub get
dart run build_runner build --delete-conflicting-outputs
```

---

## 4. Locate the Generated Files

Generated Dart files will appear under `lib/` (e.g., `lib/queries.sqlitec.dart`, `lib/schemas.sqlitec.dart`).

---

## 5. Next Steps

- See [Basic Usage](usage.md) for how to write SQL files and use the generated code.
- See [Type Map](type_map.md) for SQL-to-Dart type mapping.

---

**Tip:**  
Whenever you update your `.sql` files, re-run the build command to update the generated Dart code.