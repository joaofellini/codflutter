import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class Tarefa {
  String descricao;
  bool concluida;
  Color cor;

  Tarefa(this.descricao, this.concluida, this.cor);

  Map<String, dynamic> toMap() {
    return {
      'descricao': descricao,
      'concluida': concluida,
      'cor': cor.value,
    };
  }

  factory Tarefa.fromMap(Map<String, dynamic> map) {
    return Tarefa(
      map['descricao'],
      map['concluida'],
      Color(map['cor']),
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Lista To Do!",
      home: TarefasApp(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TarefasApp extends StatefulWidget {
  @override
  _TarefasAppState createState() => _TarefasAppState();
}

class _TarefasAppState extends State<TarefasApp> {
  TextEditingController _controller = TextEditingController();
  List<Tarefa> tarefas = [];
  int totalTarefas = 0;
  int tarefasConcluidas = 0;

  @override
  void initState() {
    super.initState();
    loadTarefas();
  }

  void loadTarefas() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> tarefasStringList = prefs.getStringList('tarefas') ?? [];

    setState(() {
      tarefas = tarefasStringList
          .map((tarefaString) => Tarefa.fromMap(
                Map<String, dynamic>.from(
                  (tarefaString != null) ? jsonDecode(tarefaString) : {},
                ),
              ))
          .toList();

      // Atualiza as contagens ao carregar as tarefas salvas
      totalTarefas = tarefas.length;
      tarefasConcluidas = tarefas.where((tarefa) => tarefa.concluida).length;
    });
  }

  void saveTarefas() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> tarefasStringList =
        tarefas.map((tarefa) => jsonEncode(tarefa.toMap())).toList();
    prefs.setStringList('tarefas', tarefasStringList);
  }

  void adicionarTarefa() {
    String novaTarefa = _controller.text.trim();

    if (novaTarefa.isNotEmpty) {
      setState(() {
        tarefas.add(Tarefa(novaTarefa, false, Colors.transparent));
        _controller.clear();
        totalTarefas++;
        saveTarefas(); // Salvar ao adicionar uma nova tarefa
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🚫 Não é possível adicionar uma tarefa vazia!'),
        ),
      );
    }
  }

  void marcarConcluida(int index) {
    setState(() {
      tarefas[index].concluida = !tarefas[index].concluida;
      tarefas[index].cor = tarefas[index].concluida
          ? const Color.fromARGB(255, 104, 215, 107)
          : Colors.transparent;

      if (tarefas[index].concluida) {
        tarefasConcluidas++;
      } else {
        tarefasConcluidas--;
      }

      saveTarefas(); // Salvar ao marcar como concluída
    });
  }

  void removerTarefa(int index) {
    setState(() {
      if (tarefas[index].concluida) {
        tarefasConcluidas--;
      }

      tarefas.removeAt(index);
      totalTarefas--;
      saveTarefas(); // Salvar ao remover uma tarefa
    });
  }

  void limparLista() {
    setState(() {
      tarefas.clear();
      totalTarefas = 0;
      tarefasConcluidas = 0;
      saveTarefas(); // Salvar ao limpar a lista
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Lista de Tarefas - $tarefasConcluidas de $totalTarefas concluídas'),
        backgroundColor: Color.fromARGB(255, 104, 215, 107),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              limparLista();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      labelText: 'Nova Tarefa',
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              adicionarTarefa();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 104, 215, 107),
            ),
            child: Text('Adicionar Tarefa'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: tarefas.length,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: const Color.fromARGB(255, 104, 215, 107)),
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                    color: tarefas[index].cor,
                  ),
                  margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: ListTile(
                    title: Row(
                      children: [
                        Checkbox(
                          value: tarefas[index].concluida,
                          onChanged: (bool? valor) {
                            marcarConcluida(index);
                          },
                          activeColor: Colors.grey, // Cor quando pressionado
                        ),
                        Expanded(
                          child: Text(tarefas[index].descricao),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            removerTarefa(index);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
