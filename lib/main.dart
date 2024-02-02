// ignore_for_file: avoid_print, duplicate_ignore

import 'dart:async';
// ignore: unused_import
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
  const PantallaPrincipal({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _PantallaPrincipalState createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
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
        title: const Text('Gong cha',style: const TextStyle(color: Colors.white),),
        backgroundColor: Colors.pink,
        actions: [
          PopupMenuButton(
            elevation: 3.2,
            onCanceled: () {
              // ignore: avoid_print
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
                  style: Theme.of(context).textTheme.titleLarge),
              Text(_msj),
              Row(
                children: [
                  const Text("Tipo de impresión", style: TextStyle(fontSize: 16)),
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
                        Text(_progreso ? _msjProgreso : "Buscar",style: const TextStyle(color: Colors.white),),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: conectado ? desconectar : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                    ),
                    child: const Text("Desconectar",style: const TextStyle(color: Colors.white),),
                  ),
                  ElevatedButton(
                    onPressed:
                        conectado ? () => navegarAPantallaImpresion(context) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                    ),
                    child: const Text("Ir a Comandas",style: const TextStyle(color: Colors.white),),
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
                        subtitle: Text("Dirección MAC: ${items[index].macAdress}",
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
      // ignore: avoid_print
      print("versión de la plataforma: $versionPlataforma");
      int porcentajeBateria = await PrintBluetoothThermal.batteryLevel;

      if (!mounted) return;

      final bool resultado = await PrintBluetoothThermal.bluetoothEnabled;
      // ignore: avoid_print
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

  // ignore: duplicate_ignore
  Future<void> conectar(String mac) async {
    setState(() {
      _progreso = true;
      _msjProgreso = "Conectando...";
      conectado = false;
    });
    final bool resultado =
        await PrintBluetoothThermal.connect(macPrinterAddress: mac);
    // ignore: avoid_print
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
  const PantallaImpresion({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MiPantallaComanda(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MiPantallaComanda extends StatefulWidget {
  const MiPantallaComanda({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MiPantallaComandaState createState() => _MiPantallaComandaState();
}

class _MiPantallaComandaState extends State<MiPantallaComanda> {
  Map<String, List<Map<String, String>>> categorias = {
    "TAMAÑO DE LA BEBIDA": [
      {"id": "1106986483", "nombre": "Artículo 1.1"},
      {"id": "1234567890", "nombre": "Artículo 1.2"}
    ],
    "TOPPING": [
      {"id": "9876543210", "nombre": "Artículo 2.1"},
      {"id": "5678901234", "nombre": "Artículo 2.2"}
    ],
    "LECHE": [
      {"id": "1122334455", "nombre": "Artículo 3.1"},
      {"id": "6677889900", "nombre": "Artículo 3.2"}
    ],
    "BEBIDA": [
      {"id": "1122334455", "nombre": "Artículo 4.1"},
      {"id": "6677889900", "nombre": "Artículo 4.2"}
    ],
  };

  List<Map<String, String>> articulosMostrados = [];
  Map<String, List<Map<String, String>>> seleccionados = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 4,
        title: Row(
          children: [
            Image.asset(
              'assets/logos/LogoBlanco.png',
              height: 40,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            child: const Text(
              'Categorías',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categorias.keys
                  .map((categoria) => GestureDetector(
                        onTap: () {
                          setState(() {
                            articulosMostrados =
                                List.from(categorias[categoria] ?? []);
                            seleccionados[categoria] = [];
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: seleccionados[categoria] != null &&
                                    seleccionados[categoria]!.isNotEmpty
                                ? Colors.pink
                                : Colors.grey,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            categoria,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            child: const Text(
              'Artículos',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: articulosMostrados.length,
              itemBuilder: (context, index) {
                Map<String, String> articulo = articulosMostrados[index];
                return Card(
                  elevation: 3,
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    title: Text(
                      '${articulo["nombre"]} - ${articulo["id"]}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    onTap: () {
                      _alternarSeleccion(articulo);
                    },
                    tileColor: _estaSeleccionado(articulo)
                        ? Colors.pink.withOpacity(0.3)
                        : null,
                  ),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _imprimirSeleccionados();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
            ),
            child: const Text(
              'Imprimir Comanda',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> imprimirPrueba(
      List<Map<String, String>> articulosSeleccionados) async {
    bool estadoConexion = await PrintBluetoothThermal.connectionStatus;
    if (estadoConexion) {
      List<int> ticket = await pruebaTicket(articulosSeleccionados);
      final resultado = await PrintBluetoothThermal.writeBytes(ticket);
      print("Resultado de la prueba de impresión: $resultado");
    } else {
      // Manejar el caso cuando no está conectado
      print(
          "La impresora no está conectada. Vuelve a conectar o muestra un mensaje de error.");
    }
  }

  Future<List<int>> pruebaTicket(
      List<Map<String, String>> articulosSeleccionados) async {
    List<int> bytes = [];

    // Usar perfil predeterminado
    final perfil = await CapabilityProfile.load();
    // ignore: prefer_typing_uninitialized_variables
    var tipoImpresion;
    final generador = Generator(
      tipoImpresion == "58 mm" ? PaperSize.mm58 : PaperSize.mm80,
      perfil,
    );

    bytes += generador.reset();

    // Usar `ESC *`
    bytes += generador.text('COMANDA GONG CHA LIVERPOOL MAZATLAN',
        styles: const PosStyles(
          align: PosAlign.center,
          fontType: PosFontType.fontA,
        ));
    bytes += generador.feed(2);
    bytes += generador.text('Artículos Seleccionados:',
        styles: const PosStyles(bold: true));

    for (var articulo in articulosSeleccionados) {
      // Obtener el ID como cadena
      final String id = articulo["id"].toString();

      // Imprimir detalles del artículo
      bytes += generador.text('${articulo["nombre"]} ');
      //  print(detalleArticulo);

      //Código QR
      //bytes += generador.qrcode(id);

      // Código de barras 
      bytes += generador.barcode(Barcode.itf(id.split('')));

      // Agregar un salto de línea para separar cada artículo
      bytes.add(10);
    }

    bytes += generador.feed(2);
    bytes += generador.cut();

    return bytes;
  }

  void _alternarSeleccion(Map<String, String> articulo) {
    setState(() {
      for (var categoria in categorias.keys) {
        if (categorias[categoria]?.contains(articulo) ?? false) {
          if (seleccionados[categoria]?.contains(articulo) ?? false) {
            seleccionados[categoria]?.remove(articulo);
          } else {
            seleccionados[categoria]?.add(articulo);
          }
        }
      }
    });
  }

  bool _estaSeleccionado(Map<String, String> articulo) {
    for (var listaSeleccionados in seleccionados.values) {
      if (listaSeleccionados.contains(articulo)) {
        return true;
      }
    }
    return false;
  }

  void _imprimirSeleccionados() {
    // ignore: avoid_print
    print('Artículos Seleccionados:');

    List<Map<String, String>> articulosSeleccionados = [];

    seleccionados.forEach((categoria, listaSeleccionados) {
      // ignore: avoid_print
      print('$categoria: $listaSeleccionados');
      articulosSeleccionados.addAll(listaSeleccionados);
    });

    imprimirPrueba(articulosSeleccionados);

    _mostrarAlertaExito();

    setState(() {
      seleccionados.clear();
      articulosMostrados.clear();
    });
  }

  void _mostrarAlertaExito() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Éxito'),
          content: const Text(
              'Los artículos seleccionados se han impreso con éxito.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }
}
