# Basic Usage — as simple as possible

This project is inspired by [sqlc](https://sqlc.dev/) and aims to generate simple, type-safe Dart code from your SQL files. It is **not** an ORM: it just generates boilerplate for you, so you can work with your database using plain SQL and strongly-typed Dart methods.

---

## 1. Write schema and queries in `.sql` files

Place your `.sql` files under `lib/` (or another watched folder).

**Example schema (`schemas.sql`):**
```sql
create table customers (
  id integer primary key autoincrement,
  name varchar not null,
  status varchar not null,
  updated_at timestamp not null
);
```

**Example queries (`selects.sql`):**
```sql
-- name: getCustomerById :one
select * from customers where id = ?;

-- name: getCustomersByStatus :many
select * from customers where status = :status;

-- name: deleteOld :exec
delete from customers where updated_at < :olderThan;
```

---

## 2. Comment directive format

Place a comment directly above each SQL statement:

- `-- name: methodName :one|:many|:exec`
  - `:one`  → single nullable result (`Future<T?>`)
  - `:many` → list of results (`Future<List<T>>`)
  - `:exec` → execute-only (`Future<int>` — rows affected)

---

## 3. How parameters map

- Positional `?` placeholders → positional parameters in method (`$arg1`, `$arg2`, ...).
  - Example: `WHERE id = ?`  → method param: `int $arg1`
- Named variables `:name` → required named Dart parameters.
  - Example: `WHERE status = :status` → method param: `required String status`
- `LIMIT`/`OFFSET` variables → `int`
- `LIKE`/`GLOB`/`MATCH`/`REGEXP` → `String`

---

## 4. How nullability works

- Column declared `NOT NULL` or `PRIMARY KEY` → non-nullable Dart field (`int`, `String`).
- Otherwise → nullable Dart field (`int?`, `String?`, etc.)

---

## 5. Expected generated API (example)

### Table row class

```dart
class Customer {
  final int id;
  final String name;
  final String status;
  final String updatedAt; // stored as ISO string

  Customer({
    required this.id,
    required this.name,
    required this.status,
    required this.updatedAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) => ...;
  Map<String, dynamic> toJson() => ...;
}
```

### Queries class

```dart
class Queries {
  final DatabaseExecutor db;
  Queries(this.db);

  Future<Customer?> getCustomerById(int $arg1) async { ... }
  Future<List<Customer>> getCustomersByStatus({required String status}) async { ... }
  Future<int> deleteOld({required String olderThan}) async { ... }
}
```

---

## 6. Generated Methods Reference

This section explains all generated methods for each SQL operation—**SELECT**, **INSERT**, **UPDATE**, and **DELETE**—with clear examples for both named and unnamed parameters. These methods are generated based on the SQL statements and their parameter styles in your `.sql` files.

---

### SELECT

- **Unnamed (positional) parameter**:
```sql
-- name: getCustomerById :one
SELECT * FROM customers WHERE id = ?;
```
```dart
Future<Customer?> getCustomerById(int $arg1) async { ... }
```
*Use when your SQL uses `?` placeholders. The Dart method will have positional parameters named `$arg1`, `$arg2`, etc.*

- **Named parameter:**
```sql
-- name: getCustomersByStatus :many
SELECT * FROM customers WHERE status = :status;
```
```dart
Future<List<Customer>> getCustomersByStatus({required String status}) async { ... }
```
*Use when your SQL uses `:name` placeholders. The Dart method will have required named parameters.*

- **Multiple parameters (mixed):**
```sql
-- name: getByNameAndStatus :one
SELECT * FROM customers WHERE name = ? AND status = :status;
```
```dart
Future<Customer?> getByNameAndStatus(String $arg1, {required String status}) async { ... }
```
*You can mix positional and named parameters. The Dart method will reflect this.*

---

### INSERT

- **Positional parameters:**
```sql
-- name: insertCustomer :exec
INSERT INTO customers(name, status) VALUES (?, ?);
```
```dart
Future<int> insertCustomer(String $arg1, String $arg2) async { ... }
```
*For `?` placeholders, parameters are positional.*

- **Named parameters:**
```sql
-- name: insertCustomerNamed :exec
INSERT INTO customers(name, status) VALUES (:name, :status);
```
```dart
Future<int> insertCustomerNamed({required String name, required String status}) async { ... }
```
*For `:name` placeholders, parameters are named.*

---

### UPDATE

- **Named parameters:**
```sql
-- name: updateStatus :exec
UPDATE customers SET status = :status WHERE id = :id;
```
```dart
Future<int> updateStatus({required String status, required int id}) async { ... }
```

- **Mixed parameters:**
```sql
-- name: updateStatusMixed :exec
UPDATE customers SET status = ? WHERE id = :id;
```
```dart
Future<int> updateStatusMixed(String $arg1, {required int id}) async { ... }
```

---

### DELETE

- **Positional parameter:**
```sql
-- name: deleteById :exec
DELETE FROM customers WHERE id = ?;
```
```dart
Future<int> deleteById(int $arg1) async { ... }
```

- **Named parameter:**
```sql
-- name: deleteByStatus :exec
DELETE FROM customers WHERE status = :status;
```
```dart
Future<int> deleteByStatus({required String status}) async { ... }
```

- **Multiple parameters:**
```sql
-- name: deleteByName :exec
DELETE FROM customers WHERE name = ? OR name = :name;
```
```dart
Future<int> deleteByName(String $arg1, {required String name}) async { ... }
```

---

### Return Types

- `:one` → Returns a single row or `null` (`Future<T?>`)
- `:many` → Returns a list of rows (`Future<List<T>>`)
- `:exec` → Returns the number of rows affected (`Future<int>`)

#### How result types are inferred

- **Full table selection:**  
  If your query selects all columns from a table (e.g., `SELECT * FROM customers`), the generated method returns an instance of the corresponding Dart class (e.g., `Customer`).

- **Partial table selection:**  
  If your query selects only some columns from a table (e.g., `SELECT id, name FROM customers`), the generated method returns a Dart record containing just those fields:
  ```dart
  Future<(int id, String name)?> getIdAndName(int $arg1) async { ... }
  ```

- **Joins or subqueries:**  
  If your query selects columns from multiple tables or includes computed columns (e.g., joins, subqueries, expressions), the return type is inferred from the selected columns:
    - **Single column:**  
      If only one column is selected (e.g., `SELECT COUNT(*) FROM customers`), the method returns that column’s Dart type (e.g., `Future<int?>`).
    - **Multiple columns:**  
      If multiple columns are selected (e.g., `SELECT c.id, o.total FROM customers c JOIN orders o ON ...`), the method returns a Dart record with those fields:
      ```dart
      Future<(int id, double total)?> getCustomerOrderTotal(int $arg1) async { ... }
      ```

**Tip:**  
Dart records provide a concise way to work with queries that return multiple fields but do not map directly to a table class.

---

**Tip:**  
Use named parameters for clarity and maintainability, especially for queries with multiple arguments.

---

## 7. Workflow

- Edit `.sql` files → run build_runner → import generated files → call methods on the generated `Queries` instance.

---

## 8. Recommendations

- Use explicit SQL types to keep method signatures stable.
- Store dates as ISO 8601 strings for cross-platform consistency; convert to `DateTime` in app code if needed.

---

## 9. About

This project is inspired by [sqlc](https://sqlc.dev/) and is designed to generate simple, explicit Dart types and query methods from your SQL files. It is not an ORM and does not hide SQL from you — you always write and see your SQL, but get strong typing and less boilerplate in Dart.