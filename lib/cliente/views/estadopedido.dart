import 'package:app2025/cliente/models/pedido_cliente_model.dart';
import 'package:app2025/cliente/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class EstadoPedido extends StatefulWidget {
  // final int? clienteId;
  const EstadoPedido({Key? key}) : super(key: key);
  @override
  State<EstadoPedido> createState() => _EstadoPedido();
}

class _EstadoPedido extends State<EstadoPedido> with TickerProviderStateMixin {
  //Color colorLetra = Color.fromARGB(255, 1, 75, 135);
  Color colorLetra = const Color.fromARGB(255, 1, 42, 76);
  //Color colorTitulos = Color.fromARGB(255, 1, 42, 76);
  Color colorTitulos = const Color.fromARGB(255, 3, 34, 60);
  Color colorOF = Colors.grey;
  Color colorON = Color.fromARGB(255, 136, 255, 118);
  String apiUrl = dotenv.env['API_URL'] ?? '';
  String apiPedidosCliente = "/api/pedido_cliente/";
  String apiProductosPedido = "/api/productosPedido/";
  String iconoRecibido = 'lib/animaciones/recibidoon6.json';
  String iconoEnCaminoON = 'lib/animaciones/encaminoon1.json';
  String iconoEnCaminoOF = 'lib/animaciones/encaminoof1.json';
  String iconoEntregadoON = 'lib/animaciones/entregadoon2.json';
  String iconoEntregadoOF = 'lib/animaciones/entregadoof1.json';
  String iconoTruncado = 'lib/animaciones/pedidotruncado1.json';

