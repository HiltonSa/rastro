import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';

typedef PositionCallback = Function(Position position);

class ServiceLocation {
  final GeolocatorPlatform _geolocatorPlatform = GeolocatorPlatform.instance;
  late StreamSubscription<Position> _positionStream;

  Future<Position?> getPosicaoAtual() async {
    bool temPermissao = await _handlePermission();
    return temPermissao ? await _geolocatorPlatform.getCurrentPosition() : null;
  }

  Future<bool> _handlePermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await _geolocatorPlatform.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the

      return false;
    }

    permission = await _geolocatorPlatform.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _geolocatorPlatform.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.

        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return false;
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.

    return true;
  }

  Future<void> startPositionStream(Function(Position position) callback) async {
    bool temPermissao = await _handlePermission();
    if (temPermissao) {
      _positionStream = Geolocator.getPositionStream(
              locationSettings: const LocationSettings(
                  accuracy: LocationAccuracy.bestForNavigation))
          .listen(callback);
    }
  }

  Future<void> stopPositionStream() async {
    await _positionStream.cancel();
  }

  Future<Map<String, String>> getEnderecoCoordenadas(LatLng coordenadas) async {
    Map<String, String> retorno = {};
    try {
      List<Placemark> locais = await placemarkFromCoordinates(
        coordenadas.latitude,
        coordenadas.longitude,
      );
      Placemark local = locais[0];
      retorno = {
        'result': 'ok',
        'nome': '${local.name}',
        'endereco': '${local.thoroughfare}',
        'bairro': '${local.subLocality}',
        'cidade': '${local.subAdministrativeArea}'
      };
    } catch (e) {
      retorno = {'result': 'erro', 'nome': e.toString()};
    }
    return retorno;
  }
}

class PosicaoMapa {
  int index;
  String descricao;
  String endereco;
  String bairro;
  String cidade;
  double latitude;
  double longitude;
  double velocidade;
  double direcao;
  PosicaoMapa({
    required this.index,
    required this.descricao,
    required this.endereco,
    required this.bairro,
    required this.cidade,
    required this.latitude,
    required this.longitude,
    required this.velocidade,
    required this.direcao,
  });
  double get kmph {
    return velocidade / 3.6;
  }
}
