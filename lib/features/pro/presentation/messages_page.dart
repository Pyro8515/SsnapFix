import 'package:flutter/material.dart';

class ProMessagesPage extends StatelessWidget {
  const ProMessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemBuilder: (_, index) => ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text('Job chat #${index + 1}'),
            subtitle: const Text('Tap to open conversation'),
            onTap: () {},
          ),
        ),
      ),
    );
  }
}
