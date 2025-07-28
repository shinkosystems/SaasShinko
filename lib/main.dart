import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SaaS Gestão Financeira', // Altere o título do app
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 233, 117, 8)),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Página Inicial - SaaS Gestão Financeira'), // Altere o título da página inicial
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Remova a variável _counter e a função _incrementCounter, elas não serão mais usadas aqui

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column( // Começa o novo body com uma Column
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Text(
              "Ações Rápidas",
              style: Theme.of(context).textTheme.headlineLarge, // Estilo de texto grande
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 160.0,
                  height: 80.0,
                  child: ElevatedButton(
                    onPressed: () {
                      print('Adicionar Receita Clicado!'); // Ação do botão
                    },
                    child: const Text('Adicionar Receita'),
                  ),
                ),
                const SizedBox(width: 16), // Espaço entre botões
                SizedBox(
                  width: 160.0,
                  height: 80.0,
                  child: OutlinedButton(
                    onPressed: () {
                      print('Adicionar Despesa Clicado!'); // Ação do botão
                    },
                    child: const Text('Adicionar Despesa'),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: TextButton(
              onPressed: () {
                print('Ver Relatórios Clicado!'); // Ação do botão
              },
              child: const Text('Ver Relatórios'),
            ),
          ),
          // Se quiser adicionar mais coisas, adicione aqui dentro da Column
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print('Botão Flutuante Clicado!'); // Nova ação para o FAB
        },
        tooltip: 'Nova Transação', // Novo tooltip
        child: const Icon(Icons.add),
      ),
    );
  }
}