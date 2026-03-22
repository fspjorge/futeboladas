import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class GameMapDetail extends StatelessWidget {
  final LatLng pos;
  final String title;
  const GameMapDetail({super.key, required this.pos, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(target: pos, zoom: 16),
            markers: {
              Marker(markerId: const MarkerId('location'), position: pos),
            },
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            compassEnabled: true,
          ),
          // Positioned(
          //   top: 0,
          //   left: 0,
          //   right: 0,
          //   height: 100,
          //   child: Container(
          //     decoration: const BoxDecoration(
          //       gradient: LinearGradient(
          //         begin: Alignment.topCenter,
          //         end: Alignment.bottomCenter,
          //         colors: [Color(0xFF0F172A), Colors.transparent],
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}
