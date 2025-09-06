import 'package:build/build.dart';
import 'src/builders/builder.dart';
import 'src/builders/sql_file_reader_builder.dart';

Builder sqlToDartBuilder(BuilderOptions options) =>
    SqlFileReaderBuilder(options);

Builder sqlToDartGenerator(BuilderOptions options) => SqliteGenerator();
