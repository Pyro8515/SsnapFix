import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../shared/theme/app_theme.dart';

/// Professional onboarding page with 5-step flow
class ProOnboardingPage extends ConsumerStatefulWidget {
  const ProOnboardingPage({super.key});

  @override
  ConsumerState<ProOnboardingPage> createState() => _ProOnboardingPageState();
}

class _ProOnboardingPageState extends ConsumerState<ProOnboardingPage> {
  int _currentStep = 0;
  final PageController _pageController = PageController();
  final ImagePicker _imagePicker = ImagePicker();

  // Step 1: Profile Information
  final _nameController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _bioController = TextEditingController();
  final _experienceController = TextEditingController();
  XFile? _profilePhoto;
  bool _isLicensed = false;
  bool _isInsured = false;

  // Step 2: Service Categories
  final List<String> _selectedServices = [];
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
  final Map<String, bool> _pricingPreferences = {}; // true = platform, false = custom
  XFile? _certificationPhoto;
  XFile? _workPhoto;

  // Step 3: Location & Service Area
  final _addressController = TextEditingController();
  final _zipController = TextEditingController();
  double? _latitude;
  double? _longitude;
  double _serviceRadius = 25.0; // miles

  // Step 4: Availability
  final Map<int, bool> _availableDays = {
    0: false, // Sunday
    1: false, // Monday
    2: false, // Tuesday
    3: false, // Wednesday
    4: false, // Thursday
    5: false, // Friday
    6: false, // Saturday
  };
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 0);
  bool _acceptsEmergencyCalls = false;
  bool _isAvailable = false;

  // Step 5: Payment Setup
  String? _stripeAccountId;
  bool _termsAccepted = false;

  @override
  void dispose() {
    _nameController.dispose();
    _businessNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _experienceController.dispose();
    _addressController.dispose();
    _zipController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 4) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    // TODO: Save onboarding data to backend
    // TODO: Setup Stripe Connect account
    // TODO: Create professional profile
    // TODO: Navigate to verification
    
    if (mounted) {
      context.go('/pro/verification');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  _buildStep1Profile(),
                  _buildStep2Services(),
                  _buildStep3Location(),
                  _buildStep4Availability(),
                  _buildStep5Payment(),
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
        children: List.generate(5, (index) {
          final isActive = index <= _currentStep;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(
                right: index < 4 ? AppTokens.spacingS : 0,
              ),
              height: 4,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : AppColors.borderPro,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep1Profile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTokens.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Professional Profile',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: AppTokens.spacingS),
          Text(
            'Step 1 of 5',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppTokens.spacingXL),
          
          // Profile Photo
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.surfacePro,
                  backgroundImage: _profilePhoto != null
                      ? Image.file(
                          File(_profilePhoto!.path),
                          fit: BoxFit.cover,
                        ).image
                      : null,
                  child: _profilePhoto == null
                      ? const Icon(Icons.person, size: 48)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primary,
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, size: 16),
                      color: Colors.white,
                      onPressed: () async {
                        final photo = await _imagePicker.pickImage(
                          source: ImageSource.gallery,
                        );
                        if (photo != null) {
                          setState(() => _profilePhoto = photo);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.spacingXL),
          
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              hintText: 'John Doe',
            ),
          ),
          const SizedBox(height: AppTokens.spacingM),
          
          TextField(
            controller: _businessNameController,
            decoration: const InputDecoration(
              labelText: 'Business Name (Optional)',
              hintText: 'ABC Plumbing Services',
            ),
          ),
          const SizedBox(height: AppTokens.spacingM),
          
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              hintText: '(555) 123-4567',
            ),
          ),
          const SizedBox(height: AppTokens.spacingM),
          
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'john@example.com',
            ),
          ),
          const SizedBox(height: AppTokens.spacingM),
          
          TextField(
            controller: _bioController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Bio',
              hintText: 'Tell us about yourself and your experience...',
            ),
          ),
          const SizedBox(height: AppTokens.spacingM),
          
          TextField(
            controller: _experienceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Years of Experience',
              hintText: '5',
              suffixText: 'years',
            ),
          ),
          const SizedBox(height: AppTokens.spacingM),
          
          SwitchListTile(
            value: _isLicensed,
            onChanged: (value) => setState(() => _isLicensed = value),
            title: const Text('Are you licensed?'),
          ),
          SwitchListTile(
            value: _isInsured,
            onChanged: (value) => setState(() => _isInsured = value),
            title: const Text('Are you insured?'),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2Services() {
    final services = [
      {'code': 'plumbing', 'name': 'Plumbing', 'icon': Icons.plumbing},
      {'code': 'electrical', 'name': 'Electrical', 'icon': Icons.electrical_services},
      {'code': 'hvac', 'name': 'HVAC', 'icon': Icons.ac_unit},
      {'code': 'locksmith', 'name': 'Locksmith', 'icon': Icons.lock},
      {'code': 'handyman', 'name': 'Handyman', 'icon': Icons.build},
      {'code': 'cleaning', 'name': 'Cleaning', 'icon': Icons.cleaning_services},
      {'code': 'landscaping', 'name': 'Landscaping', 'icon': Icons.grass},
      {'code': 'painting', 'name': 'Painting', 'icon': Icons.brush},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTokens.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Service Categories',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: AppTokens.spacingS),
          Text(
            'Step 2 of 5 - Select the trades you work in',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppTokens.spacingXL),
          
          Wrap(
            spacing: AppTokens.spacingM,
            runSpacing: AppTokens.spacingM,
            children: services.map((service) {
              final isSelected = _selectedServices.contains(service['code']);
              return FilterChip(
                label: Text(service['name'] as String),
                selected: isSelected,
                avatar: Icon(service['icon'] as IconData, size: 20),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedServices.add(service['code'] as String);
                    } else {
                      _selectedServices.remove(service['code']);
                    }
                  });
                },
              );
            }).toList(),
          ),
          
          if (_selectedServices.isNotEmpty) ...[
            const SizedBox(height: AppTokens.spacingXL),
            Text(
              'Selected Services',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTokens.spacingM),
            ..._selectedServices.map((serviceCode) {
              final service = services.firstWhere(
                (s) => s['code'] == serviceCode,
              );
              return Card(
                margin: const EdgeInsets.only(bottom: AppTokens.spacingM),
                child: Padding(
                  padding: const EdgeInsets.all(AppTokens.spacingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service['name'] as String,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppTokens.spacingS),
                      Wrap(
                        spacing: AppTokens.spacingS,
                        children: (_serviceSubtasks[serviceCode] ?? [])
                            .map((subtask) => Chip(
                                  label: Text(subtask),
                                  visualDensity: VisualDensity.compact,
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: AppTokens.spacingS),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text('Platform Pricing'),
                              value: true,
                              groupValue: _pricingPreferences[serviceCode],
                              onChanged: (value) {
                                setState(() {
                                  _pricingPreferences[serviceCode] = value ?? true;
                                });
                              },
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text('Custom Pricing'),
                              value: false,
                              groupValue: _pricingPreferences[serviceCode],
                              onChanged: (value) {
                                setState(() {
                                  _pricingPreferences[serviceCode] = value ?? false;
                                });
                              },
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
            
            const SizedBox(height: AppTokens.spacingL),
            Text(
              'Certifications & Work Photos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTokens.spacingM),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final photo = await _imagePicker.pickImage(
                        source: ImageSource.gallery,
                      );
                      if (photo != null) {
                        setState(() => _certificationPhoto = photo);
                      }
                    },
                    icon: const Icon(Icons.badge),
                    label: Text(_certificationPhoto == null ? 'Add Cert' : 'Cert Added'),
                  ),
                ),
                const SizedBox(width: AppTokens.spacingM),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final photo = await _imagePicker.pickImage(
                        source: ImageSource.gallery,
                      );
                      if (photo != null) {
                        setState(() => _workPhoto = photo);
                      }
                    },
                    icon: const Icon(Icons.photo_library),
                    label: Text(_workPhoto == null ? 'Add Work' : 'Work Added'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStep3Location() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTokens.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location & Service Area',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: AppTokens.spacingS),
          Text(
            'Step 3 of 5',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppTokens.spacingXL),
          
          TextField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Service Address',
              hintText: '123 Main St',
              prefixIcon: Icon(Icons.home_outlined),
            ),
          ),
          const SizedBox(height: AppTokens.spacingM),
          
          TextField(
            controller: _zipController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'ZIP Code',
              hintText: '10001',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
          ),
          const SizedBox(height: AppTokens.spacingM),
          
          OutlinedButton.icon(
            onPressed: () async {
              // TODO: Get current location via geolocator
              // TODO: Reverse geocode to fill address fields
            },
            icon: const Icon(Icons.my_location),
            label: const Text('Use Current Location'),
          ),
          const SizedBox(height: AppTokens.spacingXL),
          
          Text(
            'Service Radius',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppTokens.spacingM),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _serviceRadius,
                  min: 5,
                  max: 50,
                  divisions: 9,
                  label: '${_serviceRadius.toStringAsFixed(0)} miles',
                  onChanged: (value) => setState(() => _serviceRadius = value),
                ),
              ),
              SizedBox(
                width: 60,
                child: Text(
                  '${_serviceRadius.toStringAsFixed(0)} mi',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep4Availability() {
    final days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTokens.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Availability',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: AppTokens.spacingS),
          Text(
            'Step 4 of 5',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppTokens.spacingXL),
          
          Text(
            'Available Days',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppTokens.spacingM),
          ...List.generate(7, (index) {
            return CheckboxListTile(
              value: _availableDays[index] ?? false,
              onChanged: (value) {
                setState(() => _availableDays[index] = value ?? false);
              },
              title: Text(days[index]),
              dense: true,
            );
          }),
          const SizedBox(height: AppTokens.spacingXL),
          
          Text(
            'Working Hours',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppTokens.spacingM),
          Row(
            children: [
              Expanded(
                child: ListTile(
                  title: const Text('Start Time'),
                  subtitle: Text(_startTime.format(context)),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _startTime,
                    );
                    if (time != null) {
                      setState(() => _startTime = time);
                    }
                  },
                ),
              ),
              Expanded(
                child: ListTile(
                  title: const Text('End Time'),
                  subtitle: Text(_endTime.format(context)),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _endTime,
                    );
                    if (time != null) {
                      setState(() => _endTime = time);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.spacingM),
          
          SwitchListTile(
            value: _acceptsEmergencyCalls,
            onChanged: (value) => setState(() => _acceptsEmergencyCalls = value),
            title: const Text('Accept Emergency Calls'),
            subtitle: const Text('Available 24/7 for urgent jobs'),
          ),
          const SizedBox(height: AppTokens.spacingM),
          
          SwitchListTile(
            value: _isAvailable,
            onChanged: (value) => setState(() => _isAvailable = value),
            title: const Text('Set as Available'),
            subtitle: const Text('Start receiving job offers immediately'),
          ),
        ],
      ),
    );
  }

  Widget _buildStep5Payment() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTokens.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Setup',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: AppTokens.spacingS),
          Text(
            'Step 5 of 5 - Connect your Stripe account',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppTokens.spacingXL),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.spacingM),
              child: Column(
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 48,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: AppTokens.spacingM),
                  Text(
                    'Secure Payment Processing',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppTokens.spacingS),
                  Text(
                    'GetDone uses Stripe Connect to securely process payments. Your bank account details are never stored on our servers.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTokens.spacingL),
          
          if (_stripeAccountId == null)
            FilledButton.icon(
              onPressed: () async {
                // TODO: Setup Stripe Connect account
                // TODO: Show Stripe Connect onboarding
              },
              icon: const Icon(Icons.account_balance),
              label: const Text('Connect Stripe Account'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            )
          else
            Card(
              child: ListTile(
                leading: const Icon(Icons.check_circle, color: AppColors.success),
                title: const Text('Stripe Account Connected'),
                subtitle: const Text('Account ending in ••••'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // TODO: Edit Stripe account
                  },
                ),
              ),
            ),
          const SizedBox(height: AppTokens.spacingL),
          
          CheckboxListTile(
            value: _termsAccepted,
            onChanged: (value) => setState(() => _termsAccepted = value ?? false),
            title: const Text('I agree to the Terms of Service'),
            subtitle: TextButton(
              onPressed: () {
                // TODO: Show terms
              },
              child: const Text('Read Terms'),
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(AppTokens.spacingM),
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
              onPressed: _currentStep == 4 && (!_termsAccepted || _stripeAccountId == null)
                  ? null
                  : _nextStep,
              child: Text(_currentStep == 4 ? 'Complete' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }
}

