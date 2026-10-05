import 'package:sembast_web/sembast_web.dart';

Future<Database> openNamedDatabase(String name) =>
    databaseFactoryWeb.openDatabase(name);
