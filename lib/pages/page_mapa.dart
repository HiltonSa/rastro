import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:rastro/services/service_location.dart';
import 'package:intl/intl.dart';
import 'package:flutter_compass/flutter_compass.dart';

class PageMapa extends StatefulWidget {
  const PageMapa({super.key});

  @override
  State<PageMapa> createState() => _PageMapaState();
}

class _PageMapaState extends State<PageMapa> {
  late StreamSubscription _streamDirecao;
  bool _rastreando = false;
  List<PosicaoMapa> posicoes = [];

  ServiceLocation serviceLocation = ServiceLocation();
  Position? posicaoAtual;
  double? heading;

  late final MapController mapController;

  PosicaoMapa posicaoMapa = PosicaoMapa(
      index: 0,
      descricao: 'Aguardando Localização',
      endereco: '',
      bairro: '',
      cidade: '',
      velocidade: 0.0,
      direcao: 0.0,
      latitude: 0.0,
      longitude: 0.0);

  _getAlteracoesPosicao(Position position) async {
    posicaoAtual = position;
    if (posicaoAtual != null) {
      _atualizaTela();
    }
  }

  _atualizaTela() {
    retornaEndereco();
    print('heading: $heading');
    _moveMapa();
  }

  _moveMapa() {
    mapController.moveAndRotate(
        LatLng(posicaoAtual!.latitude, posicaoAtual!.longitude), 18, heading!);
    setState(() {});
  }

  _atualizaDirecao(CompassEvent? event) async {
    if (event != null) {
      heading = event.heading!;
      _moveMapa();
    }
  }

  retornaEndereco() async {
    print('retornaEndereco');
    await serviceLocation
        .getEnderecoCoordenadas(
            LatLng(posicaoAtual!.latitude, posicaoAtual!.longitude))
        .then((value) {
      // print('value: ${value}');
      if (value['result'] == 'ok') {
        posicaoMapa = PosicaoMapa(
            index: 0,
            descricao: value['nome'] ?? '',
            endereco: value['endereco'] ?? '',
            bairro: value['bairro'] ?? '',
            cidade: value['cidade'] ?? '',
            velocidade: posicaoAtual!.speed,
            direcao: posicaoAtual!.heading,
            latitude: posicaoAtual!.latitude,
            longitude: posicaoAtual!.longitude);

        posicoes.insert(0, posicaoMapa);
      }
    });
  }

  @override
  void initState() {
    super.initState();

    mapController = MapController();
    // serviceLocation.startPositionStream(_getAlteracoesPosicao);
    recuperaPosicaonicial();
    _streamDirecao = FlutterCompass.events!.listen(_atualizaDirecao);
  }

  recuperaPosicaonicial() async {
    posicaoAtual = await serviceLocation.getPosicaoAtual();
    retornaEndereco();
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
    serviceLocation.stopPositionStream();
    _streamDirecao.cancel();
  }

  @override
  Widget build(BuildContext context) {
    Size tamanho = MediaQuery.of(context).size;

    _mostraMensagem(String msg) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }

    _comecar() async {
      if (!_rastreando) {
        posicoes = [];
        _rastreando = true;
        serviceLocation.startPositionStream(_getAlteracoesPosicao);
      }
    }

    _parar() {
      if (_rastreando) {
        serviceLocation.stopPositionStream();
        setState(() {
          _rastreando = false;
        });
      }
    }

    return Scaffold(
      // appBar: AppBar(
      //   backgroundColor: Colors.white70,
      //   bottomOpacity: 40.0,
      //   centerTitle: true,
      //   title: const Text('Rastro'),
      // ),
      body: Stack(alignment: Alignment.bottomCenter, children: [
        posicaoAtual == null
            ? const Center(child: Text('Aguardando localização...'))
            : StreamBuilder<CompassEvent>(
                stream: FlutterCompass.events,
                builder: (context, snapshot) {
                  return FlutterMap(
                    mapController: mapController,
                    options: MapOptions(
                      initialCenter: LatLng(
                        posicaoAtual!.latitude,
                        posicaoAtual!.longitude,
                      ),
                      initialZoom: 18,
                      maxZoom: 18,
                      minZoom: 3,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'br.com.corvette.rastro',
                      ),
                      MarkerLayer(markers: [
                        Marker(
                            point: LatLng(
                                posicaoMapa.latitude, posicaoMapa.longitude),
                            child: Icon(
                              _rastreando
                                  ? Icons.navigation
                                  : Icons.location_pin,
                              color: _rastreando ? Colors.blue : Colors.red,
                            ))
                      ]),
                      PolylineLayer(polylines: [
                        Polyline(
                            strokeWidth: 5,
                            color: Colors.blue,
                            points: posicoes
                                .map((e) => LatLng(e.latitude, e.longitude))
                                .toList()),
                      ])
                    ],
                  );
                }),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: _comecar,
            onDoubleTap: _parar,
            child: Container(
              padding: const EdgeInsets.all(8),
              height: tamanho.height * 0.2,
              width: tamanho.width * 0.95,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(15)),
                color: !_rastreando
                    ? const Color.fromARGB(144, 76, 175, 79)
                    : const Color.fromARGB(129, 244, 67, 54),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    height: tamanho.height * .18,
                    width: tamanho.width * .27,
                    decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(15)),
                        color: Colors.black38),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.asset('assets/images/cadrant.png'),
                          Transform.rotate(
                            angle: (heading! * pi / 180) * -1,
                            child: Image.asset('assets/images/compass.png'),
                          ),
                          Positioned(
                            top: 70,
                            child: Text(
                              '${posicaoMapa.direcao.ceil()}°',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        posicaoMapa.descricao,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        posicaoMapa.endereco,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        posicaoMapa.bairro,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        posicaoMapa.cidade,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                      // Text(posicaoAtual.toString()),
                      const SizedBox(
                        height: 10,
                      ),
                      Text(
                        !_rastreando
                            ? 'Toque para rastrear'
                            : 'Duplo toque para parar o rastreio',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        NumberFormat('###.#', 'pt-BR').format(posicaoMapa.kmph),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 40,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'Km/h',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        )
      ]),
    );
  }
}
