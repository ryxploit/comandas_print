import 'dart:async';
// ignore: unused_import
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: Colors.blue,
        hintColor: Colors.green,
        textTheme: const TextTheme(
          headline6: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          bodyText2: TextStyle(fontSize: 16),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _info = "";
  String _msj = '';
  bool connected = false;
  List<BluetoothInfo> items = [];
  List<String> _options = [
    "permission bluetooth granted",
    "bluetooth enabled",
    "connection status",
    "update info"
  ];
  bool _progress = false;
  String _msjprogress = "";
  String optionprinttype = "58 mm";
  List<String> options = ["58 mm", "80 mm"];
  String selectedCommand = "Default Command";

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gong cha'),
        backgroundColor: Colors.blue,
        actions: [
          PopupMenuButton(
            elevation: 3.2,
            onCanceled: () {
              print('You have not chosen anything');
            },
            tooltip: 'Menu',
            onSelected: (Object select) async {
              // ... (unchanged)
            },
            itemBuilder: (BuildContext context) {
              return _options.map((String option) {
                return PopupMenuItem(
                  value: option,
                  child: Text(option),
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
              Text('Info: $_info\n ',
                  style: Theme.of(context).textTheme.headline6),
              Text(_msj),
              Row(
                children: [
                  const Text("Type print", style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: optionprinttype,
                    items: options.map((String option) {
                      return DropdownMenuItem<String>(
                        value: option,
                        child: Text(option),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        optionprinttype = newValue!;
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
                      getBluetoots();
                    },
                    style: ElevatedButton.styleFrom(
                      primary: Colors.blue,
                    ),
                    child: Row(
                      children: [
                        Visibility(
                          visible: _progress,
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
                        Text(_progress ? _msjprogress : "Search"),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: connected ? disconnect : null,
                    style: ElevatedButton.styleFrom(
                      primary: Colors.blue,
                    ),
                    child: const Text("Disconnect"),
                  ),
                  ElevatedButton(
                    onPressed:
                        connected ? () => navigateToPrintScreen(context) : null,
                    style: ElevatedButton.styleFrom(
                      primary: Colors.blue,
                    ),
                    child: const Text("Test"),
                  ),
                ],
              ),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
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
                          connect(mac);
                        },
                        title: Text('Name: ${items[index].name}',
                            style: TextStyle(fontSize: 18)),
                        subtitle: Text("macAddress: ${items[index].macAdress}",
                            style: TextStyle(fontSize: 14)),
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

  Future<void> initPlatformState() async {
    try {
      String platformVersion = await PrintBluetoothThermal.platformVersion;
      print("platform version: $platformVersion");
      int porcentbatery = await PrintBluetoothThermal.batteryLevel;

      if (!mounted) return;

      final bool result = await PrintBluetoothThermal.bluetoothEnabled;
      print("bluetooth enabled: $result");
      if (result) {
        _msj = "Bluetooth enabled, please search and connect";
      } else {
        _msj = "Bluetooth not enabled";
      }

      setState(() {
        _info = "$platformVersion ($porcentbatery% battery)";
      });
    } on PlatformException {
      _info = 'Failed to get platform version.';
    }
  }

  Future<void> getBluetoots() async {
    setState(() {
      _progress = true;
      _msjprogress = "Wait";
      items = [];
    });
    final List<BluetoothInfo> listResult =
        await PrintBluetoothThermal.pairedBluetooths;

    setState(() {
      _progress = false;
    });

    if (listResult.isEmpty) {
      _msj =
          "There are no Bluetooth devices linked. Go to settings and link the printer.";
    } else {
      _msj = "Touch an item in the list to connect";
    }

    setState(() {
      items = listResult;
    });
  }

  Future<void> connect(String mac) async {
    setState(() {
      _progress = true;
      _msjprogress = "Connecting...";
      connected = false;
    });
    final bool result =
        await PrintBluetoothThermal.connect(macPrinterAddress: mac);
    print("state connected $result");
    if (result) connected = true;
    setState(() {
      _progress = false;
    });
  }

  Future<void> disconnect() async {
    final bool status = await PrintBluetoothThermal.disconnect;
    setState(() {
      connected = false;
    });
    print("status disconnect $status");
  }

  void navigateToPrintScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PrintScreen()),
    );
  }
}

class PrintScreen extends StatelessWidget {
  const PrintScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyComandaPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyComandaPage extends StatefulWidget {
  const MyComandaPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MyComandaPageState createState() => _MyComandaPageState();
}

class _MyComandaPageState extends State<MyComandaPage> {
  Map<String, List<Map<String, String>>> categorias = {
    "TAMAÑO DE LA BEBIDA": [
      {"id": "1106986483", "nombre": "Articulo 1.1"},
      {"id": "1234567890", "nombre": "Articulo 1.2"}
    ],
    "TOPPING": [
      {"id": "9876543210", "nombre": "Articulo 2.1"},
      {"id": "5678901234", "nombre": "Articulo 2.2"}
    ],
    "LECHE": [
      {"id": "1122334455", "nombre": "Articulo 3.1"},
      {"id": "6677889900", "nombre": "Articulo 3.2"}
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
                      _toggleSelection(articulo);
                    },
                    tileColor: _isSelected(articulo)
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
              'Imprimir Seleccionados',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> printTest(
      List<Map<String, String>> articulosSeleccionados) async {
    bool connectionStatus = await PrintBluetoothThermal.connectionStatus;
    if (connectionStatus) {
      List<int> ticket = await testTicket(articulosSeleccionados);
      final result = await PrintBluetoothThermal.writeBytes(ticket);
      print("Print test result: $result");
    } else {
      // Manejar el caso cuando no está conectado
      print(
          "La impresora no está conectada. Reconectar o mostrar mensaje de error.");
    }
  }

  

  Future<List<int>> testTicket(
      List<Map<String, String>> articulosSeleccionados) async {
    List<int> bytes = [];

    // Usar perfil predeterminado
    final profile = await CapabilityProfile.load();
    var optionprinttype;
    final generator = Generator(
      optionprinttype == "58 mm" ? PaperSize.mm58 : PaperSize.mm80,
      profile,
    );

    bytes += generator.reset();

    // Usar `ESC *`
    bytes += generator.text('COMANDA GONG CHA',
        styles: const PosStyles(
          align: PosAlign.center,
          fontType: PosFontType.fontA,
        ));
    bytes += generator.feed(2);
    bytes += generator.text('Artículos Seleccionados:',
        styles: const PosStyles(bold: true));

    // Imprimir detalles de artículos seleccionados con código de barras
for (var articulo in articulosSeleccionados) {
  bytes += generator.text('${articulo["nombre"]} - ${articulo["id"]}');

  // Obtener el ID como cadena
  final String barData = articulo["id"].toString();
  print(barData);

  //final List<int> barData = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 4];
    //bytes += generator.barcode(Barcode.upcA(barData));
}




    bytes += generator.feed(2);
    bytes += generator.cut();

    return bytes;
  }

  void _toggleSelection(Map<String, String> articulo) {
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

  bool _isSelected(Map<String, String> articulo) {
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

  printTest(articulosSeleccionados);

  _showSuccessAlert();

  setState(() {
    seleccionados.clear();
    articulosMostrados.clear();
  });
}

  void _showSuccessAlert() {
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
