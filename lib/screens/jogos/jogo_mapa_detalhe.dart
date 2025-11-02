import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class JogoMapaDetalhe extends StatelessWidget {
  final LatLng pos;
  final String titulo;
  const JogoMapaDetalhe({super.key, required this.pos, required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: CameraPosition(target: pos, zoom: 16),
        markers: {Marker(markerId: const MarkerId('local'), position: pos)},
        myLocationButtonEnabled: false,
        zoomControlsEnabled: true,
        compassEnabled: true,
      ),
    );
  }
}

