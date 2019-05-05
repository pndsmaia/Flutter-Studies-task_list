import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  Home({Key key}) : super(key: key);

  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _taskController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  List _toDoList = [];
  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPosition;

  @override
  void initState() {
    super.initState();
    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Tarefas'),
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: TextFormField(
                      decoration: InputDecoration(
                          labelText: 'Nova Tarefa',
                          labelStyle: TextStyle(color: Colors.blueAccent)),
                      controller: _taskController,
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'Por favor, escreva alguma tarefa!';
                        }
                      },
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    if (_formKey.currentState.validate()) {
                      _addNewTask();
                    }
                  },
                  icon: Icon(Icons.add),
                )
              ],
            ),
          ),
          Expanded(
              child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: EdgeInsets.only(top: 10.0),
              itemCount: _toDoList.length,
              itemBuilder: (context, index) {
                return ListTile(title: buildListItem(context, index));
              },
            ),
          ))
        ],
      ),
    );
  }

  void _addNewTask() {
    setState(() {
      Map<String, dynamic> newTask = Map();
      newTask['title'] = _taskController.text;
      _taskController.text = '';
      newTask['complete'] = false;
      _toDoList.add(newTask);
    _refresh();
    _saveData();
    });
  }

  Widget buildListItem(context, index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
          color: Colors.red,
          child: Align(
            alignment: Alignment(-0.9, 0.0),
            child: Icon(
              Icons.delete,
              color: Colors.white,
            ),
          )),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        onChanged: (check) {
          setState(() {
            _toDoList[index]['complete'] = check;
            _saveData();
          });
        },
        title: Text(_toDoList[index]['title']),
        value: _toDoList[index]['complete'],
        secondary: CircleAvatar(
          child: Icon(_toDoList[index]['complete'] ? Icons.check : Icons.error),
        ),
      ),
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_toDoList[index]);
          _lastRemovedPosition = index;
          _toDoList.removeAt(index);
          _saveData();

          final snackbar = SnackBar(
            content:
                Text('A Tarefa \"${_lastRemoved['title']}\" foi deletada.'),
            action: SnackBarAction(
              label: 'Desfazer',
              onPressed: () {
                setState(() {
                  _toDoList.insert(_lastRemovedPosition, _lastRemoved);
                  _saveData();
                });
              },
            ),
            duration: Duration(seconds: 2),
          );
          Scaffold.of(context).showSnackBar(snackbar);
        });
      },
    );
  }

  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _toDoList.sort((a, b) {
        if (a['complete'] && !b['complete']) {
          return 1;
        } else if (!a['complete'] && b['complete']) {
          return -1;
        } else {
          return 0;
        }
      });
      _saveData();
    });
    return null;
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/data.json');
  }

  Future<File> _saveData() async {
    String data = json.encode(_toDoList);

    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();

      return file.readAsString();
    } catch (error) {
      return error;
    }
  }
}
