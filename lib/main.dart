import 'dart:async';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://vouegedqhtzzmnnhgyxu.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZvdWVnZWRxaHR6em1ubmhneXh1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTYzOTk3NzIsImV4cCI6MjAzMTk3NTc3Mn0.8WTVtMsKMJIeYPYluv7ZbiKzt8N6iO4ajJM6pHnIn6I',
  );
  runApp(const MyApp());
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
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(fontSize: 16),
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
  final SupabaseClient supabase = Supabase.instance.client;

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
              // Aquí puede ir la lógica correspondiente
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
                  style: Theme.of(context).textTheme.titleLarge),
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
      setState(() {
        _info = 'Error al obtener la versión de la plataforma.';
      });
    }
  }

  Future<void> obtenerDispositivosBluetooth() async {
    try {
      setState(() {
        _progreso = true;
        _msjProgreso = "Espera";
        items = [];
      });
      final List<BluetoothInfo> listaResultados =
          await PrintBluetoothThermal.pairedBluetooths;

      setState(() {
        _progreso = false;
        if (listaResultados.isEmpty) {
          _msj =
              "No hay dispositivos Bluetooth vinculados. Ve a configuración y vincula la impresora.";
        } else {
          _msj = "Toca un elemento en la lista para conectar";
          items = listaResultados;
        }
      });
    } catch (e) {
      setState(() {
        _progreso = false;
        _msj = "Error al obtener dispositivos Bluetooth: $e";
      });
    }
  }

  Future<void> conectar(String mac) async {
    try {
      setState(() {
        _progreso = true;
        _msjProgreso = "Conectando...";
        conectado = false;
      });
      final bool resultado =
          await PrintBluetoothThermal.connect(macPrinterAddress: mac);

      setState(() {
        _progreso = false;
        conectado = resultado;
      });

      if (resultado) {
        print("Conectado exitosamente a $mac");
      } else {
        print("Falló la conexión a $mac");
      }
    } catch (e) {
      setState(() {
        _progreso = false;
        _msj = "Error al conectar: $e";
      });
    }
  }

  Future<void> desconectar() async {
    try {
      final bool estado = await PrintBluetoothThermal.disconnect;
      setState(() {
        conectado = false;
      });

      print("estado de desconexión $estado");
    } catch (e) {
      setState(() {
        _msj = "Error al desconectar: $e";
      });
    }
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
      theme: ThemeData(primaryColor: Colors.pink),
    );
  }
}

class MiPantallaComanda extends StatefulWidget {
  @override
  _MiPantallaComandaState createState() => _MiPantallaComandaState();
}

