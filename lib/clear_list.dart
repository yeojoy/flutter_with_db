import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'todo.dart';

class ClearTodoList extends StatefulWidget {
  Future<Database> database;
  ClearTodoList(this.database);

  @override
  _ClearTodoListState createState() => _ClearTodoListState();
}

class _ClearTodoListState extends State<ClearTodoList> {
  late Future<List<Todo>> clearList;

  @override
  void initState() {
    super.initState();
    clearList = getClearList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Clear list"),
      ),
      body: Container(
        child: Center(
          child: FutureBuilder<List<Todo>>(
            builder: (context, snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.none:
                case ConnectionState.waiting:
                case ConnectionState.active:
                  return CircularProgressIndicator();
                case ConnectionState.done: {
                  if (snapshot.hasData) {
                    // pickme
                    if (snapshot.data != null && snapshot.data!.isEmpty) {
                      return Text("No data.");
                    }
                    return ListView.builder(
                      itemBuilder: (context, index) {
                        var todo = snapshot.data?.elementAt(index) as Todo;
                        return makeTodoListTile(context, todo);
                      },
                      itemCount: snapshot.data?.length,
                    );
                  } else {
                    return Text("No data.");
                  }
                }
              }
            },
           future: clearList,
          )
        )
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          var data = await clearList;

          if (data.length == 0) {

            return;
          }

          final result = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text("모두 삭제"),
                content: Text("완료한 일을 모두 삭제하시겠습니까?"),
                actions: <Widget> [
                  MaterialButton(
                      onPressed: () {
                        Navigator.of(context).pop(true);
                      },
                      child: Text("모두 삭제")
                  ),
                  MaterialButton(onPressed: () { Navigator.of(context).pop(false); },
                    child: Text("취소"),)
                ]
              );
            }
          );

          if (result!) {
            _removeAllTodos();
          }
        },
        child: Icon(Icons.delete),
      ),
    );
  }

  Future<List<Todo>> getClearList() async {
    final Database database = await widget.database;
    // https://www.sqlitetutorial.net/sqlite-where/
    List<Map<String, dynamic>> maps =
      await database.rawQuery('select * from $tableName where $columnActive = 1');
    // List<Map<String, dynamic>> maps = await database.query(tableName, columns: null, where: "$columnActive = ?", whereArgs: [ 1 ]);
    // List<Map<String, dynamic>> maps = await database.query(
    //     tableName,
    //     columns: null, // null인 경우 전체 columns을 가져
    //     where: "$columnContent LIKE ? or $columnContent LIKE ?",
    //     whereArgs: [ "pick%", "beers" ]
    // );

    return List.generate(maps.length, (i) {
      return Todo(
        title: maps[i][columnTitle].toString(),
        content: maps[i][columnContent].toString(),
        id: maps[i][columnId]
      );
    });
  }

  _removeAllTodos() async {
    final Database database = await widget.database;
    // database.rawDelete("delete from $tableName where $columnActive = 1");
    database.delete(tableName, where: "$columnActive = ?", whereArgs: [ 1 ]);
    setState(() {
      clearList = getClearList();
    });
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
        leading: Icon(Icons.done),
        // leading: SizedBox(
        //   width: 64,
        //   height: 56
        // ),

    );
  }
}
