A Dart plugin to generate boilerplate for your local database, 
featuring low coupling and type safety, completely inspired by the [sqlc](https://sqlc.dev/) go library.

This plugin works in any OS and can be used with [sqflite](https://pub.dev/packages/sqflite) and [sqflite_common_ffi](https://pub.dev/packages/sqflite_common_ffi)

## Features

Use this plugin in your dart application to:

- Generate classes from your DDL code.
- Generate methods from your queries with type safety.
- Consume data from your database without needing to worry about type casting and all the boilerplate.

## Getting started

To use this plugin you need to install sqflite or sqflite_common_ffi.

## Usage

Create a .sql file anywhere in your lib folder and write your custom SQL commands.

```sql
create table customers (
    id integer primary key autoincrement,
    name varchar not null default null,
    status varchar not null default ''
);

--name getCustomerByName :one
select * from customers where name = ? and status = :status;

--name: insertCustomer :exec
insert into customers(name, status) values (?, ?);
```
<details>
<summary>Generated code:</summary>
 

```dart
// in file sqlitec/schemas.dart
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
Future<Customers?> getCustumerByNameAndStatus(String $arg1, {
  required String status,
}) async {
    final result = await db.rawQuery(
      'SELECT * FROM customers WHERE name = ? AND status = ?',
      [$arg1, status],
    );
    
    if (result.isEmpty) return null;
    final resultFirst = result.first;
    return Customers.fromJson(resultFirst);
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

await queries.insertCustomer(name: 'Kauli', status: 'registered');
final user = await queries.getCustomerByNameAndStatus('Kauli', status: 'registered');

print(user); // Customers(id: 1, name: Kauli, status: registered,)
```
