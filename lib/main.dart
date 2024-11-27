import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();



  Future<void> PagamentoEAtualizar(String cpf, String metodoPagamento, double valorTotal) async {
  final db = await database;

  // Registrar o pagamento
  int pagamentoId = await db.insert('Pagamentos', {
    'cpf': cpf,
    'metodoPagamento': metodoPagamento,
    'valorTotal': valorTotal,
    'data': DateTime.now().toIso8601String(),
  });

  // Atualizar o carrinho
  await db.rawUpdate(
    '''
    UPDATE Carrinho 
    SET idPagamento = ?, quantidadeEscolhida = 0 
    WHERE cpf = ? AND idPagamento IS NULL
    ''',
    [pagamentoId, cpf],
  );
}

  Future<void> atualizarEstoque(int idOferta, int quantidade) async {
  final db = await database;
  await db.rawUpdate(
    'UPDATE Oferta SET quantidadeEmEstoque = quantidadeEmEstoque - ? WHERE id = ?',
    [quantidade, idOferta],
  );
}

  Future<void> aumentaEstoque(int idOferta, int quantidade) async {
  final db = await database;
  await db.rawUpdate(
    'UPDATE Oferta SET quantidadeEmEstoque = quantidadeEmEstoque + ? WHERE id = ?',
    [quantidade, idOferta],
  );
}


  Future<void> salvarNoCarrinho(Map<String, dynamic> oferta, int quantidade, String cpf) async {
  final db = await database;
  await db.insert('Carrinho', {
    'idOferta': oferta['id'],
    'quantidadeEscolhida': quantidade,
    'pago': 0,
    'cpf': cpf, // Adicionando o CPF
  });
}

  Future<void> atualizaCarrinho(int idcarrinho) async {
  final db = await database;
  await db.rawUpdate(
    "UPDATE Carrinho SET quantidadeEscolhida = 0 WHERE id = ?",
    [idcarrinho],
  );

}


  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('app_database.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final path = join("Porjetos/project", filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE User (
        cpf TEXT PRIMARY KEY,
        senha TEXT NOT NULL,
        email TEXT NOT NULL,
        nome TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE Oferta (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        produto TEXT NOT NULL,
        preco REAL NOT NULL,
        quantidadeEmEstoque INTEGER NOT NULL,
        produtor TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE Carrinho (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        idOferta INTEGER NOT NULL,
        quantidadeEscolhida INTEGER NOT NULL,
        pago INTEGER NOT NULL,
        FOREIGN KEY (idOferta) REFERENCES Oferta (id)
      );
    ''');
  }

  Future<void> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    await db.insert('User', user);
  }

  Future<void> insertOferta(Map<String, dynamic> oferta) async {
    final db = await database;
    await db.insert('Oferta', oferta);
  }

  Future<List<Map<String, dynamic>>> getOfertas() async {
    final db = await database;
    return await db.rawQuery('''
    SELECT * FROM Oferta WHERE quantidadeEmEstoque > 0
  ''');
  }

Future<List<Map<String, dynamic>>> getCarrinho() async {
  final db = await database;
  // Realiza uma junção entre as tabelas 'Carrinho' e 'Oferta'
  return await db.rawQuery('''
    SELECT c.*, o.produto, o.preco, o.quantidadeEmEstoque, o.produtor 
    FROM Carrinho c
    JOIN Oferta o ON c.idOferta = o.id
    WHERE quantidadeEscolhida > 0 AND pago = 0
  ''');
}

  Future<List<Map<String, dynamic>>> getPagamento() async {
    final db = await database;
    // Realiza uma junção entre as tabelas 'Pagamento' e 'Carrinho'
    return await db.rawQuery('''
      SELECT * 
      FROM Pagamentos 
      WHERE valorTotal > 0
    ''');
  }
  

  Future<bool> validaLogin(String cpf, String senha) async {
    final db = await database;
    final result = await db.query(
      'User',
      where: 'cpf = ? AND senha = ?',
      whereArgs: [cpf, senha],
    );
    return result.isNotEmpty;
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}

void main() async {
  // Inicialização condicional para desktop
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(const BioHarvestApp());
}

class BioHarvestApp extends StatelessWidget {
  const BioHarvestApp({super.key});
  
  @override
  
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => LoginPage(),
        '/ofertas': (context) => OfertasPage(),
        '/carrinho': (context) => CarrinhosPage(),
        '/pagamentos': (context) => Pagamentospage(),

      },
    );
  }
}

class LoginPage extends StatelessWidget {
  final TextEditingController cpfController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();
  
  LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDDE4D4),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundImage: AssetImage('assets/logo.png'),
                backgroundColor: Colors.transparent,
              ),
              const SizedBox(height: 20),
              const Text(
                'BioHarvest',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'LOGIN',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: cpfController,
                decoration: InputDecoration(
                  labelText: 'CPF / CNPJ (Apenas Números)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 15),
              TextField(
                controller: senhaController,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  
                  //String dbPath = await getDatabasesPath();
                  //print("Caminho do banco de dados: $dbPath");

                  
                  String cpf = cpfController.text;
                  String senha = senhaController.text;

                  bool isValid = await DatabaseHelper.instance.validaLogin(cpf, senha);

                  if (isValid) {
                    Navigator.pushNamed(context, '/ofertas',arguments: cpf );// Passando o CPF para a página de ofertas
                  } else {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Erro de Login'),
                        content: const Text('CPF ou Senha incorretos!'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Entrar',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Ainda não possuo uma conta',
                  style: TextStyle(fontSize: 18, color: Color.fromARGB(255, 80, 80, 80)),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Esqueci minha senha',
                  style: TextStyle(fontSize: 18, color: Color.fromARGB(255, 80, 80, 80)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OfertasPage extends StatefulWidget {
  const OfertasPage({super.key});
  
  @override
  State<OfertasPage> createState() => _OfertasPageState();
}

class _OfertasPageState extends State<OfertasPage> {

  
  String filtroAtual = ''; // Filtro inicial (vazio para exibir todas as ofertas)
  late Future<List<Map<String, dynamic>>> ofertasFuturas;

  @override
  void initState() {
    super.initState();
    ofertasFuturas = DatabaseHelper.instance.getOfertas();
  }

  @override
  Widget build(BuildContext context) {
  final String cpf = ModalRoute.of(context)?.settings.arguments as String; // Pegando o CPF

    return Scaffold(
      backgroundColor: const Color(0xFFDDE4D4),
      appBar: AppBar(
        title: const Text('BioHarvest'),
        
        leading: IconButton(
          icon: Icon(Icons.menu), 
          onPressed: () {
            Navigator.pushNamed(context, '/pagamentos',arguments: cpf ); // Navegar para a página de pagamentos
          },
        ),  // Remover a seta (ícone do Drawer)
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.pushNamed(context, '/carrinho',arguments: cpf ); // Navegar para a página do carrinho
            },
          ),
          TextButton(
            onPressed: () {
              // Logout
            },
            child: const Text(
              'Log Off',
              style: TextStyle(color: Color.fromARGB(255, 80, 80, 80)),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Campo de filtro
            const Text(
              'Filtro',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
                
              dropdownColor: Colors.white,
              value: filtroAtual.isEmpty ? null : filtroAtual,
              
              hint: const Text('Selecione um filtro'),
              items: ['Tomate', 'Batata', 'Cenoura', 'Todos']
                  .map((item) => DropdownMenuItem(
                        value: item,
                        child: Text(item),
                      ))
                  .toList(),
                  
              onChanged: (value) {
                setState(() {
                  filtroAtual = value == 'Todos' ? '' : value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Título de Ofertas
            const Text(
              'Ofertas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Listagem de Ofertas
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: ofertasFuturas,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return const Center(child: Text('Erro ao carregar ofertas'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('Sem ofertas disponíveis'));
                  }

                  // Filtrar as ofertas pelo filtro selecionado
                  List<Map<String, dynamic>> ofertas = snapshot.data!;
                  if (filtroAtual.isNotEmpty) {
                    ofertas = ofertas
                        .where((oferta) =>
                            oferta['produto']
                                .toString()
                                .toLowerCase()
                                .contains(filtroAtual.toLowerCase()))
                        .toList();
                  }

                  if (ofertas.isEmpty) {
                    return const Center(child: Text('Nenhuma oferta encontrada'));
                  }

                  return ListView.builder(
                    itemCount: ofertas.length,
                    itemBuilder: (context, index) {
                      final oferta = ofertas[index];
                      return Card(
                        color: const Color(0xFFF8F8F8),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                oferta['produto'],
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text('Produtor: ${oferta['produtor']}'),
                              const SizedBox(height: 8),
                              Text('Preço: R\$ ${(oferta['preco'] as double).toStringAsFixed(2)}'),
                              const SizedBox(height: 8),
                              Text('Quantidade em estoque: ${oferta['quantidadeEmEstoque']}'),
                              const SizedBox(height: 16),
                              Center(
                                child: ElevatedButton(
                                  onPressed: () {
                                    _adicionarAoCarrinho(context, oferta);

                                    setState(() {
                                      ofertasFuturas = DatabaseHelper.instance.getOfertas();
                                      });
                                  },
                                  child: const Text('Adicionar ao Carrinho'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _adicionarAoCarrinho(BuildContext context, Map<String, dynamic> oferta) async {
    int quantidadeSelecionada = 1;
    int estoque = oferta['quantidadeEmEstoque'];
    final String cpf = ModalRoute.of(context)?.settings.arguments as String; // Pegando o CPF


    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Adicionar ao Carrinho'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Produto: ${oferta['produto']}'),
                  const SizedBox(height: 8),
                  Text('Estoque disponível: $estoque'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          if (quantidadeSelecionada > 1) {
                            setState(() {
                              quantidadeSelecionada--;
                            });
                          }
                        },
                        icon: const Icon(Icons.remove),
                      ),
                      Text('$quantidadeSelecionada'),
                      IconButton(
                        onPressed: () {
                          if (quantidadeSelecionada < estoque) {
                            setState(() {
                              quantidadeSelecionada++;
                            });
                          }
                        },
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Atualizar o estoque
                    await DatabaseHelper.instance.atualizarEstoque(oferta['id'], quantidadeSelecionada);

                    // Salvar no carrinho com CPF
                  await DatabaseHelper.instance.salvarNoCarrinho(oferta, quantidadeSelecionada, cpf);

                  

                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Item adicionado ao carrinho!')),
                    );
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class CarrinhosPage extends StatefulWidget {
  const CarrinhosPage({super.key});
  
  @override
  State<CarrinhosPage> createState() => _CarrinhosPageSate();
}

class _CarrinhosPageSate extends State<CarrinhosPage> {

  
  late Future<List<Map<String, dynamic>>> carrinhoFuturo;

  @override
  void initState() {
    super.initState();
    carrinhoFuturo = DatabaseHelper.instance.getCarrinho();
  }

  @override
  Widget build(BuildContext context) {
    
    final String cpf = ModalRoute.of(context)?.settings.arguments as String; // Pegando o CPF

    return Scaffold(
      backgroundColor: const Color(0xFFDDE4D4),
      appBar: AppBar(
        title: const Text('BioHarvest'),
        
        leading: IconButton(
          icon: Icon(Icons.menu), 
          onPressed: () {
            Navigator.pushNamed(context, '/pagamentos',arguments: cpf ); // Navegar para a página de pagamentos
          },
        ),  // Remover a seta (ícone do Drawer)
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag),
            onPressed: () {
              Navigator.pushNamed(context, '/ofertas',arguments: cpf ); // Navegar para a página de compra
            },
          ),
          TextButton(
            onPressed: () {
              // Logout
            },
            child: const Text(
              'Log Off',
              style: TextStyle(color: Color.fromARGB(255, 80, 80, 80)),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        
            // Título de Carrinho
            const Text(
              'Carrinho',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
                  onPressed: () {
                    _pagamento(context);
                  },
                  style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Avançar para o Pagamento',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                                ),
            const SizedBox(height: 16),

            // Listagem de Ofertas
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: carrinhoFuturo,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return const Center(child: Text('Erro ao carregar carrinho'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('Carrinho Vazio'));
                  }

                  //Filtra os carrinhos do CPF
                  List<Map<String, dynamic>> carrinho = snapshot.data!;
                  
                    carrinho = carrinho
                        .where((carrinho) =>
                            carrinho['cpf']
                                .toString()
                                .contains(cpf))
                        .toList();
                  

                  return ListView.builder(
                    itemCount: carrinho.length,
                    itemBuilder: (context, index) {
                      final carrinhos = carrinho[index];
                      return Card(
                        color: const Color(0xFFF8F8F8),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                carrinhos['produto'],
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                )
                              ),
                              const SizedBox(height: 8),
                              Text('Preço Unitário: R\$ ${(carrinhos['preco'] as double).toStringAsFixed(2)}'),
                              const SizedBox(height: 8),
                              Text('Quantidade: ${(carrinhos['quantidadeEscolhida'] as int).toStringAsFixed(2)}'),
                              const SizedBox(height: 8),
                              Text('Total: R\$ ${((carrinhos['quantidadeEscolhida'] as int)*(carrinhos['preco'] as double)).toStringAsFixed(2)}'),
                              const SizedBox(height: 8),
                              
                              Center(
                                child: ElevatedButton(
                                  onPressed: () async {
                                  // Atualizar o estoque
                                  await DatabaseHelper.instance.aumentaEstoque(carrinhos['idOferta'], carrinhos['quantidadeEscolhida']);

                                    // Remove do Carrinho
                                  await DatabaseHelper.instance.atualizaCarrinho(carrinhos['id']);

                                  setState(() {
                                    carrinhoFuturo = DatabaseHelper.instance.getCarrinho();
                                  });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Itens removidos do carrinho!')),
                                    );
                                  },
                                  child: const Text('Remover do Carrinho'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _pagamento(BuildContext context) async {
    final String cpf = ModalRoute.of(context)?.settings.arguments as String;

    String metodoPagamento = 'Cartão de Crédito';
    double valorTotal = 0.0;

    // Recuperar carrinho e calcular valor total
    List<Map<String, dynamic>> carrinho = await DatabaseHelper.instance.getCarrinho();
    carrinho = carrinho.where((c) => c['cpf'].toString() == cpf).toList();
    valorTotal = carrinho.fold(0.0, (total, item) {
      return total + (item['quantidadeEscolhida'] as int) * (item['preco'] as double);
    });

    // Exibir o pop-up
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Registrar Pagamento'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Valor Total: R\$ ${valorTotal.toStringAsFixed(2)}'),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: metodoPagamento,
                    onChanged: (value) {
                      setState(() {
                        metodoPagamento = value!;
                      });
                    },
                    items: const [
                      DropdownMenuItem(
                        value: 'Cartão de Crédito',
                        child: Text('Cartão de Crédito'),
                      ),
                      DropdownMenuItem(
                        value: 'Cartão de Débito',
                        child: Text('Cartão de Débito'),
                      ),
                      DropdownMenuItem(
                        value: 'Pix',
                        child: Text('Pix'),
                      ),
                      DropdownMenuItem(
                        value: 'Dinheiro',
                        child: Text('Dinheiro'),
                      ),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Método de Pagamento',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Registrar pagamento e atualizar carrinho
                    await DatabaseHelper.instance.PagamentoEAtualizar(cpf, metodoPagamento, valorTotal);

                    // Atualizar o estado da página
                    setState(() {
                      carrinhoFuturo = DatabaseHelper.instance.getCarrinho();
                    });

                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Pagamento registrado com sucesso!')),
                    );
                  },
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );
    }
  
  }

class Pagamentospage extends StatefulWidget {
  const Pagamentospage({super.key});
  
  @override
  State<Pagamentospage> createState() => _PagamentoPageState();
}

class _PagamentoPageState extends State<Pagamentospage> {

  
  late Future<List<Map<String, dynamic>>> pagamentosf;

  @override
  void initState() {
    super.initState();
    pagamentosf = DatabaseHelper.instance.getPagamento();
  }

  @override
  Widget build(BuildContext context) {
    
    final String cpf = ModalRoute.of(context)?.settings.arguments as String; // Pegando o CPF

    return Scaffold(
      backgroundColor: const Color(0xFFDDE4D4),
      appBar: AppBar(
        title: const Text('BioHarvest'),
        
        leading: IconButton(
          icon: Icon(Icons.menu), 
          onPressed: () {
             Navigator.pushNamed(context, '/pagamentos',arguments: cpf ); // Navegar para a página de pagamentos
          },
        ),  // Remover a seta (ícone do Drawer)
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag),
            onPressed: () {
              Navigator.pushNamed(context, '/ofertas',arguments: cpf ); // Navegar para a página de compra
            },
          ),
          TextButton(
            onPressed: () {
              // Logout
            },
            child: const Text(
              'Log Off',
              style: TextStyle(color: Color.fromARGB(255, 80, 80, 80)),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        
            // Título
            const Text(
              'Pagamentos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: pagamentosf,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return const Center(child: Text('Erro ao carregar pagamentos'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('Não encontrado pagamentos'));
                  }

                  //Filtra os pagamentos do CPF
                  List<Map<String, dynamic>> pagamentos = snapshot.data!;
                  
                    pagamentos = pagamentos
                        .where((pagamentos) =>
                            pagamentos['cpf']
                                .toString()
                                .contains(cpf))
                        .toList();
                  

                  return ListView.builder(
                    itemCount: pagamentos.length,
                    itemBuilder: (context, index) {
                      final pagamento = pagamentos[index];
                      return Card(
                        color: const Color(0xFFF8F8F8),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pagamento['data'],
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                )
                              ),
                              const SizedBox(height: 8),
                              Text('Valor Total: R\$ ${(pagamento['valorTotal'] as int).toStringAsFixed(2)}'),
                              const SizedBox(height: 8),
                              Text('Metodo de Pagamento: ${pagamento['metodoPagamento']}'),
                              const SizedBox(height: 8),
                              
                              
                              
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  
  
  }
