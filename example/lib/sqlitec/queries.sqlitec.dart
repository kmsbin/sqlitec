import 'package:sqflite_common/sqlite_api.dart';
import 'schemas.sqlitec.dart';

class Queries {
  DatabaseExecutor db;

  Queries({
    required this.db,
  });

  Future<Customers?> getCustumerByNameAndStatus(
    String $arg1, {
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

  Future<int> insertCustumer({
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

  Future<List<Customers?>> getCustomersById(int $arg1) async {
    final result = await db.rawQuery(
      'SELECT * FROM customers WHERE customers.id = ?',
      [$arg1],
    );

    return result.map((e) => Customers.fromJson(e)).toList();
  }

  Future<Customers?> getCustomerById(int $arg1) async {
    final result = await db.rawQuery(
      'SELECT * FROM customers WHERE customers.id = ?',
      [$arg1],
    );

    if (result.isEmpty) return null;
    final resultFirst = result.first;
    return Customers.fromJson(resultFirst);
  }

  Future<List<int?>> getCustomersIdWhereStatusIs({
    required String status,
  }) async {
    final result = await db.rawQuery(
      'SELECT id FROM customers WHERE status = ?',
      [status],
    );

    return result.map((e) => (e['id'] as num).toInt()).toList();
  }

  Future<int> insertCustomer({
    required int id,
    required String name,
    required String status,
    required dynamic updatedAt,
  }) async {
    final result = await db.rawInsert(
      'INSERT INTO customers VALUES (?, ?, ?)',
      [
        id,
        name,
        status,
        updatedAt,
      ],
    );

    return result;
  }

  Future<int> insertOrder({
    required int id,
    required double total,
    required int customerId,
    required String customerName,
    required String customerStatus,
    required dynamic date,
    required dynamic dated,
  }) async {
    final result = await db.rawInsert(
      'INSERT INTO orders VALUES (?, ?, ?, ?, ?)',
      [
        id,
        total,
        customerId,
        customerName,
        customerStatus,
        date,
        dated,
      ],
    );

    return result;
  }

  Future<int> deleteCustomerByName(
    String $arg1, {
    required String name,
  }) async {
    final result = await db.rawDelete(
      'DELETE FROM customers WHERE name = ? OR name = ?',
      [$arg1, name],
    );

    return result;
  }

  Future<int> deleteCustomersWithoutPayments() async {
    final result = await db.rawDelete(
      'WITH custumers_without_payments AS (SELECT c.id FROM customers AS c LEFT JOIN payments AS p ON c.id = p.customer_id WHERE p.customer_id IS NULL) DELETE FROM customers WHERE id IN (SELECT id FROM custumers_without_payments)',
      [],
    );

    return result;
  }
}
