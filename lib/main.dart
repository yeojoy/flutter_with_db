import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
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
        'second': (context) => AddTodoApp()
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

  @override
  void initState() {
    super.initState();
    todoList = getTodos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My TODO app"),
      ),
      body: Container(
        child: Center(
        // PICKME should be Generic at FutureBuilder
        child: FutureBuilder<List<Todo>>(
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
                  return ListView.builder(
                    itemBuilder: (content, index) {
                      debugPrint("content : $content and index : $index");
                      var todo = snapshot.data?.elementAt(index) as Todo;
                      return makeTodoListTile(context, todo);
                      // return makeTodoCard(todo);
                    },
                    itemCount: snapshot.data?.length,
                  );
                } else {
                  // pickme 바꿔보자
                  return Text('No data!');
                }
            }
            return CircularProgressIndicator();
          },
          future: todoList,
        )
      )),
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
      floatingActionButtonLocation: FloatingActionButtonLocation
          .endFloat, // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  // (C)REATE insert todo item
  void _insertTodo(Todo todo) async {
    final Database database = await widget.db;
    // insert function in sqflite library
    await database.insert(tableName, todo.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);

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
    int active = todo.active ? 1 : 0;
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

  void _refreshList() {
    setState(() {
      todoList = getTodos();
    });
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
        leading: Icon(todo.active ? Icons.verified : Icons.verified_outlined),
        onTap: () {
          debugPrint(
              'Todo : ${todo.id}, ${todo.title}, ${todo.content}, ${todo.active}');
          todo.active = !todo.active;
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
}
