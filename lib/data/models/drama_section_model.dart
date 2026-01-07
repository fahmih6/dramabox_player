import 'drama_model.dart';

class DramaSectionModel {
  final String name;
  final List<DramaModel> dramas;

  DramaSectionModel({required this.name, required this.dramas});

  factory DramaSectionModel.fromJson(Map<String, dynamic> json) {
    return DramaSectionModel(
      name: json['name'] as String,
      dramas: (json['dramas'] as List)
          .map((e) => DramaModel.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'dramas': dramas.map((e) => e.toJson()).toList()};
  }
}
