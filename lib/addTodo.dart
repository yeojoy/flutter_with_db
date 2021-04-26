import 'package:flutter/material.dart';
import 'todo.dart';

class AddTodoApp extends StatelessWidget {

  // pickme
  TextEditingController _titleController = TextEditingController();
  TextEditingController _contentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text('add Toto'),
      ),
      body: Container(
        child: Center(
          child: Column(
            children: <Widget> [
              Padding(
                padding: EdgeInsets.all(10),
                child: TextField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: 'Title'),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(10),
                child: TextField(
                  controller: _contentController,
                  decoration: InputDecoration(labelText: 'What do I do ...'),
                ),
              ),
              ElevatedButton(
                child: Text('Save'),
                onPressed: () {
                  Todo todo = Todo(
                      title: _titleController.value.text,
                      content: _contentController.value.text,
                      active: false
                  );
                  // pickme todo who is pop's parameter, is returned in "onPressed"
                  Navigator.of(context).pop(todo);
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}

// class AddTodoApp extends StatefulWidget {
//   @override
//   State<StatefulWidget> createState() => _AddTodoApp();
// }
//
// class _AddTodoApp extends State<AddTodoApp> {
//
//   // pickme
//   late TextEditingController titleController;
//   late TextEditingController contentController;
//
//   @override
//   void initState() {
//     super.initState();
//     titleController = TextEditingController();
//     contentController = TextEditingController();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('add Toto'),
//       ),
//       body: Container(
//         child: Center(
//           child: Column(
//             children: <Widget> [
//               Padding(
//                 padding: EdgeInsets.all(10),
//                 child: TextField(
//                   controller: titleController,
//                   decoration: InputDecoration(labelText: 'Title'),
//                 ),
//               ),
//               Padding(
//                 padding: EdgeInsets.all(10),
//                 child: TextField(
//                   controller: contentController,
//                   decoration: InputDecoration(labelText: 'What do I do ...'),
//                 ),
//               ),
//               ElevatedButton(
//                 child: Text('Save'),
//                 onPressed: () {
//                   Todo todo = Todo(
//                     title: titleController.value.text,
//                     content: contentController.value.text,
//                     active: false
//                   );
//                   // pickme todo who is pop's parameter, is returned in "onPressed"
//                   Navigator.of(context).pop(todo);
//                 },
//               )
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }