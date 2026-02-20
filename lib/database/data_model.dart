// abstract class for all datamodels in the app

abstract class DataModel {
  // can later switch to UUID string identifiers if want to go online
  int? get id;
  Map<String, dynamic> toMap();
  String get tableName;
}
