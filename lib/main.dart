// ignore_for_file: avoid_print

import 'dart:async';
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
    "SERIE MILK": [
      {"id": "1107799377", "nombre": "GREEN MILK TEA MED 70.00"},
      {"id": "1107799482", "nombre": "GREEN MILK TEA GRAND 80.00"},
      {"id": "1113094954", "nombre": "GREEN MILK TEA CAL MED 70.00"},
      {"id": "1107799385", "nombre": "BLACK MILK TEA MED 70.00"},
      {"id": "1107799491", "nombre": "BLACK MILK TEA GRAND 80.00"},
      {"id": "1113094962", "nombre": "BLACK MILK TEA MED CAL 70.00"},
      {"id": "1107799369", "nombre": "TAPIOCA BLACK MILK TEA MED 88.00"},
      {"id": "1107799474", "nombre": "TAPIOCA BLACK MILK TEA GRAND 100.00"},
      {"id": "1113094474", "nombre": "TAPIOCA BLACK MILK TEA MED CAL 79.00"},
      {"id": "1107799393", "nombre": "CARAMEL BLACK MILK TEA MED 91.00"},
      {"id": "1107799504", "nombre": "CARAMEL BLACK MILK TEA GRAND 101.00"},
      {"id": "1113094971", "nombre": "CARAMEL BLACK TEA MED CAL 91.00"},
      {"id": "1107799407", "nombre": "CHOCOLATE MILK MED 96.00"},
      {"id": "1107799512", "nombre": "CHOCOLATE MILK GRAND 108.00"},
      {"id": "1113094989", "nombre": "CHOCOLATE MILK MED CAL 96.00"},
      {"id": "1107799415", "nombre": "TARO MILK MED 96.00"},
      {"id": "1107799521", "nombre": "TARO MILK GRAND 108.00"},
      {"id": "1113094997", "nombre": "TARO MILK MED CAL 96.00"},
      {"id": "1107799423", "nombre": "MATCHA MILK MED 91.00"},
      {"id": "1107799539", "nombre": "MATCHA MILK GRAND 103.00"},
      {"id": "1113095004", "nombre": "MATCHA MILK MED CAL 91.00"},
      {"id": "1107799431", "nombre": "CHAI MILK TEA MED 96.00"},
      {"id": "1107799547", "nombre": "CHAI MILK TEA GRAND 108.00"},
      {"id": "1113095012", "nombre": "CHAI MILK TEA MED CAL 96.00"},
      {"id": "1107799440", "nombre": "FRESA GREEN MILK TEA MED 91.00"},
      {"id": "1107799555", "nombre": "FRESA GREEN MILK TEA GRAND 101.00"},
      {"id": "1113095098", "nombre": "FRESA GREEN MILK TEA MED CAL 91.00"},
      {"id": "1107799458", "nombre": "FRESA BLACK MILK TEA MED 91.00"},
      {"id": "1107799563", "nombre": "FRESA BLACK MILK TEA GRAND 101.00"},
      {"id": "1113095101", "nombre": "FRESA BLACK MILK TEA MED CAL 91.00"},
      {"id": "1107799466", "nombre": "YAKULT GREEN MED 91.00"},
      {"id": "1107799571", "nombre": "YAKULT GREEN GRAND 101.00"}
    ],
    "SERIE SMOOTHIE": [
      {"id": "1107799768", "nombre": "TARO SMOOTHIE MED 101.00"},
      {"id": "1107800260", "nombre": "TARO SMOOTHIE GRAND 113.00"},
      {"id": "1107799776", "nombre": "MANGO SMOOTHIE MED 110.00"},
      {"id": "1107800278", "nombre": "MANGO SMOOTHIE GRAND 122.00"},
      {"id": "1107799784", "nombre": "CHOCOLATE SMOOTHIE MED 101.00"},
      {"id": "1107800286", "nombre": "CHOCOLATE SMOOTHIE GRAND 113.00"},
      {"id": "1107799792", "nombre": "CHAI SMOOTHIE MED 100.00"},
      {"id": "1107800294", "nombre": "CHAI SMOOTHIE GRAND 112.00"},
      {"id": "1107799806", "nombre": "MATCHA SMOOTHIE MED 101.00"},
      {"id": "1107800308", "nombre": "MATCHA SMOOTHIE GRAND 113.00"},
      {"id": "1107799814", "nombre": "FRESA SMOOTHIE MED 100.00"},
      {"id": "1107800316", "nombre": "FRESA SMOOTHIE GRAND 112.00"},
      {"id": "1107800120", "nombre": "CHOCO FRESA SMOOTHIE MED 110.00"},
      {"id": "1107800821", "nombre": "CHOCO FRESA SMOOTHIE GRAND 122.00"},
      {"id": "1107800847", "nombre": "DURAZNO BLACK TEA SMOOTHIE MED 88.00"},
      {"id": "1107800871", "nombre": "DURAZNO BLACK TEA SMOOHIE GRAD 100.00"},
      {"id": "1107803421", "nombre": "MARACUYA SMOOTHIE CON COCO JEL 91.00"},
      {"id": "1107800855", "nombre": "MARACUYA SMOOTHIE CON COCO JEL 103.00"},
      {"id": "1107800898", "nombre": "LICHI SMOOTHIE GRAND 100.00"},
      {"id": "1107800863", "nombre": "LICHI SMOOTHIE MED 88.00"},
      {"id": "1107801860", "nombre": "MARACUYA GREEN TEA SMOOTHIE ME 81.00"},
      {"id": "1107801878", "nombre": "MARACUYA GREEN TEA SMOOTHIE GR 93.00"},
      {"id": "1107801886", "nombre": "MANGO GREEN TEA SMOOTHIE MED 110.00"},
      {"id": "1107801894", "nombre": "MANGO GREEN TEA SMOOTHIE GRAN 122.00"},
      {"id": "1105350798", "nombre": "CHILLI SMOOTHIE"}
    ],
    "SERIE CREATIVA/BROWN": [
      {"id": "1107799717", "nombre": "MARACUYA GREEN TEA GRAND 93.00"},
      {"id": "1107799628", "nombre": "MARACUYÀ GREEN TEA MED 81.00"},
      {"id": "1113095233", "nombre": "MARACUYÁ GREEN TEA MED CAL 81.00"},
      {"id": "1107799679", "nombre": "MARACOCO GREEN TEA CON PERLAS C 107.00"},
      {"id": "1107799580", "nombre": "MARACOCO GREEN TEA CON PERLAS 95.00"},
      {"id": "1107799709", "nombre": "LICHI GREEN TEA GRAND 93.00"},
      {"id": "1107799610", "nombre": "LICHI GREEN TEA MED  81.00"},
      {"id": "1113095225", "nombre": "LICHI GREEN TEA MED CAL 81.00"},
      {"id": "1107799636", "nombre": "FRESA GREEN TEA MED 86.00"},
      {"id": "1107799725", "nombre": "FRESA GREEN TEA GRAND 98.00"},
      {"id": "1113095241", "nombre": "FRESA GREEN TEA MED CAL 86.00"},
      {"id": "1107799733", "nombre": "FRESA BLACK TEA GRAND 98.00"},
      {"id": "1107799644", "nombre": "FRESA BLACK TEA MED 86.00"},
      {"id": "1113095250", "nombre": "FRESA BLACK TEA MED CAL 86.00"},
      {"id": "1107799601", "nombre": "MANGO GREEN TEA MED 86.00"},
      {"id": "1107799695", "nombre": "MANGO GREEN TEA GRAND 98.00"},
      {"id": "1113095110", "nombre": "MANGO GREEN TEA MED CAL 86.00"},
      {"id": "1107799652", "nombre": "DURAZNO GREEN TEA MED 81.00"},
      {"id": "1107799741", "nombre": "DURAZNO GREEN TEA GRAND 93.00"},
      {"id": "1113094911", "nombre": "DURAZNO GREEN TEA MED CAL 81.00"},
      {"id": "1107801258", "nombre": "BROWN SUGAR PEARL LATTE GRAND  103.00"},
      {"id": "1107801223", "nombre": "BROWN SUGAR PEARL LATTE MED  91.00"},
      {"id": "1107801240", "nombre": "BROWN SUGAR MATCHA MILK TEA GR 104.00"},
      {"id": "1107800910", "nombre": "BROWN SUGAR MATCHA MILK TEA ME 94.00"},
      {"id": "1107801231", "nombre": "BROWN SUGAR BLACK MILK TEA GRAN 101.00"},
      {"id": "1107800901", "nombre": "BROWN SUGAR BLACK MILK TEA MED 91.00"},
      {"id": "1113094920", "nombre": "BROWN SUGAR BLACK MILK TEA MED 90.00"}
    ],
    "SERIE TE/CAFE": [
      {"id": "1107799342", "nombre": "GREEN TEA GRAND 75.00"},
      {"id": "1107799105", "nombre": "GREEN TEA MED 65.00"},
      {"id": "1107799351", "nombre": "BLACK TEA GRAND 75.00"},
      {"id": "1107799113", "nombre": "BLACK TEA MED 65.00"},
      {"id": "1107799326", "nombre": "GREEN TEA CALIENTE MED 65.00"},
      {"id": "1107799334", "nombre": "BLACK TEA CALIENTE MED 65.00"},
      {"id": "1128339988", "nombre": "MILK COFFEE MED 76.00"},
      {"id": "1128340030", "nombre": "MILK COFFEE GDE 86.00"},
      {"id": "1128339996", "nombre": "AMERICANO MED 65.00"},
      {"id": "1128340048", "nombre": "AMERICANO GDE 75.00"},
      {"id": "1128340005", "nombre": "MOCHA MED 88.00"},
      {"id": "1128340056", "nombre": "MOCHA GDE 98.00"},
      {"id": "1128340137", "nombre": "DOLCE MILK MED 96.00"},
      {"id": "1128340111", "nombre": "DOLCE SMOOTHIE GDE 104.00"},
      {"id": "1128340129", "nombre": "DOLCE SMOOTHIE MED 92.00"}
    ],
    "TEMPORADA": [
      {"id": "1142067206", "nombre": "LONDON FOG EARL GREY CALIENTE MED 78.00"},
      {"id": "1142067214", "nombre": "LONDON FOG EARL GREY MED 78.00"},
      {"id": "1142067826", "nombre": "LONDON FOG EARL GREY GRAD 90.00"},
      {
        "id": "1146375266",
        "nombre": "Gingerbread Milk Tea with Milk Foam and Pearls (Hot) 110.00"
      },
      {
        "id": "1149572101",
        "nombre": "STRAWBERRY ALMOND JELLY MILK TEA MED 95.00"
      },
      {
        "id": "1149572119",
        "nombre": "STRAWBERRY ALMOND JELLY SMOOTHIE MED 100.00"
      },
      {
        "id": "1146375274",
        "nombre": "Gingerbread Milk Tea en botella navideña 150.00"
      },
      {"id": "1148493975", "nombre": "Combo chocolate MED/FRIO 135.00"},
      {"id": "1148493983", "nombre": "Combo chocolate GDE/FRIO 150.00"},
      {"id": "1148493991", "nombre": "Combo chocolate MED/CALIENTE 135.00"},
      {
        "id": "1148722842",
        "nombre": "Lychee sweet caramel green tea MED/FRIO 2x1½ 112.00"
      },
      {
        "id": "1148725361",
        "nombre": "Lychee sweet caramel green tea MED/Caliente 2x1½ 112.00"
      },
      {
        "id": "1148726333",
        "nombre": "Lychee sweet caramel green tea GDE/FRIO 2x1½ 127.00"
      },
      {
        "id": " 1148726341",
        "nombre": "Taro Sweet Caramel Milk MED/FRIO 2x1½ 120.00"
      },
      {
        "id": "1148726350",
        "nombre": " Taro Sweet Caramel Milk MED/Caliente 2x1½ 120.00"
      },
      {
        "id": "1148726368",
        "nombre": "Taro Sweet Caramel Milk GDE/FRIO 2x1½ 135.00"
      },
      {
        "id": "1148726376",
        "nombre": "Chai Sweet Caramel Milk MED/FRIO 2x1½ 120.00"
      },
      {
        "id": "1148726384",
        "nombre": "Chai Sweet Caramel Milk MED/Caliente 2x1½ 120.00"
      },
      {
        "id": "1148726392",
        "nombre": "Chai Sweet Caramel Milk GDE/FRIO 2x1½ 135.00"
      }
    ],
    "TOPPINGS": [
      {"id": "1107801266", "nombre": "LECHE DESLACTOSADA 9.00"},
      {"id": "1131685668", "nombre": "LECHE ENTERA 0.01"},
      {"id": "1131685676", "nombre": "LECHE LIGHT 0.01"},
      {"id": "1107801274", "nombre": "LECHE DESLACTOSADA LIGHT 9.00"},
      {"id": "1107801282", "nombre": "LECHE DE COCO 10.00"},
      {"id": "1107801291", "nombre": "LECHE DE ALMENDRAS 10.00"},
      {"id": "1107801304", "nombre": "OREOS MOLIDAS 10.00"},
      {"id": "1107801312", "nombre": "TAPIOCA / PERLAS 12.00"},
      {"id": "1107801321", "nombre": "COCO JELLY 15.00"},
      {"id": "1107801339", "nombre": "MILK FOAM 13.00"},
      {"id": "1107801347", "nombre": "TAPIOCA BLANCA 18.00"},
      {"id": "1107801355", "nombre": "TAPIOCA FRESA 19.00"},
      {"id": "1107801371", "nombre": "CREME BRULEE 15.00"}
    ],
    "SOUVENIRS": [
      {"id": "1130205697", "nombre": "AGENDA GONGCHA 250.00"},
      {"id": "1103817672", "nombre": "SET DE POPOTES 130.00"},
      {"id": "1109302216", "nombre": "LLAVERO GONGCHA 3D 100.00"},
      {"id": "1128821411", "nombre": "TERMO ACERO INOXIDABLE 380.00"},
      {"id": "1103819130", "nombre": "TERMO PLASTICO 160.00"},
      {"id": "1131856012", "nombre": "MAIZ PUFFED 25.00"},
      {"id": "1131856004", "nombre": "OBLEAS GOLDEN MILK / PINK CHAI 48.00"},
      {"id": "1131855997", "nombre": "OBLEAS MATCHA / TARO 48.00"},
      {"id": "1149767815", "nombre": "Conejo en la Luna 320.00"},
      {"id": "1149769851", "nombre": " Boba Gamer 320.00"},
      {"id": "1149769869", "nombre": "Las aventuras de Tapiokitty 320.00"},
    ],
    "EMBOTELLADOS": [
      {"id": "1146476551", "nombre": "AGUA GODDESS ATHENA 500 ML 39.00"},
    ],
    "ALIMENTOS": [
      {"id": "1131936920", "nombre": "BG ROST BEEF 85.00"},
      {"id": "1131936946", "nombre": "BG PAVO 85.00"},
      {"id": "1131936954", "nombre": "BG SERRANO 95.00"},
      {"id": "1131936962", "nombre": "BG PAMPLONA 85.00"},
      {"id": "1131936971", "nombre": "BG 3 QUESOS 85.00"},
      {"id": "1131937039", "nombre": "PASTEL DE CHOCOLATE 70.00"},
      {"id": "1131937047", "nombre": "CHEESSCAKE 65.00"},
      {"id": "1131886221", "nombre": "OBLEAS MATCHA / TARO 48.00"},
      {"id": "1131889026", "nombre": "OBLEAS GOLDEN MILK / PINK 48.00"},
      {"id": "1131936989", "nombre": "BG SELVA NEGRA 95.00"},
      {"id": "1131936997", "nombre": "PANQUE DE CHOCOLATE 45.00"},
      {"id": "1131937004", "nombre": "PANQUE DE ELOTE 45.00"},
      {"id": "1131937012", "nombre": "PANQUE DE COCO 45.00"},
      {"id": "1131937021", "nombre": "PANQUE DE PLATANO 45.00"},
    ],
  };

  List<Map<String, String>> articulosMostrados = [];
  Map<String, List<Map<String, String>>> seleccionados = {};

  List<Map<String, String>> carrito = []; // Carrito de compras

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
          // Carrito de compras
          Container(
            padding: const EdgeInsets.all(10),
            child: const Text(
              'Carrito de Compras',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 1,
            child: ListView.builder(
              itemCount: carrito.length,
              itemBuilder: (context, index) {
                final articulo = carrito[index];
                return ListTile(
                  title: Text('${articulo["nombre"]}'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        carrito.removeAt(index);
                      });
                    },
                  ),
                );
              },
            ),
          ),

          ElevatedButton(
            onPressed: () {
              _vaciarCarrito();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              'Vaciar Carrito',
              style: TextStyle(color: Colors.white),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _imprimirCarrito();
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

  void _alternarSeleccion(Map<String, String> articulo) {
    setState(() {
      for (var categoria in categorias.keys) {
        if (categorias[categoria]?.contains(articulo) ?? false) {
          if (seleccionados[categoria]?.contains(articulo) ?? false) {
            carrito.add(articulo); // Agregar al carrito si ya está seleccionado
          } else {
            seleccionados[categoria]?.add(articulo);
            carrito.add(articulo); // Agregar al carrito si no está seleccionado
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

  void _imprimirCarrito() {
    print('Artículos en el carrito:');

    List<Map<String, String>> articulosCarrito = [];

    carrito.forEach((articulo) {
      print('$articulo');
      articulosCarrito.add(articulo);
    });

    imprimirPrueba(articulosCarrito);

    setState(() {
      seleccionados.clear();
      articulosMostrados.clear();
      carrito.clear(); // Vaciar el carrito después de imprimir
    });
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
    bytes += generador.text('GONG CHA LIVERPOOL MAZATLAN',
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

  // Métodos para gestionar el carrito de compras
  void _agregarAlCarrito(Map<String, String> articulo) {
    setState(() {
      carrito.add(articulo);
    });
  }

  void _removerDelCarrito(Map<String, String> articulo) {
    setState(() {
      carrito.remove(articulo);
    });
  }

  void _vaciarCarrito() {
    setState(() {
      carrito.clear();
    });
  }
}
