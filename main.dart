import 'dart:async';
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
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final tarefas_controller = TextEditingController();

  Map<String, dynamic> _lastRemovement;

  int _last_removementPos;

  List _ToDoList = [];

  Future<Null> _Refresh() async {
    await Future.delayed(Duration(seconds: 2));

    setState(() {
      _ToDoList.sort((a, b) {
        // ordena a lista
        if (a["ok"] && !b["ok"]) {
          return 1; // caso a for finalizado b vai para cima
        } else if (!a["ok"] && b["ok"]) {
          //caso b foi finalizada a vai para cima
          return -1;
        } else {
          // caso for igual mantem o mesmo
          return 0;
        }
      });
      _SetFile();
      return null;
    });
  }

  @override
  void initState() {
    super.initState();

    _ReadData().then((data) {
      setState(() {
        _ToDoList = json.decode(data);
      });
    });
  }

  void _AdicionarAlista() {
    setState(() {
      Map<String, dynamic> nova = Map();
      nova["title"] = tarefas_controller.text;
      print(tarefas_controller.text);
      tarefas_controller.text = " ";
      nova["ok"] = false;
      _ToDoList.add(nova);

      _SetFile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Tarefas"),
        centerTitle: true,
        backgroundColor: Colors.lightBlue,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: <Widget>[
                Expanded(
                    child: TextField(
                  decoration: InputDecoration(
                      labelText: "Nova tarefa",
                      labelStyle:
                          TextStyle(fontSize: 17.0, color: Colors.lightBlue)),
                  controller: tarefas_controller,
                )),
                RaisedButton(
                  color: Colors.lightBlue,
                  child: Text("ADD"),
                  textColor: Colors.white,
                  onPressed: _AdicionarAlista,
                )
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
                onRefresh: _Refresh,
                child: ListView.builder(
                    padding: EdgeInsets.only(top: 10.0),
                    itemCount: _ToDoList.length,
                    itemBuilder: buildItem // chamada de metodo
                    )),
          ),
        ],
      ),
    );
  }

  Widget buildItem(contexto, index) {
    return Dismissible(
      // função que permite fazer exclusão
      key: Key(DateTime.now().microsecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      // função que permite qual lado será removido
      child: CheckboxListTile(
        title: Text(_ToDoList[index]["title"]),
        value: _ToDoList[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(_ToDoList[index]["ok"] ? Icons.check : Icons.error),
        ),
        onChanged: (c) {
          setState(() {
            _ToDoList[index]["ok"] = c;
            _SetFile();
          });
        },
      ),
      onDismissed: (direction) {
        // o que vai fazer quando for até o final
        setState(() {
          _lastRemovement = Map.from(_ToDoList[index]);
          _last_removementPos = index; // serve para armazenar a tarefa removida
          _ToDoList.removeAt(index);
          _SetFile();

          final snack = SnackBar(
            content: Text(
                "Tarefa \"${_lastRemovement["title"]}\" foi removida com sucesso !"),
            action: SnackBarAction(
              label: "Desfazer",
              onPressed: () {
                setState(() {
                  _ToDoList.insert(_last_removementPos, _lastRemovement);
                  _SetFile();
                });
              },
            ),
            duration: Duration(seconds: 4),
          );
          Scaffold.of(context).removeCurrentSnackBar();
          Scaffold.of(context).showSnackBar(snack);
        });
      },
    );
  }

  Future<File> _GetFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _SetFile() async {
    String data = json.encode(_ToDoList);

    final file = await _GetFile();
    return file.writeAsString(data);
  }

  Future<String> _ReadData() async {
    try {
      final file = await _GetFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}
