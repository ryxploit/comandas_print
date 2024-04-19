// ignore_for_file: avoid_print

import 'dart:async';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: Colors.pink,
        hintColor: Colors.grey,
        textTheme: const TextTheme(
          // ignore: deprecated_member_use
          headline6: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          // ignore: deprecated_member_use
          bodyText2: TextStyle(fontSize: 16),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const PantallaPrincipal(),
    );
  }
}

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({Key? key}) : super(key: key);

  @override
  _PantallaPrincipalState createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  late Database _database;

  String _info = "";
  String _msj = '';
  bool conectado = false;
  List<BluetoothInfo> items = [];
  final List<String> _opciones = [
    "permiso de bluetooth concedido",
    "bluetooth habilitado",
    "estado de conexión",
    "actualizar información"
  ];
  bool _progreso = false;
  String _msjProgreso = "";
  String tipoImpresion = "58 mm";
  List<String> opciones = ["58 mm", "80 mm"];
  String comandoSeleccionado = "Comando Predeterminado";

  @override
  void initState() {
    super.initState();
    inicializarEstadoPlataforma();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    try {
      _database = await openDatabase(
        path.join(await getDatabasesPath(), 'comanda_database.db'),
        onCreate: (db, version) async {
          try {
            await db.execute(
              "CREATE TABLE IF NOT EXISTS categorias(id INTEGER PRIMARY KEY, nombre TEXT)",
            );
            await db.execute(
              "CREATE TABLE IF NOT EXISTS articulos(id INTEGER PRIMARY KEY, nombre TEXT, idCategoria INTEGER)",
            );
          } catch (e) {
            print('Error creating tables: $e');
          }
        },
        version: 1,
      );
    } catch (e) {
      print('Error initializing database: $e');
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gong cha',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.pink,
        actions: [
          PopupMenuButton(
            elevation: 3.2,
            onCanceled: () {
              print('No has seleccionado nada');
            },
            tooltip: 'Menú',
            onSelected: (Object seleccion) async {
              // ... (sin cambios)
            },
            itemBuilder: (BuildContext context) {
              return _opciones.map((String opcion) {
                return PopupMenuItem(
                  value: opcion,
                  child: Text(opcion),
                );
              }).toList();
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Información: $_info\n ',
                  style: Theme.of(context).textTheme.headline6),
              Text(_msj),
              Row(
                children: [
                  const Text("Tipo de impresión",
                      style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: tipoImpresion,
                    items: opciones.map((String opcion) {
                      return DropdownMenuItem<String>(
                        value: opcion,
                        child: Text(opcion),
                      );
                    }).toList(),
                    onChanged: (String? nuevoValor) {
                      setState(() {
                        tipoImpresion = nuevoValor!;
                      });
                    },
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      obtenerDispositivosBluetooth();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                    ),
                    child: Row(
                      children: [
                        Visibility(
                          visible: _progreso,
                          child: const SizedBox(
                            width: 25,
                            height: 25,
                            child: CircularProgressIndicator.adaptive(
                              strokeWidth: 1,
                              backgroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _progreso ? _msjProgreso : "Buscar",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: conectado ? desconectar : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                    ),
                    child: const Text(
                      "Desconectar",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: conectado
                        ? () => navegarAPantallaImpresion(context)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                    ),
                    child: const Text(
                      "Ir a Comandas",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  color: Colors.grey.withOpacity(0.3),
                ),
                child: ListView.builder(
                  itemCount: items.isNotEmpty ? items.length : 0,
                  itemBuilder: (context, index) {
                    return Card(
                      elevation: 3,
                      child: ListTile(
                        onTap: () {
                          String mac = items[index].macAdress;
                          conectar(mac);
                        },
                        title: Text('Nombre: ${items[index].name}',
                            style: const TextStyle(fontSize: 18)),
                        subtitle: Text(
                            "Dirección MAC: ${items[index].macAdress}",
                            style: const TextStyle(fontSize: 14)),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> inicializarEstadoPlataforma() async {
    try {
      String versionPlataforma = await PrintBluetoothThermal.platformVersion;

      print("versión de la plataforma: $versionPlataforma");
      int porcentajeBateria = await PrintBluetoothThermal.batteryLevel;

      if (!mounted) return;

      final bool resultado = await PrintBluetoothThermal.bluetoothEnabled;

      print("bluetooth habilitado: $resultado");
      if (resultado) {
        _msj = "Bluetooth habilitado, por favor busca y conecta";
      } else {
        _msj = "Bluetooth no habilitado";
      }

      setState(() {
        _info = "$versionPlataforma ($porcentajeBateria% batería)";
      });
    } on PlatformException {
      _info = 'Error al obtener la versión de la plataforma.';
    }
  }

  Future<void> obtenerDispositivosBluetooth() async {
    setState(() {
      _progreso = true;
      _msjProgreso = "Espera";
      items = [];
    });
    final List<BluetoothInfo> listaResultados =
        await PrintBluetoothThermal.pairedBluetooths;

    setState(() {
      _progreso = false;
    });

    if (listaResultados.isEmpty) {
      _msj =
          "No hay dispositivos Bluetooth vinculados. Ve a configuración y vincula la impresora.";
    } else {
      _msj = "Toca un elemento en la lista para conectar";
    }

    setState(() {
      items = listaResultados;
    });
  }

  Future<void> conectar(String mac) async {
    setState(() {
      _progreso = true;
      _msjProgreso = "Conectando...";
      conectado = false;
    });
    final bool resultado =
        await PrintBluetoothThermal.connect(macPrinterAddress: mac);

    print("estado de conexión $resultado");
    if (resultado) conectado = true;
    setState(() {
      _progreso = false;
    });
  }

  Future<void> desconectar() async {
    final bool estado = await PrintBluetoothThermal.disconnect;
    setState(() {
      conectado = false;
    });

    print("estado de desconexión $estado");
  }

  void navegarAPantallaImpresion(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PantallaImpresion()),
    );
  }
}

class PantallaImpresion extends StatelessWidget {
  const PantallaImpresion({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MiPantallaComanda(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MiPantallaComanda extends StatefulWidget {
  @override
  _MiPantallaComandaState createState() => _MiPantallaComandaState();
}

class _MiPantallaComandaState extends State<MiPantallaComanda> {
  List<Map<String, dynamic>> _categorias = [];
  Map<String, List<Map<String, dynamic>>> _datos = {};
  Map<String, int> _seleccionados = {};

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<Database> _initializeDatabase() async {
    try {
      final Future<Database> database = openDatabase(
        path.join(await getDatabasesPath(), 'comanda_database.db'),
        onCreate: (db, version) async {
          try {
            await db.execute(
              "CREATE TABLE IF NOT EXISTS categorias(id INTEGER PRIMARY KEY, nombre TEXT)",
            );
            await db.execute(
              "CREATE TABLE IF NOT EXISTS articulos(id INTEGER PRIMARY KEY, nombre TEXT, idCategoria INTEGER)",
            );
            await _actualizarEstructuraTablaArticulos(db);
          } catch (e) {
            print('Error creating tables: $e');
          }
        },
        version: 1,
      );

      final db = await database;
      final categorias = await db.query('categorias');

      setState(() {
        _categorias = List<Map<String, dynamic>>.from(categorias);
      });

      await _loadArticles(db);
      return db;
    } catch (e) {
      print('Error al inicializar la base de datos: $e');
      throw e;
    }
  }

  void _confirmDelete(BuildContext context, Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirmación"),
          content: Text("¿Estás seguro de que deseas eliminar este artículo?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                _deleteItem(item);
                Navigator.of(context).pop();
              },
              child: Text("Eliminar"),
            ),
          ],
        );
      },
    );
  }

  void _deleteItem(Map<String, dynamic> item) async {
    try {
      final db = await _initializeDatabase();
      await db.delete(
        'articulos',
        where: 'id = ?',
        whereArgs: [item['id']],
      );
      await db.close();
      _loadArticles(await _initializeDatabase());
    } catch (e) {
      print('Error al eliminar el artículo: $e');
    }
  }

  Future<void> _actualizarEstructuraTablaArticulos(Database db) async {
    try {
      await db.execute(
        "ALTER TABLE articulos ADD COLUMN sku TEXT",
      );
      print('Estructura de la tabla articulos actualizada correctamente.');
    } catch (e) {
      print('Error al actualizar la estructura de la tabla articulos: $e');
    }
  }

  Future<void> _loadArticles(Database db) async {
    try {
      _datos.clear();
      for (final categoria in _categorias) {
        final nombreCategoria = categoria['nombre'].toString();
        final articulos = await db.query(
          'articulos',
          where: 'idCategoria = ?',
          whereArgs: [categoria['id']],
        );
        setState(() {
          _datos[nombreCategoria] =
              List<Map<String, dynamic>>.from(articulos ?? []);
        });
      }
    } catch (e) {
      print('Error loading articles: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mi Comanda'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () {
                _mostrarAgregarDatosScreen(context);
              },
              child: Text('Agregar Datos'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final articulosSeleccionados = _datos.values
                    .expand((e) => e)
                    .where((item) =>
                        (_seleccionados[item['sku'].toString()] ?? 0) > 0)
                    .toList();
                _imprimirComanda(articulosSeleccionados);
              },
              child: Text('Imprimir Comanda'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _mostrarConfirmacionBorrado(context);
              },
              child: Text('Borrar Base de Datos'),
            ),
            SizedBox(height: 20),
            if (_datos.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _datos.entries.map((entry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Column(
                        children: entry.value.map((item) {
                          final sku = item['sku'].toString();
                          final cantidadSeleccionada = _seleccionados[sku] ?? 0;
                          return Column(
                            children: [
                              ListTile(
                                title: Text(item['nombre'].toString()),
                                subtitle: Text(sku),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.remove),
                                      onPressed: () {
                                        setState(() {
                                          if (cantidadSeleccionada > 0) {
                                            _seleccionados[sku] =
                                                cantidadSeleccionada - 1;
                                          }
                                        });
                                      },
                                    ),
                                    Text(cantidadSeleccionada.toString()),
                                    IconButton(
                                      icon: Icon(Icons.add),
                                      onPressed: () {
                                        setState(() {
                                          _seleccionados[sku] =
                                              cantidadSeleccionada + 1;
                                        });
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete),
                                      onPressed: () {
                                        _confirmDelete(context, item);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              Divider(),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _borrarBaseDeDatos() async {
    try {
      // Obtiene la ruta de la base de datos
      //String path = await getDatabasesPath();
      String databasePath =
          path.join(await getDatabasesPath(), 'comanda_database.db');

      // Borra la base de datos si existe
      bool exists = await databaseExists(databasePath);
      if (exists) {
        await deleteDatabase(databasePath);
        print('Base de datos borrada exitosamente.');
      } else {
        print('La base de datos no existe.');
      }
    } catch (e) {
      print('Error al borrar la base de datos: $e');
      throw e;
    }
  }

  _mostrarConfirmacionBorrado(BuildContext context) {
    TextEditingController _controller = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar Borrado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'Introduce la contraseña para confirmar el borrado de la base de datos:'),
              TextField(
                controller: _controller,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Contraseña',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                String password = _controller.text;
                if (password == 'mcl4r3n650s') {
                  _borrarBaseDeDatos();
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        'Contraseña incorrecta. Por favor, inténtalo de nuevo.'),
                  ));
                }
              },
              child: Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  void _mostrarAgregarDatosScreen(BuildContext context) async {
    final nuevosDatos = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AgregarDatosScreen(
          categoriasExistencias: _getCategoriasExistencias(),
          onDatosGuardados: _onDatosGuardados,
        ),
      ),
    );

    if (nuevosDatos != null) {
      _loadArticles(await _initializeDatabase());
    }
  }

  List<String> _getCategoriasExistencias() {
    return _categorias
        .map((categoria) => categoria['nombre'].toString())
        .toList();
  }

  void _onDatosGuardados() async {
    await _loadArticles(await _initializeDatabase());
  }

  void _imprimirComanda(
      List<Map<String, dynamic>> articulosSeleccionados) async {
    try {
      Map<String, int> cantidadPorSKU = {};

      // Aggregate quantities of each item
      for (var articulo in articulosSeleccionados) {
        String sku = articulo["sku"].toString();
        cantidadPorSKU[sku] =
            (cantidadPorSKU[sku] ?? 0) + (_seleccionados[sku] ?? 0);
      }

      bool estadoConexion = await PrintBluetoothThermal.connectionStatus;

      if (estadoConexion) {
        List<int> ticket = await pruebaTicket(cantidadPorSKU);
        final resultado = await PrintBluetoothThermal.writeBytes(ticket);

        print("Resultado de la impresión de la comanda: $resultado");

        // Reset selected quantities to zero after printing
        setState(() {
          _seleccionados.clear();
        });
      } else {
        print(
            "La impresora no está conectada. Vuelve a conectar o muestra un mensaje de error.");
      }
    } catch (e) {
      print('Error al imprimir la comanda: $e');
    }
  }
}

Future<List<int>> pruebaTicket(Map<String, int> cantidadPorSKU) async {
  List<int> bytes = [];

  final perfil = await CapabilityProfile.load();
  var tipoImpresion;
  final generador = Generator(
    tipoImpresion == "58 mm" ? PaperSize.mm58 : PaperSize.mm80,
    perfil,
  );

  bytes += generador.reset();

  bytes += generador.text('GONG CHA LIVERPOOL MAZATLAN',
      styles: const PosStyles(
        align: PosAlign.center,
        fontType: PosFontType.fontA,
      ));
  bytes += generador.feed(2);
  bytes += generador.text('Artículos Seleccionados:',
      styles: const PosStyles(bold: true));

  // Loop through the SKU quantities map
  cantidadPorSKU.forEach((sku, cantidad) {
    for (var i = 0; i < cantidad; i++) {
      bytes += generador.text('SKU: $sku');
      bytes += generador.barcode(Barcode.itf(sku.split('')));
      bytes.add(10); // Add line feed
    }
  });

  bytes += generador.feed(2);
  bytes += generador.cut();

  return bytes;
}

class AgregarDatosScreen extends StatefulWidget {
  final List<String> categoriasExistencias;
  final VoidCallback onDatosGuardados;

  AgregarDatosScreen({
    required this.categoriasExistencias,
    required this.onDatosGuardados,
  });

  @override
  _AgregarDatosScreenState createState() => _AgregarDatosScreenState();
}

class _AgregarDatosScreenState extends State<AgregarDatosScreen> {
  TextEditingController _controllerCategoria = TextEditingController();
  TextEditingController _controllerNombre = TextEditingController();
  TextEditingController _controllerSKU = TextEditingController();
  String _selectedCategoria = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Agregar Datos'),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value:
                        _selectedCategoria.isEmpty ? null : _selectedCategoria,
                    items: widget.categoriasExistencias
                        .map((categoria) => DropdownMenuItem(
                              child: Text(categoria),
                              value: categoria,
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategoria = value!;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Categoría',
                    ),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _agregarNuevaCategoria,
                  child: Text('Agregar Nueva'),
                ),
              ],
            ),
            SizedBox(height: 20),
            TextField(
              controller: _controllerNombre,
              decoration: InputDecoration(labelText: 'Nombre del Artículo'),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _controllerSKU,
              decoration: InputDecoration(labelText: 'SKU'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _guardarDatos();
              },
              child: Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _agregarNuevaCategoria() async {
    final nuevaCategoria = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Nueva Categoría'),
          content: TextField(
            controller: _controllerCategoria,
            decoration: InputDecoration(labelText: 'Nombre de la Categoría'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(_controllerCategoria.text.trim());
              },
              child: Text('Agregar'),
            ),
          ],
        );
      },
    );

    if (nuevaCategoria != null && nuevaCategoria.isNotEmpty) {
      try {
        final db = await _openDatabase();
        final result = await db.rawQuery(
          'SELECT id FROM categorias WHERE nombre = ?',
          [nuevaCategoria],
        );

        int categoriaId;

        if (result.isNotEmpty) {
          categoriaId = result.first['id'] as int;
        } else {
          categoriaId = await db.rawInsert(
            'INSERT INTO categorias(nombre) VALUES(?)',
            [nuevaCategoria],
          );
        }

        await db.close();

        setState(() {
          widget.categoriasExistencias.add(nuevaCategoria);
          _selectedCategoria = nuevaCategoria;
        });
      } catch (e) {
        print('Error al agregar nueva categoría: $e');
      }
    }
  }

  void _guardarDatos() async {
    if (_selectedCategoria.isEmpty ||
        _controllerNombre.text.trim().isEmpty ||
        _controllerSKU.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, completa todos los campos')),
      );
      return;
    }

    try {
      final db = await _openDatabase();
      final categoriaId = await _getCategoriaId(db, _selectedCategoria);

      await db.rawInsert(
        'INSERT INTO articulos(nombre, sku, idCategoria) VALUES(?, ?, ?)',
        [
          _controllerNombre.text.trim(),
          _controllerSKU.text.trim(),
          categoriaId
        ],
      );

      await db.close();

      _selectedCategoria = '';
      _controllerNombre.clear();
      _controllerSKU.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Los datos fueron guardados correctamente')),
      );

      widget.onDatosGuardados();

      Navigator.pop(context);
    } catch (e) {
      print('Error al guardar los datos: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ocurrió un error al guardar los datos')),
      );
    }
  }

  Future<Database> _openDatabase() async {
    return openDatabase(
      path.join(await getDatabasesPath(), 'comanda_database.db'),
      onCreate: (db, version) async {
        try {
          await db.execute(
            "CREATE TABLE IF NOT EXISTS categorias(id INTEGER PRIMARY KEY, nombre TEXT)",
          );
          await db.execute(
            "CREATE TABLE IF NOT EXISTS articulos(id INTEGER PRIMARY KEY, nombre TEXT, sku TEXT, idCategoria INTEGER)",
          );
        } catch (e) {
          print('Error creating tables: $e');
        }
      },
      version: 1,
    );
  }

  Future<int> _getCategoriaId(Database db, String categoriaNombre) async {
    final result = await db.rawQuery(
      'SELECT id FROM categorias WHERE nombre = ?',
      [categoriaNombre],
    );
    if (result.isNotEmpty) {
      return result.first['id'] as int;
    } else {
      throw Exception(
          'La categoría seleccionada no existe en la base de datos.');
    }
  }
}
