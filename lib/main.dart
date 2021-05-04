import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'clear_list.dart';
import 'add_todo.dart';
import 'todo.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Future<Database> database = initDatabase();

    return MaterialApp(
      title: 'My todo',
      theme: ThemeData(primarySwatch: Colors.teal),
      initialRoute: 'first',
      routes: {
        // pickme route name은 약속일 뿐 '/'가 아니여도 됨.
        'first': (context) => DatabaseApp(database),
        // pickme no need to send a db object
        'second': (context) => AddTodoApp(),
        '/clearList': (context) => ClearTodoList(database),
      },
    );
  }

  Future<Database> initDatabase() async {
    return openDatabase(
      join(await getDatabasesPath(), 'my_todos.db'),
      onCreate: (db, version) {
        return db.execute(
            "CREATE TABLE $tableName($columnId INTEGER PRIMARY KEY AUTOINCREMENT, "
            "$columnTitle TEXT, $columnContent TEXT, $columnActive BOOL)");
      },
      version: 1, // pickme to migrate database. 자세한 설명은 라이브러리 사이트에 있습니다.
    );
  }
}

class DatabaseApp extends StatefulWidget {
  final Future<Database> db;
  DatabaseApp(this.db);

  @override
  State<StatefulWidget> createState() {
    return _DatabaseAppState();
  }
  // pickme 같은 것. 아래는 dart의 lambda 문법
  // @override
  // State<StatefulWidget> createState() => _DatabaseAppState();
}

class _DatabaseAppState extends State<DatabaseApp> {
  late Future<List<Todo>> todoList;
  late TextEditingController _searchTextEditingController;

