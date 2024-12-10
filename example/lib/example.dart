import 'dart:convert';

import 'package:example/sqlitec/queries.sqlitec.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'sqlitec/schemas.sqlitec.dart';

Future<void> main(List<String> arguments) async {
  sqfliteFfiInit();
  final db = await databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      onConfigure: (db) async {
        await db.execute(Orders.$createTableStatement);
        await db.execute(Customers.$createTableStatement);
        await db.execute(Payments.$createTableStatement);
      },
    ),
  );

  final queries = Queries(db: db);

  var id = await queries.insertCustumer(name: 'Kauli', status: 'registered');
  print(id);
  await db.update('customers', {'updated_at': 'asdfasdfasdf'});
  // final user = await queries.getCustumerByNameAndStatus('Kauli', status: 'registered');
  final asdf =
      await db.query('customers', where: 'name = ?', whereArgs: ['Kauli']);
  print(jsonEncode(asdf));
  await db.close();
}
