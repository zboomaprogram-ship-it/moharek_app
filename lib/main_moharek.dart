import 'package:moharek_app/core/config/app_config.dart';
import 'package:moharek_app/core/config/moharek_config.dart';
import 'package:moharek_app/main.dart' as entry;

void main() {
  AppConfig.setInstance(const MoharekConfig());
  entry.main();
}