  @override
  void initState() {
    super.initState();
    todoList = getTodos();
    _searchTextEditingController = TextEditingController();
  }
zzk
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My TODO app"),
        actions: <Widget> [
          MaterialButton(
            onPressed: () async {
              await Navigator.of(context).pushNamed('/clearList');
              _refreshList();
            },
            onLongPress: () {
              _makeTextData();
            },
            child: Text("완료한 일",
              style: TextStyle(color: Colors.white)
            )
          ),
        ]
      ),
      body: _getBody(),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final todo = await Navigator.of(context).pushNamed('second');

          if (todo != null) {
            // pickme casting is mandatory.
            debugPrint('todo data : ${(todo as Todo).title}');
            _insertTodo(todo);
          }
        },
        child: Icon(Icons.add),
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // (C)REATE insert todo item
  void _insertTodo(Todo todo) async {
    final Database database = await widget.db;
    // insert function in sqflite library
    // await database.insert(tableName, todo.toMap(),
    //     conflictAlgorithm: ConflictAlgorithm.replace);
    // await database.rawInsert("INSERT INTO $tableName($columnTitle, $columnContent, $columnActive) VALUES('${todo.title}', '${todo.content}', ${todo.active! ? 1 : 0})");
    await database.rawInsert("INSERT INTO $tableName($columnTitle, $columnContent, $columnActive) VALUES(?, ?, ?)", [todo.title, todo.content, todo.active! ? 1 : 0]);

    _refreshList();
  }

  // (R)EAD select all todo items
  Future<List<Todo>> getTodos() async {
    final Database database = await widget.db;
    // final List<Map<String, dynamic>> maps = await database.query(tableName);
    final List<Map<String, dynamic>> maps = await database.rawQuery("SELECT * FROM $tableName");
    debugPrint('Map length ${maps.length}');

    return List.generate(maps.length, (i) {
      bool active = maps[i][columnActive] == 1 ? true : false;
      var todo = Todo(
          title: maps[i][columnTitle].toString(),
          content: maps[i][columnContent].toString(),
          active: active);
      todo.setId(maps[i][columnId]);

      debugPrint(
          '$i : ${todo.id}, ${todo.title}, ${todo.content}, ${todo.active}');
      return todo;
    });
  }

  /// (U)PDATE update todo item in Database
  void _updateTodo(Todo todo) async {
    final Database database = await widget.db;
    // await database.update(
    //     tableName,
    //     todo.toMap(),
    //     where: '$columnId = ?',
    //     whereArgs: [todo.id]
    // );
    // pickme, sqlite doesn't have a boolean type. https://www.sqlite.org/datatype3.html
    int active = todo.active != null ? (todo.active! ? 1 : 0) : 0;
    // pickme use raw query
    await database.rawUpdate('update $tableName set $columnActive = $active where $columnId = ${todo.id}');

    _refreshList();
  }

  /// (D)ELETE delete todo item in Database
  void _deleteTodo(Todo todo) async {
    final Database database = await widget.db;
    // await database.delete(
    //   tableName,
    //   where: '$columnId = ?',
    //   whereArgs: [todo.id]
    // );
    await database.rawDelete("DELETE FROM $tableName WHERE $columnId = ${todo.id}");

    _refreshList();
  }

  void _query(String text) async {
    final database = await widget.db;

    final List<Map<String, dynamic>> maps = await database.rawQuery("SELECT * FROM $tableName WHERE $columnTitle LIKE '%$text%' OR $columnContent LIKE '%$text%'");

    setState(() {
      todoList = getSearchResult(maps);
    });
  }

  Future<List<Todo>> getSearchResult(List<Map<String, dynamic>> maps) async {
    return List.generate(maps.length, (i) {
      bool active = maps[i][columnActive] == 1 ? true : false;
      var todo = Todo(
          title: maps[i][columnTitle].toString(),
          content: maps[i][columnContent].toString(),
          active: active);
      todo.setId(maps[i][columnId]);

      debugPrint("todo: ${todo.id}, ${todo.title}, ${todo.content}");
      return todo;
    });
  }

  _refreshList() {
    setState(() {
      todoList = getTodos();
    });
  }

  Widget _getBody() {
    return Container(
        child: Center(
          // PICKME should be Generic at FutureBuilder
            child: Column(
              children: <Widget> [
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: TextField(
                    controller: _searchTextEditingController,
                    maxLines: 1,
                    onChanged: (text) {
                      final query = text.trim();
                      if (query.length >= 2) {
                        debugPrint("query: $query");
                        _query(query.trim());
                      } else {
                        _refreshList();
                      }
                    },
                  ),
                ),
                FutureBuilder<List<Todo>>(
                  builder: (context, snapshot) {
                    switch (snapshot.connectionState) {
                      case ConnectionState.none:
                        return CircularProgressIndicator();
                      case ConnectionState.waiting:
                        return CircularProgressIndicator();
                      case ConnectionState.active:
                        return CircularProgressIndicator();
                      case ConnectionState.done:
                        if (snapshot.hasData && snapshot.data != null) {
                          return snapshot.data!.length > 0 ? Expanded(
                            child: ListView.builder(
                              itemBuilder: (context, index) {
                                var todo = snapshot.data?.elementAt(index) as Todo;
                                return makeTodoListTile(context, todo);
                                // return makeTodoCard(todo);
                              },
                              itemCount: snapshot.data?.length,
                            ),
                          ) : Text('No data!');
                        }
                    }
                    // pickme dead code.
                    return CircularProgressIndicator();
                  },
                  future: todoList,
                ),
              ],
            )
        )
    );
  }
  // pickme make children with Card Widget, but there is no tap event.
  Card makeTodoCard(Todo todo) {
    return Card(
        child: GestureDetector(
          child: Column(children: <Widget>[
            Text('${todo.id} -> ${todo.title}'),
            Text(todo.content),
            Text(todo.active.toString())
          ]
        )
      )
    );
  }

  ListTile makeTodoListTile(BuildContext context, Todo todo) {
    return ListTile(
        title: Text(todo.title, style: TextStyle(fontSize: 20)),
        subtitle: Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(todo.content),
            ],
          )
        ),
        leading: Icon(todo.active! ? Icons.verified : Icons.verified_outlined),
        onTap: () {
          debugPrint(
              'Todo : ${todo.id}, ${todo.title}, ${todo.content}, ${todo.active}');
          todo.active = !todo.active!;
          debugPrint(
              'Todo : ${todo.id}, ${todo.title}, ${todo.content}, ${todo.active}');
          _updateTodo(todo);
        },
        onLongPress: () async {
          Todo result = await showDialog(
            context: context,
            barrierDismissible: true,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('${todo.id} : ${todo.title}'),
                content: Text('Are you sure to delete ${todo.content} item?'),
                actions: <Widget> [
                  MaterialButton(
                    onPressed: () {
                      Navigator.of(context).pop(todo);
                    },
                    child: Text("Delete")
                  ),
                  MaterialButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text("Cancel"),
                  )
                ],
              );
            }
          );

          if (result != null) {
            _deleteTodo(result);
          }
          // showDialogToDeleteTodo(context, todo);

        }
    );
  }

  /*
   * Delete todo when user presses the item longtime.
   */
  void showDialogToDeleteTodo(BuildContext context, Todo todo) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${todo.id} : ${todo.title}'),
          content: Text('Are you sure to delete ${todo.content} item?'),
          actions: [
            MaterialButton(
              onPressed: () {
                _deleteTodo(todo);
                Navigator.of(context).pop();
              },
              child: Text("Delete")
            ),
            MaterialButton(onPressed: () { Navigator.of(context).pop(); },
            child: Text("Cancel"),)
          ],
        );
      }
    );
  }

  _makeTextData() {
    var todo = Todo(title: "Children", content: "Pick up EY at school.", active: false);
    _insertTodo(todo);
    todo = Todo(title: "Children", content: "Pick up DY at daycare.", active: false);
    _insertTodo(todo);
    todo = Todo(title: "Bank", content: "Withdraw \$100.", active: false);
    _insertTodo(todo);
    todo = Todo(title: "Work", content: "Daily meeting at 12pm", active: false);
    _insertTodo(todo);
    todo = Todo(title: "Work", content: "Quick demo.", active: false);
    _insertTodo(todo);
    todo = Todo(title: "Back", content: "Send \$449.80 to wife.", active: false);
    _insertTodo(todo);
    todo = Todo(title: "Grocery", content: "Costco at 5pm.", active: false);
    _insertTodo(todo);
    todo = Todo(title: "Parc", content: "aller au parc.", active: false);
    _insertTodo(todo);
    todo = Todo(title: "Français", content: "apprendre le cours demain matin.", active: false);
    _insertTodo(todo);
    todo = Todo(title: "examen", content: "prendre en examen de français.", active: false);
    _insertTodo(todo);
  }
}
