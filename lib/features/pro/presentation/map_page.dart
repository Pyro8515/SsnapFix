import 'package:flutter/material.dart';

class ProMapPage extends StatelessWidget {
  const ProMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map')),
      body: const SafeArea(
        child: Center(
          child: Icon(Icons.map_outlined, size: 96),
        ),
      ),
    );
  }
}
