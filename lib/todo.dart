final String tableName = 'todos';
final String columnId = '_id';
final String columnTitle = 'title';
final String columnContent = 'content';
final String columnActive = 'active';

class Todo {
  // pickme
  late int id = 1;
  late String title;
  late String content;
  late bool active;

  Map<String, dynamic> toMap() {
    var map = <String, dynamic> {
      columnTitle: title,
      columnContent: content,
      columnActive: active == true ? 1 : 0
    };
    return map;
  }

  // pickme
  setId(int id) {
    this.id = id;
  }

  // pickme
  Todo({required this.title, required this.content, required this.active});
}