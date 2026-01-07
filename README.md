A Dart plugin to generate boilerplate code for your local database,  
featuring low coupling and type safety, completely inspired by the [sqlc](https://sqlc.dev/) Go library.

**IT IS NOT AN ORM.** This package has no intention of being an ORM. 
Instead, it simply writes the tedious parts of database handling for you, leaving you in 
control and fully aware of what is happening. There is no magic code, no surprises, just simple, and idiomatic dart code.

This plugin works on any operating system and can be used with [sqflite](https://pub.dev/packages/sqflite) and [sqflite_common_ffi](https://pub.dev/packages/sqflite_common_ffi).

## 📚 [Official Documentation](https://kmsbin.github.io/sqlitec/)

## Features

Use this plugin in your Dart application to:
- Automatically generate Dart classes from your database tables.
- Call your queries as simple, type-safe Dart methods.
- Enjoy type-safe query arguments, ensuring correct types at compile time.
- Work with your database easily, without manual type casting or boilerplate code.

## Getting started

To use this plugin you will need the sqflite or sqflite_common_ffi implementation.

## Usage

Create a .sql file anywhere in your lib folder and write your custom SQL commands.

```sql
create table customers (
    id integer primary key autoincrement,
    name varchar not null default '',
    status varchar not null default ''
);

--name: getCustomerByNameAndStatus :one
select * from customers where name = ? and status = :status;

--name: insertCustomer :exec
insert into customers(name, status) values (?, ?);
```
<details>
<summary>Generated code:</summary>
 

```dart
// sqlitec/schemas.dart
class Customers {
  static const String $tableInfo = 'customers';
  static const String $createTableStatement = 'CREATE TABLE customers(id integer PRIMARY KEY AUTOINCREMENT, name varchar NOT NULL DEFAULT NULL, status varchar NOT NULL DEFAULT \'\')';
  int id;
  String name;
  String status;

  Customers({
    required this.id,
    required this.name,
    required this.status,
  });

  factory Customers.fromJson(Map<String, dynamic> jsonMap) {
    return Customers(
      id: (jsonMap['id'] as num).toInt(),
      name: jsonMap['name'] as String,
      status: jsonMap['status'] as String,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status,
    };
  }

  String toString() {
    return '''Customers(
  id: $id,
  name: $name,
  status: $status,
)''';  }

...
// methods inside Queries class on sqlitec/queries.sqlitec.dart
Future<Customers?> getCustomerByNameAndStatus(String $arg1, {
  required String status,
}) async {
    final result = await db.rawQuery(
      'SELECT * FROM customers WHERE name = ? AND status = ?',
      [$arg1, status],
    );
    
    if (result.isEmpty) return null;

    return Customers.fromJson(result.first);
}

Future<int> insertCustomer({
  required String name,
  required String status,
}) async {
    final result = await db.rawInsert(
      'INSERT INTO customers (name, status) VALUES (?, ?)',
      [
        name,
        status,
      ],
    );

    return result;
}
```
</details>

### Using the generated code

```dart
final queries = Queries(db: /*your db instance*/);

await queries.insertCustomer(name: 'Bob', status: 'registered');
final user = await queries.getCustomerByNameAndStatus('Bob', status: 'registered');

print(user); // Customers(id: 1, name: Bob, status: registered,)
```

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
