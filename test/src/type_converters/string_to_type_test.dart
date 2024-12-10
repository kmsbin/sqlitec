import 'package:sqlitec/src/type_converters/string_to_basic_type.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  test('Must convert all to Basic.text', () {
    expect(getTypeByString('varchar'), BasicType.text);
    expect(getTypeByString('text'), BasicType.text);
    expect(getTypeByString('varchar'), BasicType.text);
    expect(getTypeByString('character'), BasicType.text);
    expect(getTypeByString('char'), BasicType.text);
    expect(getTypeByString('date'), BasicType.text);
    expect(getTypeByString('datetime'), BasicType.text);
  });

  test('Must convert all to Basic.int', () {
    expect(getTypeByString('int'), BasicType.int);
    expect(getTypeByString('tinyint'), BasicType.int);
    expect(getTypeByString('bigint'), BasicType.int);
  });
}
