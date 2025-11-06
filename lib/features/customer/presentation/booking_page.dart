import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../../app/router/routes.dart';
import '../../../shared/data/jobs_repository.dart';
import '../../../shared/theme/app_theme.dart';

/// Enhanced booking page with subtask selection, photo upload, pricing summary
class BookingPage extends ConsumerStatefulWidget {
  const BookingPage({super.key, this.service});

  final String? service;

  @override
  ConsumerState<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends ConsumerState<BookingPage> {
  final _pageController = PageController();
  int _currentStep = 0;
  final ImagePicker _imagePicker = ImagePicker();

  // Step 1: Service & Subtask
  String? _selectedService;
  String? _selectedSubtask;
  final Map<String, List<String>> _serviceSubtasks = {
    'plumbing': ['Leaky Faucet', 'Clogged Drain', 'Water Heater', 'Pipe Repair', 'Installation'],
    'electrical': ['Outlet Repair', 'Light Fixture', 'Panel Upgrade', 'Wiring', 'Installation'],
    'hvac': ['AC Repair', 'Heating Repair', 'Installation', 'Maintenance', 'Ductwork'],
    'locksmith': ['Lock Repair', 'Key Duplication', 'Lock Installation', 'Safe Opening', 'Emergency'],
    'handyman': ['Drywall', 'Painting', 'Carpentry', 'Assembly', 'General Repair'],
    'cleaning': ['Deep Clean', 'Regular Clean', 'Move-in/out', 'Carpet', 'Window'],
    'landscaping': ['Lawn Care', 'Tree Trimming', 'Mulching', 'Planting', 'Irrigation'],
    'painting': ['Interior', 'Exterior', 'Cabinet', 'Touch-up', 'Color Consultation'],
  };

  // Step 2: Address & Location
  final _addressController = TextEditingController();
  double? _latitude;
  double? _longitude;
  bool _isLoadingLocation = false;

  // Step 3: Time & Photo
  bool _isASAP = true;
  DateTime? _scheduledStart;
  DateTime? _scheduledEnd;
  XFile? _photo;
  final _notesController = TextEditingController();

  // Step 4: Pricing & Payment
  int? _priceCents;
  bool _isCreatingJob = false;

  @override
  void initState() {
    super.initState();
    _selectedService = widget.service?.toLowerCase();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _isLoadingLocation = false;
      });
      await _reverseGeocode();
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: $e')),
        );
      }
    }
  }

  Future<void> _reverseGeocode() async {
    if (_latitude == null || _longitude == null) return;
    try {
      final placemarks = await placemarkFromCoordinates(_latitude!, _longitude!);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _addressController.text = [
            place.street,
            place.locality,
            place.administrativeArea,
            place.postalCode,
          ].where((s) => s != null && s.isNotEmpty).join(', ');
        });
      }
    } catch (e) {
      // Ignore geocoding errors
    }
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _createJob();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _createJob() async {
    if (_selectedService == null || _latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    setState(() => _isCreatingJob = true);

    try {
      final jobsRepo = ref.read(jobsRepositoryProvider);
      
      final job = await jobsRepo.createJob(
        serviceCode: _selectedService!,
        address: {
          'street': _addressController.text,
          'lat': _latitude,
          'lng': _longitude,
        },
        scheduledStart: _isASAP ? null : _scheduledStart?.toIso8601String(),
        scheduledEnd: _isASAP ? null : _scheduledEnd?.toIso8601String(),
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      // Trigger matching
      await jobsRepo.matchJob(job.id);

      if (mounted) {
        context.go('${AppRoute.customerTrack.path}/${job.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating job: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreatingJob = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book a Service'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            _buildProgressIndicator(),
            
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1Service(),
                  _buildStep2Address(),
                  _buildStep3Time(),
                  _buildStep4Pricing(),
                ],
              ),
            ),
            
            // Navigation buttons
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(AppTokens.spacingM),
      child: Row(
        children: List.generate(4, (index) {
          final isActive = index <= _currentStep;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(
                right: index < 3 ? AppTokens.spacingS : 0,
              ),
              height: 4,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : AppColors.borderCustomer,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep1Service() {
    final services = [
      {'code': 'plumbing', 'name': 'Plumbing', 'icon': Icons.plumbing, 'color': AppColors.servicePlumbing},
      {'code': 'electrical', 'name': 'Electrical', 'icon': Icons.electrical_services, 'color': AppColors.serviceElectrical},
      {'code': 'hvac', 'name': 'HVAC', 'icon': Icons.ac_unit, 'color': AppColors.serviceHVAC},
      {'code': 'locksmith', 'name': 'Locksmith', 'icon': Icons.lock, 'color': AppColors.serviceLocksmith},
      {'code': 'handyman', 'name': 'Handyman', 'icon': Icons.build, 'color': AppColors.serviceHandyman},
      {'code': 'cleaning', 'name': 'Cleaning', 'icon': Icons.cleaning_services, 'color': AppColors.serviceCleaning},
      {'code': 'landscaping', 'name': 'Landscaping', 'icon': Icons.grass, 'color': AppColors.serviceLandscaping},
      {'code': 'painting', 'name': 'Painting', 'icon': Icons.brush, 'color': AppColors.servicePainting},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTokens.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What needs fixing?',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: AppTokens.spacingS),
          Text(
            'Select a service category',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppTokens.spacingXL),
          
          Wrap(
            spacing: AppTokens.spacingM,
            runSpacing: AppTokens.spacingM,
            children: services.map((service) {
              final isSelected = _selectedService == service['code'];
              return FilterChip(
                label: Text(service['name'] as String),
                selected: isSelected,
                avatar: Icon(
                  service['icon'] as IconData,
                  size: 20,
                  color: isSelected ? Colors.white : (service['color'] as Color),
                ),
                onSelected: (selected) {
                  setState(() {
                    _selectedService = selected ? service['code'] as String : null;
                    _selectedSubtask = null;
                  });
                },
              );
            }).toList(),
          ),
          
          if (_selectedService != null && _serviceSubtasks.containsKey(_selectedService)) ...[
            const SizedBox(height: AppTokens.spacingXL),
            Text(
              'What specifically?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTokens.spacingM),
            Wrap(
              spacing: AppTokens.spacingM,
              runSpacing: AppTokens.spacingM,
              children: _serviceSubtasks[_selectedService]!.map((subtask) {
                final isSelected = _selectedSubtask == subtask;
                return FilterChip(
                  label: Text(subtask),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedSubtask = selected ? subtask : null);
                  },
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStep2Address() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTokens.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Where is the job?',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: AppTokens.spacingS),
          Text(
            'We\'ll match you with pros nearby',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppTokens.spacingXL),
          
          TextField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Address',
              hintText: '123 Main St',
              prefixIcon: Icon(Icons.home_outlined),
            ),
          ),
          const SizedBox(height: AppTokens.spacingM),
          
          OutlinedButton.icon(
            onPressed: _isLoadingLocation ? null : _getCurrentLocation,
            icon: _isLoadingLocation
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
            label: Text(_isLoadingLocation ? 'Getting location...' : 'Use Current Location'),
          ),
          
          if (_latitude != null && _longitude != null) ...[
            const SizedBox(height: AppTokens.spacingM),
            Card(
              color: AppColors.success.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(AppTokens.spacingM),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.success),
                    const SizedBox(width: AppTokens.spacingM),
                    Expanded(
                      child: Text(
                        'Location found: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStep3Time() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTokens.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'When do you need help?',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: AppTokens.spacingS),
          Text(
            'ASAP or schedule for later',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppTokens.spacingXL),
          
          Card(
            child: RadioListTile<bool>(
              title: const Text('ASAP'),
              subtitle: const Text('Get a pro as soon as possible'),
              value: true,
              groupValue: _isASAP,
              onChanged: (value) => setState(() => _isASAP = value ?? true),
            ),
          ),
          const SizedBox(height: AppTokens.spacingM),
          Card(
            child: RadioListTile<bool>(
              title: const Text('Schedule'),
              subtitle: const Text('Pick a specific time'),
              value: false,
              groupValue: _isASAP,
              onChanged: (value) => setState(() => _isASAP = value ?? false),
            ),
          ),
          
          if (!_isASAP) ...[
            const SizedBox(height: AppTokens.spacingXL),
            ListTile(
              title: const Text('Preferred Time'),
              subtitle: Text(
                _scheduledStart == null
                    ? 'Select date and time'
                    : '${_scheduledStart!.toLocal().toString().split('.')[0]}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (date == null) return;
                
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (time == null) return;
                
                setState(() {
                  _scheduledStart = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    time.hour,
                    time.minute,
                  );
                  _scheduledEnd = _scheduledStart!.add(const Duration(hours: 2));
                });
              },
            ),
          ],
          
          const SizedBox(height: AppTokens.spacingXL),
          Text(
            'Optional: Upload a photo',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppTokens.spacingM),
          
          if (_photo != null)
            Card(
              child: Stack(
                children: [
                  Image.file(
                    File(_photo!.path),
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _photo = null),
                    ),
                  ),
                ],
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: () async {
                final photo = await _imagePicker.pickImage(source: ImageSource.gallery);
                if (photo != null) {
                  setState(() => _photo = photo);
                }
              },
              icon: const Icon(Icons.photo_library),
              label: const Text('Add Photo'),
            ),
          
          const SizedBox(height: AppTokens.spacingXL),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Additional Notes (Optional)',
              hintText: 'Any special instructions or details...',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep4Pricing() {
    // Mock pricing - in production, this would come from the service
    final basePrice = 50.0;
    final diagnosticFee = 25.0;
    final total = basePrice + diagnosticFee;
    _priceCents = (total * 100).toInt();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTokens.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review & Confirm',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: AppTokens.spacingS),
          Text(
            'Review your booking details',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppTokens.spacingXL),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Service',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppTokens.spacingS),
                  Text(
                    '${_selectedService?.toUpperCase()} - ${_selectedSubtask ?? "General"}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTokens.spacingM),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Location',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppTokens.spacingS),
                  Text(
                    _addressController.text.isEmpty ? 'Not set' : _addressController.text,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTokens.spacingM),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Time',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppTokens.spacingS),
                  Text(
                    _isASAP ? 'ASAP' : (_scheduledStart?.toLocal().toString().split('.')[0] ?? 'Not set'),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTokens.spacingXL),
          
          Card(
            color: AppColors.surfaceCustomer,
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pricing Summary',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppTokens.spacingM),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Base Fee', style: Theme.of(context).textTheme.bodyLarge),
                      Text('\$${basePrice.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                  const SizedBox(height: AppTokens.spacingS),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Diagnostic Fee', style: Theme.of(context).textTheme.bodyLarge),
                      Text('\$${diagnosticFee.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        '\$${total.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTokens.spacingM),
          
          Card(
            color: AppColors.success.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.spacingM),
              child: Row(
                children: [
                  Icon(Icons.lock_outline, color: AppColors.success),
                  const SizedBox(width: AppTokens.spacingM),
                  Expanded(
                    child: Text(
                      'Payment will be authorized on booking and captured when work starts',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(AppTokens.spacingL),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: AppTokens.spacingM),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: _isCreatingJob
                  ? null
                  : (_currentStep == 0 && _selectedService == null)
                      ? null
                      : (_currentStep == 1 && _latitude == null)
                          ? null
                          : _nextStep,
              child: _isCreatingJob
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_currentStep == 3 ? 'Confirm Booking' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }
}
