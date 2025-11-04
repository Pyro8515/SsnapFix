import 'package:flutter/material.dart';

class BookingPage extends StatefulWidget {
  const BookingPage({super.key, this.service});

  final String? service;

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final _addressController = TextEditingController();
  DateTimeRange? _timeRange;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final now = DateTime.now();
    final start = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      initialDate: now,
    );
    if (start == null) return;

    final timeOfDay = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 2))),
    );
    if (timeOfDay == null) return;

    final startDateTime = DateTime(
      start.year,
      start.month,
      start.day,
      timeOfDay.hour,
      timeOfDay.minute,
    );
    setState(() {
      _timeRange = DateTimeRange(
        start: startDateTime,
        end: startDateTime.add(const Duration(hours: 2)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service ?? 'Choose a service';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book a pro'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Service',
                border: OutlineInputBorder(),
              ),
              child: Text(service),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Time window'),
              subtitle: Text(
                _timeRange == null
                    ? 'Pick a preferred arrival window'
                    : '${_timeRange!.start} - ${_timeRange!.end}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.schedule),
                onPressed: _pickTime,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {},
              child: const Text('Continue to payment'),
            ),
          ],
        ),
      ),
    );
  }
}
