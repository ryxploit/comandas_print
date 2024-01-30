// ignore_for_file: public_member_api_docs, sort_constructors_first
// ignore_for_file: unused_import

import 'dart:async';
import 'dart:io';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';



void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _info = "";
  String _msj = '';
  bool connected = false;
  List<BluetoothInfo> items = [];
  // ignore: prefer_final_fields
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

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
          actions: [
            PopupMenuButton(
              elevation: 3.2,
              //initialValue: _options[1],
              onCanceled: () {
                print('You have not chossed anything');
              },
              tooltip: 'Menu',
              onSelected: (Object select) async {
                String sel = select as String;
                if (sel == "permission bluetooth granted") {
                  bool status =
                      await PrintBluetoothThermal.isPermissionBluetoothGranted;
                  setState(() {
                    _info = "permission bluetooth granted: $status";
                  });
                  //open setting permision if not granted permision
                } else if (sel == "bluetooth enabled") {
                  bool state = await PrintBluetoothThermal.bluetoothEnabled;
                  setState(() {
                    _info = "Bluetooth enabled: $state";
                  });
                } else if (sel == "update info") {
                  initPlatformState();
                } else if (sel == "connection status") {
                  final bool result =
                      await PrintBluetoothThermal.connectionStatus;
                  setState(() {
                    _info = "connection status: $result";
                  });
                }
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
                Text('info: $_info\n '),
                Text(_msj),
                Row(
                  children: [
                    const Text("Type print"),
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
                      child: Row(
                        children: [
                          Visibility(
                            visible: _progress,
                            child: const SizedBox(
                              width: 25,
                              height: 25,
                              child: CircularProgressIndicator.adaptive(
                                  strokeWidth: 1,
                                  backgroundColor: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(_progress ? _msjprogress : "Search"),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: connected ? disconnect : null,
                      child: const Text("Disconnect"),
                    ),
                    ElevatedButton(
                      onPressed: connected ? printTest : null,
                      child: const Text("Test"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // Redirige a PantallaDestino cuando se presiona el botón
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ComandasWidget(articulosMostrados: []))
                        );
                      },
                      child: const Text("Comandas"),
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
                        return ListTile(
                          onTap: () {
                            String mac = items[index].macAdress;
                            connect(mac);
                          },
                          title: Text('Name: ${items[index].name}'),
                          subtitle:
                              Text("macAddress: ${items[index].macAdress}"),
                        );
                      },
                    )),
                const SizedBox(height: 10),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> initPlatformState() async {
    String platformVersion;
    int porcentbatery = 0;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await PrintBluetoothThermal.platformVersion;
      // ignore: avoid_print
      print("patformversion: $platformVersion");
      porcentbatery = await PrintBluetoothThermal.batteryLevel;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    final bool result = await PrintBluetoothThermal.bluetoothEnabled;
    // ignore: avoid_print
    print("bluetooth enabled: $result");
    if (result) {
      _msj = "Bluetooth enabled, please search and connect";
    } else {
      _msj = "Bluetooth not enabled";
    }

    setState(() {
      _info = "$platformVersion ($porcentbatery% battery)";
    });
  }

  Future<void> getBluetoots() async {
    setState(() {
      _progress = true;
      _msjprogress = "Wait";
      items = [];
    });
    final List<BluetoothInfo> listResult =
        await PrintBluetoothThermal.pairedBluetooths;

    /*await Future.forEach(listResult, (BluetoothInfo bluetooth) {
      String name = bluetooth.name;
      String mac = bluetooth.macAdress;
    });*/

    setState(() {
      _progress = false;
    });

    if (listResult.isEmpty) {
      _msj =
          "There are no bluetoohs linked, go to settings and link the printer";
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
    print("state conected $result");
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

  Future<void> printTest() async {
    bool conexionStatus = await PrintBluetoothThermal.connectionStatus;
    //print("connection status: $conexionStatus");
    if (conexionStatus) {
      List<int> ticket = await testTicket();
      final result = await PrintBluetoothThermal.writeBytes(ticket);
      print("print test result:  $result");
    } else {
      //no conectado, reconecte
    }
  }

  Future<List<int>> testTicket() async {
    List<int> bytes = [];
    // Using default profile
    final profile = await CapabilityProfile.load();
    final generator = Generator(
        optionprinttype == "58 mm" ? PaperSize.mm58 : PaperSize.mm80, profile);
    //bytes += generator.setGlobalFont(PosFontType.fontA);
    bytes += generator.reset();

    //Using `ESC *`

    bytes += generator.text('COMANDA GONG CHA',
        styles: const PosStyles(
          align: PosAlign.center,
          fontType: PosFontType.fontA,
        ));
    bytes += generator.feed(2);
    bytes += generator.text('Bold text', styles: const PosStyles(bold: true));

    //barcode

    final List<int> barData = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 4];
    bytes += generator.barcode(Barcode.upcA(barData));

    bytes += generator.text(
      'Text size 100%',
      styles: const PosStyles(
        fontType: PosFontType.fontA,
      ),
    );

    bytes += generator.feed(2);
    bytes += generator.cut();
    return bytes;
  }
}


class ComandasWidget extends StatefulWidget {
  final List<Map<String, String>> articulosMostrados;

  ComandasWidget({
    Key? key,
    required this.articulosMostrados,
  }) : super(key: key);

  @override
  _ComandasWidgetState createState() => _ComandasWidgetState();
}

class _ComandasWidgetState extends State<ComandasWidget> {
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
    seleccionados.forEach((categoria, listaSeleccionados) {
      // ignore: avoid_print
      print('$categoria: $listaSeleccionados');
    });

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