class _MiPantallaComandaState extends State<MiPantallaComanda> {
  final SupabaseClient supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _categorias = [];
  Map<String, List<Map<String, dynamic>>> _datos = {};
  List<Map<String, dynamic>> _carrito = [];
  Set<String> _expandedCategories = {};
  bool _isLoading = true; // Añadido para controlar el estado de carga

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadCategories();
    await _loadArticles();
    setState(() {
      _isLoading = false; // Datos cargados, se oculta el indicador de carga
    });
  }

  Future<void> _loadCategories() async {
    try {
      final response = await supabase.from('categorias').select();
      final categorias = response as List<dynamic>;

      setState(() {
        _categorias = categorias
            .map((categoria) => Map<String, dynamic>.from(categoria))
            .toList();
      });
    } catch (e) {
      print('Error al cargar categorías: $e');
    }
  }

  Future<void> _loadArticles() async {
    try {
      Map<String, List<Map<String, dynamic>>> newDatos = {};
      for (final categoria in _categorias) {
        final response = await supabase
            .from('articulos')
            .select()
            .eq('idCategoria', categoria['id']);
        final articulos = response as List<dynamic>;

        newDatos[categoria['nombre']] = articulos
            .map((articulo) => Map<String, dynamic>.from(articulo))
            .toList();
      }
      setState(() {
        _datos = newDatos;
      });
    } catch (e) {
      print('Error al cargar artículos: $e');
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
            ElevatedButton(
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
      await supabase.from('articulos').delete().eq('id', item['id']);
      _loadArticles();
    } catch (e) {
      print('Error al eliminar el artículo: $e');
    }
  }

  void _confirmDeleteCategoria(BuildContext context, String categoria) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirmación"),
          content: Text(
              "¿Estás seguro de que deseas eliminar esta categoría y todos sus artículos?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () {
                _deleteCategoria(categoria);
                Navigator.of(context).pop();
              },
              child: Text("Eliminar"),
            ),
          ],
        );
      },
    );
  }

  void _deleteCategoria(String categoria) async {
    try {
      final categoriaId = await _getCategoriaId(categoria);
      await supabase.from('categorias').delete().eq('nombre', categoria);
      await supabase.from('articulos').delete().eq('idCategoria', categoriaId);
      _loadCategories();
    } catch (e) {
      print('Error al eliminar la categoría: $e');
    }
  }

  Future<int> _getCategoriaId(String categoriaNombre) async {
    final response = await supabase
        .from('categorias')
        .select('id')
        .eq('nombre', categoriaNombre)
        .single();
    if (response != null) {
      return response['id'];
    } else {
      throw Exception(
          'La categoría seleccionada no existe en la base de datos.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('GongPrint'),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Colors.green,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Cargando información de la matrix...',
                    style: TextStyle(color: Colors.green),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            _mostrarAgregarArticuloScreen(context);
                          },
                          icon: Icon(
                            Icons.add,
                            color: Colors.pink,
                          ),
                          label: Text(
                            'Agregar Artículo',
                            style: TextStyle(color: Colors.pink),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                        SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: () {
                            _mostrarAgregarCategoriaScreen(context);
                          },
                          icon: Icon(Icons.add, color: Colors.pink),
                          label: Text(
                            'Agregar Categoría',
                            style: TextStyle(color: Colors.pink),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                        SizedBox(height: 20),
                        if (_datos.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: _datos.entries.map((entry) {
                              return ExpansionPanelList(
                                expansionCallback:
                                    (int index, bool isExpanded) {
                                  setState(() {
                                    _expandedCategories.contains(entry.key)
                                        ? _expandedCategories.remove(entry.key)
                                        : _expandedCategories.add(entry.key);
                                  });
                                },
                                children: [
                                  ExpansionPanel(
                                    headerBuilder: (BuildContext context,
                                        bool isExpanded) {
                                      return ListTile(
                                        title: Text(
                                          entry.key,
                                          style: TextStyle(
                                            color: Colors.pink,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        trailing: IconButton(
                                          icon: Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed: () {
                                            _confirmDeleteCategoria(
                                                context, entry.key);
                                          },
                                        ),
                                      );
                                    },
                                    body: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: entry.value.map((item) {
                                        return ListTile(
                                          title:
                                              Text(item['nombre'].toString()),
                                          subtitle: Text('SKU: ${item['sku']}'),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: Icon(
                                                  Icons.add_shopping_cart,
                                                  color: Colors.green,
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    _carrito.add(item);
                                                  });
                                                },
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.delete,
                                                  color: Colors.red,
                                                ),
                                                onPressed: () {
                                                  _confirmDelete(context, item);
                                                },
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                    isExpanded:
                                        _expandedCategories.contains(entry.key),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        SizedBox(height: 20),
                        Text(
                          'Carrito:',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        if (_carrito.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: _carrito.map((item) {
                              return ListTile(
                                title: Text(item['nombre'].toString()),
                                subtitle: Text('SKU: ${item['sku']}'),
                                trailing: IconButton(
                                  icon: Icon(
                                    Icons.remove_shopping_cart,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _carrito.remove(item);
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        if (_carrito.isEmpty)
                          Text(
                            'El carrito está vacío.',
                            style: TextStyle(color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _imprimirComanda(_carrito);
                          },
                          icon: Icon(
                            Icons.print,
                            color: Colors.white,
                          ),
                          label: Text(
                            'Imprimir Comanda',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 15),
                            backgroundColor: Colors.pink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  void _mostrarAgregarArticuloScreen(BuildContext context) async {
    final nuevosDatos = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AgregarArticuloScreen(
          categoriasExistencias: _getCategoriasExistencias(),
          onDatosGuardados: () async => await _onDatosGuardados(),
        ),
      ),
    );

    if (nuevosDatos != null) {
      _loadArticles();
    }
  }

  void _mostrarAgregarCategoriaScreen(BuildContext context) async {
    final nuevaCategoria = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AgregarCategoriaScreen(
          onCategoriaGuardada: () async => await _onDatosGuardados(),
        ),
      ),
    );

    if (nuevaCategoria != null) {
      _loadCategories();
    }
  }

  List<String> _getCategoriasExistencias() {
    return _categorias
        .map((categoria) => categoria['nombre'].toString())
        .toList();
  }

  Future<void> _onDatosGuardados() async {
    await _loadArticles();
    await _loadCategories();
  }

  void _imprimirComanda(List<Map<String, dynamic>> carrito) async {
    try {
      Map<String, int> cantidadPorSKU = {};

      for (var articulo in carrito) {
        String sku = articulo["sku"].toString();

        if (cantidadPorSKU.containsKey(sku)) {
          cantidadPorSKU[sku] = cantidadPorSKU[sku]! + 1;
        } else {
          cantidadPorSKU[sku] = 1;
        }
      }

      bool estadoConexion = await PrintBluetoothThermal.connectionStatus;

      if (estadoConexion) {
        List<int> ticket = await _generarTicket(carrito, cantidadPorSKU);
        final resultado = await PrintBluetoothThermal.writeBytes(ticket);

        print("Resultado de la impresión de la comanda: $resultado");

        setState(() {
          _carrito.clear();
        });
      } else {
        print(
            "La impresora no está conectada. Vuelve a conectar o muestra un mensaje de error.");
      }
    } catch (e) {
      print('Error al imprimir la comanda: $e');
    }
  }

  Future<List<int>> _generarTicket(List<Map<String, dynamic>> carrito,
      Map<String, int> cantidadPorSKU) async {
    List<int> bytes = [];

    final perfil = await CapabilityProfile.load();
    var tipoImpresion = "58 mm";
    final generador = Generator(
        tipoImpresion == "58 mm" ? PaperSize.mm58 : PaperSize.mm80, perfil);

    bytes += generador.reset();

    bytes += generador.text('GONG CHA LIVERPOOL MAZATLAN',
        styles: const PosStyles(
          align: PosAlign.center,
          fontType: PosFontType.fontA,
        ));
    bytes += generador.feed(2);
    bytes += generador.text('Artículos Seleccionados:',
        styles: const PosStyles(bold: true));

    // Utilizamos un set para asegurarnos de imprimir cada artículo correctamente
    Set<Map<String, dynamic>> articulosUnicos = carrito.toSet();
    for (var articulo in articulosUnicos) {
      String sku = articulo['sku'].toString();
      String nombre = articulo['nombre'].toString();
      int cantidad = cantidadPorSKU[sku] ?? 0;

      bytes += generador.text('$nombre ');
      bytes += generador.barcode(Barcode.itf(sku.split('')));
      bytes.add(10);
    }

    bytes += generador.feed(2);
    bytes += generador.cut();

    return bytes;
  }
}

class AgregarArticuloScreen extends StatefulWidget {
  final List<String> categoriasExistencias;
  final VoidCallback onDatosGuardados;

  AgregarArticuloScreen({
    required this.categoriasExistencias,
    required this.onDatosGuardados,
  });

  @override
  _AgregarArticuloScreenState createState() => _AgregarArticuloScreenState();
}

class _AgregarArticuloScreenState extends State<AgregarArticuloScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  TextEditingController _controllerNombre = TextEditingController();
  TextEditingController _controllerSKU = TextEditingController();
  String _selectedCategoria = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Agregar Artículo'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField(
              value: _selectedCategoria.isNotEmpty ? _selectedCategoria : null,
              items: widget.categoriasExistencias
                  .map((String categoria) => DropdownMenuItem(
                        value: categoria,
                        child: Text(categoria),
                      ))
                  .toList(),
              onChanged: (String? value) {
                setState(() {
                  _selectedCategoria = value!;
                });
              },
              decoration: InputDecoration(
                labelText: 'Selecciona una Categoría',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _controllerNombre,
              decoration: InputDecoration(
                labelText: 'Nombre del Artículo',
                hintText: 'Escribe el nombre del artículo',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _controllerSKU,
              decoration: InputDecoration(
                labelText: 'SKU',
                hintText: 'Escribe el código SKU',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _guardarArticulo();
              },
              child: Text('Guardar Artículo'),
            ),
          ],
        ),
      ),
    );
  }

  void _guardarArticulo() async {
    try {
      final nombre = _controllerNombre.text.trim();
      final sku = _controllerSKU.text.trim();

      if (_selectedCategoria.isNotEmpty &&
          nombre.isNotEmpty &&
          sku.isNotEmpty) {
        final categoriaId = await _getCategoriaId(_selectedCategoria);
        await supabase.from('articulos').insert({
          'nombre': nombre,
          'idCategoria': categoriaId,
          'sku': sku,
        });

        _limpiarCampos();
        widget.onDatosGuardados();
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Por favor, asegúrate de completar todos los campos antes de guardar los datos.'),
        ));
      }
    } catch (e) {
      print('Error al guardar el artículo: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Error al guardar el artículo. Por favor, inténtalo de nuevo.'),
      ));
    }
  }

  Future<int> _getCategoriaId(String categoriaNombre) async {
    final response = await supabase
        .from('categorias')
        .select('id')
        .eq('nombre', categoriaNombre)
        .single();
    if (response != null) {
      return response['id'];
    } else {
      throw Exception(
          'La categoría seleccionada no existe en la base de datos.');
    }
  }

  void _limpiarCampos() {
    _controllerNombre.clear();
    _controllerSKU.clear();
    setState(() {
      _selectedCategoria = '';
    });
  }
}

class AgregarCategoriaScreen extends StatefulWidget {
  final VoidCallback onCategoriaGuardada;

  AgregarCategoriaScreen({
    required this.onCategoriaGuardada,
  });

  @override
  _AgregarCategoriaScreenState createState() => _AgregarCategoriaScreenState();
}

class _AgregarCategoriaScreenState extends State<AgregarCategoriaScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  TextEditingController _controllerCategoria = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Agregar Categoría'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controllerCategoria,
              decoration: InputDecoration(
                labelText: 'Categoría',
                hintText: 'Escribe el nombre de la categoría',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _guardarCategoria();
              },
              child: Text('Guardar Categoría'),
            ),
          ],
        ),
      ),
    );
  }

  void _guardarCategoria() async {
    try {
      final categoria = _controllerCategoria.text.trim();

      if (categoria.isNotEmpty) {
        await supabase.from('categorias').insert({
          'nombre': categoria,
        });

        _limpiarCampos();
        widget.onCategoriaGuardada();
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Por favor, escribe el nombre de la categoría antes de guardar.'),
        ));
      }
    } catch (e) {
      print('Error al guardar la categoría: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Error al guardar la categoría. Por favor, inténtalo de nuevo.'),
      ));
    }
  }

  void _limpiarCampos() {
    _controllerCategoria.clear();
  }
}