  String mensajePendiente =
      'Ya recibimos tu pedido!, estamos gestionando la entrega ;)';
  String mensajeEncamino = 'Tus productos Sol ya estan en camino!';
  String mensajeEntregado = '¡Ya entregamos tu pedido! :)';
  String mensajeTruncado = 'No pudimos entregar tu pedido :(';
  String linea = 'lib/animaciones/lineacargando.json';
  List<PedidoCliente> listPedidosPendientes = [];
  List<PedidoCliente> listPedidosPasados = [];
  List<ProductoPedidoCliente> listProductosPedidoPendiente = [];
  List<ProductoPedidoCliente> listProductosPedidoPasados = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // Llama a tu función con el ID del usuario
      ordenandoGets(userProvider.user?.id);
    });
  }

  DateTime mesyAnio(String? fecha) {
    if (fecha is String) {
      return DateTime.parse(fecha);
    } else {
      return DateTime.now();
    }
  }

  Future<dynamic> getPedidos(clienteID) async {
    var res = await http.get(
      Uri.parse(apiUrl + apiPedidosCliente + clienteID.toString()),
      headers: {"Content-type": "application/json"},
    );
    print(".........data");
    print(res.body);
    try {
      if (res.statusCode == 200) {
        var data = json.decode(res.body);
        List<PedidoCliente> tempPedidos = data.map<PedidoCliente>((mapa) {
          return PedidoCliente(
            id: mapa['id'],
            estado: mapa['estado'],
            subtotal: mapa['subtotal'].toDouble(),
            descuento: mapa['descuento'].toDouble(),
            total: mapa['total'].toDouble(),
            tipoPago: mapa['tipo_pago'],
            tipoEnvio: mapa['tipo'],
            fecha: mapa['fecha'],
            direccion: mapa['direccion'],
            distrito: mapa['distrito'],
          );
        }).toList();
        // Verificar si el widget está montado antes de llamar a setState
        if (mounted) {
          setState(() {
            for (var i = 0; i < tempPedidos.length; i++) {
              if (tempPedidos[i].estado == 'pendiente') {
                tempPedidos[i].mensaje = mensajePendiente;
                tempPedidos[i].iconoRecibido = iconoRecibido;
                tempPedidos[i].colorRecibido = colorON;
                tempPedidos[i].iconoProceso = iconoEnCaminoOF;
                tempPedidos[i].colorProceso = colorOF;
                tempPedidos[i].iconoEntregado = iconoEntregadoOF;
                tempPedidos[i].colorEntregado = colorOF;
                listPedidosPendientes.add(tempPedidos[i]);
                print(listPedidosPendientes);

                // ACA SE PUEDE AGREGAR UN ATRIBUTO DE FECHA DE ENTREGA AL PEDIDO
              } else if (tempPedidos[i].estado == 'en proceso') {
                tempPedidos[i].mensaje = mensajeEncamino;
                tempPedidos[i].iconoRecibido = iconoRecibido;
                tempPedidos[i].colorRecibido = colorON;
                tempPedidos[i].iconoProceso = iconoEnCaminoON;
                tempPedidos[i].colorProceso = colorON;
                tempPedidos[i].iconoEntregado = iconoEntregadoOF;
                tempPedidos[i].colorEntregado = colorOF;
                listPedidosPendientes.add(tempPedidos[i]);
              } else if (tempPedidos[i].estado == 'entregado') {
                tempPedidos[i].mensaje = mensajeEntregado;
                tempPedidos[i].iconoEntregado = iconoEntregadoON;
                tempPedidos[i].colorEntregado = colorON;
                tempPedidos[i].altoIcono = 0.2;
                tempPedidos[i].anchoIcono = 0.35;
                listPedidosPasados.add(tempPedidos[i]);
              } else if (tempPedidos[i].estado == 'truncado') {
                tempPedidos[i].mensaje = mensajeTruncado;
                tempPedidos[i].iconoEntregado = iconoTruncado;
                tempPedidos[i].colorEntregado = colorON;
                tempPedidos[i].altoIcono = 0.1;
                tempPedidos[i].anchoIcono = 0.12;
                listPedidosPasados.add(tempPedidos[i]);
              }
            }
          });
        }
      }
    } catch (e) {
      throw Exception('Error en la solicitud: $e');
    }
  }

  Future<dynamic> getProductos(
      pedidoID, List<ProductoPedidoCliente> listaProductos) async {
    var res = await http.get(
      Uri.parse(apiUrl + apiProductosPedido + pedidoID.toString()),
      headers: {"Content-type": "application/json"},
    );
    try {
      if (res.statusCode == 200) {
        var data = json.decode(res.body);
        List<ProductoPedidoCliente> tempoProductos =
            data.map<ProductoPedidoCliente>((mapa) {
          return ProductoPedidoCliente(
            productoID: mapa['producto_id'],
            productoNombre: mapa['producto_nombre'],
            cantidadProducto: mapa['cantidad'],
            foto: mapa['foto'],
            promocionID: mapa['promocion_id'],
            promocionNombre: mapa['promocion_nombre'],
            cantidadPorPromo: mapa['cantidad_por_promo'],
          );
        }).toList();
        // Verificar si el widget está montado antes de llamar a setState
        if (mounted) {
          setState(() {
            listaProductos.addAll(tempoProductos);
          });
        }
      }
    } catch (e) {
      //print('Error en la solicitud: $e');
      throw Exception('Error en la solicitud: $e');
    }
  }

  Future<void> ordenandoGets(clienteID) async {
    await getPedidos(clienteID);
    for (var i = 0; i < listPedidosPasados.length; i++) {
      await getProductos(listPedidosPasados[i].id, listProductosPedidoPasados);
    }
    for (var i = 0; i < listPedidosPendientes.length; i++) {
      await getProductos(
          listPedidosPendientes[i].id, listProductosPedidoPendiente);
    }
  }

  @override
  Widget build(BuildContext context) {
    final TabController tabController = TabController(length: 2, vsync: this);
    final anchoActual = MediaQuery.of(context).size.width;
    final largoActual = MediaQuery.of(context).size.height;
    return Scaffold(
        backgroundColor: Colors.white,
        body: PopScope(
          canPop: false,
          onPopInvoked: (bool didPop) {
            if (didPop) {
              return;
            }
          },
          /*appBar: AppBar(
        backgroundColor: Colors.white,
      ),*/
          child: SafeArea(
              child: Padding(
            padding: const EdgeInsets.all(12.0),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              //TAB BAR
              Container(
                height: largoActual * 0.060,
                width: anchoActual,
                decoration: BoxDecoration(
                    color: const Color.fromARGB(129, 192, 192, 192),
                    borderRadius: BorderRadius.circular(20)),
                child: TabBar(
                    indicatorSize: TabBarIndicatorSize.tab,
                    controller: tabController,
                    //indicatorWeight: 10,
                    indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: colorTitulos,
                        border: Border.all(
                            color: Colors.white,
                            width: 2,
                            style: BorderStyle.solid)),
                    labelStyle: TextStyle(
                        color: Colors.white,
                        fontSize: largoActual * 0.018,
                        fontWeight: FontWeight
                            .w400), // Ajusta el tamaño del texto de la pestaña seleccionada
                    unselectedLabelStyle: TextStyle(
                        fontSize: largoActual * 0.018,
                        fontWeight: FontWeight.w300),
                    //labelColor: colorLetra,
                    unselectedLabelColor: colorLetra,
                    tabs: const [
                      Tab(
                        text: "Pendientes",
                        icon: Icon(
                          Icons.assignment_rounded,
                          size: 18,
                        ),
                        iconMargin: EdgeInsets.only(bottom: 1),
                      ),
                      Tab(
                        text: "Entregados",
                        icon: Icon(
                          Icons.assignment_turned_in_rounded,
                          size: 18,
                        ),
                        iconMargin: EdgeInsets.only(bottom: 1),
                      ),
                    ]),
              ),
              //CONTAINER
              Container(
                alignment: Alignment.center,
                margin: EdgeInsets.only(
                  top: largoActual * 0.013,
                ),
                height: largoActual / 1.35,
                width: double.maxFinite,
                child: TabBarView(
                  controller: tabController,
                  children: [
                    //LIST VIEW PENDIENTES
                    listPedidosPendientes.isNotEmpty
                        ? ListView.builder(
                            scrollDirection: Axis.vertical,
                            itemCount: listPedidosPendientes.length,
                            itemBuilder: (context, index) {
                              PedidoCliente pedido =
                                  listPedidosPendientes[index];
                              return GestureDetector(
                                onTap: () {},
                                child: SizedBox(
                                  height: anchoActual * 0.65,
                                  child: Card(
                                    surfaceTintColor: Colors.white,
                                    color: const Color.fromARGB(
                                        255, 255, 255, 255),
                                    elevation: 8,
                                    margin: EdgeInsets.only(
                                      top: largoActual * 0.0068,
                                      bottom: largoActual * 0.013,
                                      left: largoActual * 0.0068,
                                      right: largoActual * 0.0068,
                                    ),
                                    child: Container(
                                      margin: EdgeInsets.all(
                                        largoActual * 0.025,
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Container(
                                                height: largoActual * 0.07,
                                                width: anchoActual * 0.15,
                                                decoration: BoxDecoration(
                                                    color: pedido.colorRecibido,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            80)),
                                                child: Lottie.asset(
                                                    pedido.iconoRecibido),
                                              ),
                                              Container(
                                                width: anchoActual * 0.15,
                                                color: Colors.transparent,
                                                child: Lottie.asset(linea),
                                              ),
                                              Container(
                                                height: largoActual * 0.07,
                                                width: anchoActual * 0.15,
                                                decoration: BoxDecoration(
                                                    color: pedido.colorProceso,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            50)),
                                                child: Lottie.asset(
                                                    pedido.iconoProceso),
                                              ),
                                              Container(
                                                width: anchoActual * 0.15,
                                                color: Colors.transparent,
                                                child: Lottie.asset(linea),
                                              ),
                                              Container(
                                                height: largoActual * 0.07,
                                                width: anchoActual * 0.15,
                                                decoration: BoxDecoration(
                                                    color:
                                                        pedido.colorEntregado,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            50)),
                                                child: Lottie.asset(
                                                    pedido.iconoEntregado),
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                            height: largoActual * 0.02,
                                          ),
                                          Text(
                                            pedido.mensaje,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                fontSize: largoActual * 0.013,
                                                color: colorLetra),
                                          ),
                                          Text(
                                            "${mesyAnio(pedido.fecha).day}/${mesyAnio(pedido.fecha).month}/${mesyAnio(pedido.fecha).year}",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                fontSize: largoActual * 0.013,
                                                color: colorLetra),
                                          ),
                                          Text(
                                            " ${pedido.total}",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                fontSize: largoActual * 0.013,
                                                color: colorLetra),
                                          ),
                                          Text(
                                            pedido.direccion,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                fontSize: largoActual * 0.013,
                                                color: colorLetra),
                                          ),
                                          ElevatedButton(
                                              style: ButtonStyle(
                                                  backgroundColor:
                                                      WidgetStateProperty.all(
                                                          const Color.fromARGB(
                                                              255,
                                                              87,
                                                              113,
                                                              255))),
                                              onPressed: () {},
                                              child: Text(
                                                "Anular pedido",
                                                style: GoogleFonts.manrope(
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.w400),
                                              ))
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            })
                        : Center(
                            child: Container(
                            child: Text(
                              "Todavía no hay pedidos",
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold, fontSize: 20.sp),
                            ),
                          )),
                    //LIST VIEW ENTREGADOS
                    listPedidosPasados.isNotEmpty
                        ? ListView.builder(
                            scrollDirection: Axis.vertical,
                            itemCount: listPedidosPasados.length,
                            itemBuilder: (context, index) {
                              PedidoCliente pedido = listPedidosPasados[index];
                              return GestureDetector(
                                onTap: () {},
                                child: SizedBox(
                                  height: anchoActual * 0.651,
                                  child: Card(
                                    surfaceTintColor: Colors.white,
                                    color: Colors.white,
                                    elevation: 8,
                                    margin: EdgeInsets.only(
                                      top: largoActual * 0.0068,
                                      bottom: largoActual * 0.013,
                                      left: largoActual * 0.0068,
                                      right: largoActual * 0.0068,
                                    ),
                                    child: Container(
                                      margin: EdgeInsets.all(
                                        largoActual * 0.025,
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                height: anchoActual * 0.2,
                                                width: anchoActual * 0.2,
                                                child: Stack(
                                                  children: [
                                                    Positioned.fill(
                                                      child: Align(
                                                        alignment:
                                                            Alignment.center,
                                                        child: Container(
                                                          height: largoActual *
                                                              0.07,
                                                          width: anchoActual *
                                                              0.15,
                                                          decoration: BoxDecoration(
                                                              color: pedido
                                                                  .colorEntregado,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          80)),
                                                        ),
                                                      ),
                                                    ),
                                                    Positioned.fill(
                                                      child: Align(
                                                        alignment:
                                                            Alignment.center,
                                                        child: SizedBox(
                                                            width: anchoActual *
                                                                pedido
                                                                    .anchoIcono,
                                                            child: Lottie.asset(
                                                                pedido
                                                                    .iconoEntregado)),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Column(
                                                children: [
                                                  SizedBox(
                                                    width: anchoActual * 0.54,
                                                    child: Text(
                                                      pedido.mensaje,
                                                      textAlign: TextAlign.left,
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontSize:
                                                              largoActual *
                                                                  0.019,
                                                          color: colorLetra),
                                                    ),
                                                  ),
                                                ],
                                              )
                                            ],
                                          ),
                                          SizedBox(
                                            height: largoActual * 0.02,
                                          ),
                                          Text(
                                            "Fecha: ${mesyAnio(pedido.fecha).day}/${mesyAnio(pedido.fecha).month}/${mesyAnio(pedido.fecha).year}",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                fontSize: largoActual * 0.014,
                                                color: colorLetra),
                                          ),
                                          Text(
                                            "Total: ${pedido.total}",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                fontSize: largoActual * 0.014,
                                                color: colorLetra),
                                          ),
                                          Text(
                                            "Dirección: ${pedido.direccion}",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                fontSize: largoActual * 0.014,
                                                color: colorLetra),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            })
                        : Center(
                            child: Container(
                            child: Text(
                              "Todavía no hay pedidos",
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold, fontSize: 20.sp),
                            ),
                          )),
                  ],
                ),
              ),
            ]),
          )),
        ));
  }
}
