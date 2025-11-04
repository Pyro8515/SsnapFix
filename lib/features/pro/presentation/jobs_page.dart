import 'package:flutter/material.dart';

class ProJobsPage extends StatelessWidget {
  const ProJobsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jobs')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Available jobs',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemBuilder: (_, index) => Card(
                    child: ListTile(
                      title: Text('Job #${index + 1}'),
                      subtitle: const Text('Service • Address • Window'),
                      trailing: FilledButton(
                        onPressed: () {},
                        child: const Text('Accept'),
                      ),
                    ),
                  ),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
