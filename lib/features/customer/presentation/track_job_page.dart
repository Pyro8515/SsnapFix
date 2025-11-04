import 'package:flutter/material.dart';

class TrackJobPage extends StatelessWidget {
  const TrackJobPage({super.key, required this.jobId});

  final String jobId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Job $jobId')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tracking job $jobId',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                'A map and ETA will appear here once the job is on the way.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.message_outlined),
                label: const Text('Message your pro'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
