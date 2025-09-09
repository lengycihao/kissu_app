import 'package:json_annotation/json_annotation.dart';

part 'common_question_model.g.dart';

@JsonSerializable()
class CommonQuestionModel {
  String? problem;
  String? answer;

  CommonQuestionModel({this.problem, this.answer});

  factory CommonQuestionModel.fromJson(Map<String, dynamic> json) {
    return _$CommonQuestionModelFromJson(json);
  }

  Map<String, dynamic> toJson() => _$CommonQuestionModelToJson(this);
}
