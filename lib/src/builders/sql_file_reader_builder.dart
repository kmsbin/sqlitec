import 'dart:async';
import 'dart:convert';
import 'package:build/build.dart';

class SqlFileReaderBuilder extends Builder {
  final BuilderOptions options;

  SqlFileReaderBuilder(this.options);

  @override
  Map<String, List<String>> get buildExtensions => {
        '.sql': ['.sqlitec.json'],
      };

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    final id = buildStep.inputId;
    final copy = id.changeExtension('.sqlitec.json');
    final content = await buildStep.readAsString(id);
    final jsonContent = {
      "content": content,
    };
    await buildStep.writeAsString(copy, jsonEncode(jsonContent));
  }
}
