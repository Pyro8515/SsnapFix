import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/state/account_controller.dart';

/// Customer onboarding page with multi-step flow
class CustomerOnboardingPage extends ConsumerStatefulWidget {
  const CustomerOnboardingPage({super.key});

  @override
  ConsumerState<CustomerOnboardingPage> createState() => _CustomerOnboardingPageState();
}

class _CustomerOnboardingPageState extends ConsumerState<CustomerOnboardingPage> {
  int _currentStep = 0;
  final PageController _pageController = PageController();

  // Step 1: Personal Info
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _smsConsent = false;

  // Step 2: Address
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  double? _latitude;
  double? _longitude;

  // Step 3: Home Details
  String? _homeType;
  bool _hasPets = false;
  final _accessNotesController = TextEditingController();

  // Step 4: Payment
  String? _paymentMethodId;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _accessNotesController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
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
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    // TODO: Save onboarding data to backend
    // TODO: Setup Stripe payment method
    // TODO: Navigate to dashboard
    
    if (mounted) {
      context.go('/customer');
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
                  _buildStep1PersonalInfo(),
                  _buildStep2Address(),
                  _buildStep3HomeDetails(),
                  _buildStep4Payment(),
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

  Widget _buildStep1PersonalInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTokens.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome to GetDone!',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: AppTokens.spacingS),
          Text(
            'Let\'s get to know you',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppTokens.spacingXL),
          
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              hintText: 'John Doe',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: AppTokens.spacingM),
          
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              hintText: '(555) 123-4567',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: AppTokens.spacingM),
          
          CheckboxListTile(
            value: _smsConsent,
            onChanged: (value) => setState(() => _smsConsent = value ?? false),
            title: const Text('I consent to receive SMS notifications'),
            subtitle: const Text('Get updates about your jobs via text'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
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
            'Where are you located?',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: AppTokens.spacingS),
          Text(
            'We need your address to match you with pros nearby',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppTokens.spacingXL),
          
          TextField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Street Address',
              hintText: '123 Main St',
              prefixIcon: Icon(Icons.home_outlined),
            ),
          ),
          const SizedBox(height: AppTokens.spacingM),
          
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    hintText: 'New York',
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.spacingM),
              Expanded(
                child: TextField(
                  controller: _stateController,
                  decoration: const InputDecoration(
                    labelText: 'State',
                    hintText: 'NY',
                  ),
                  maxLength: 2,
                ),
              ),
            ],
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
        ],
      ),
    );
  }

  Widget _buildStep3HomeDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTokens.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tell us about your home',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: AppTokens.spacingS),
          Text(
            'This helps pros prepare for the job',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppTokens.spacingXL),
          
          Text(
            'Home Type',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppTokens.spacingM),
          
          Wrap(
            spacing: AppTokens.spacingM,
            runSpacing: AppTokens.spacingM,
            children: [
              'House',
              'Apartment',
              'Condo',
              'Townhouse',
              'Commercial',
            ].map((type) {
              final isSelected = _homeType == type;
              return FilterChip(
                label: Text(type),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _homeType = selected ? type : null);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: AppTokens.spacingXL),
          
          SwitchListTile(
            value: _hasPets,
            onChanged: (value) => setState(() => _hasPets = value),
            title: const Text('Do you have pets?'),
            subtitle: const Text('Pros need to know for safety'),
          ),
          const SizedBox(height: AppTokens.spacingM),
          
          TextField(
            controller: _accessNotesController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Access Notes (Optional)',
              hintText: 'Gate code, door location, etc.',
              prefixIcon: Icon(Icons.note_outlined),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep4Payment() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTokens.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Setup',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: AppTokens.spacingS),
          Text(
            'Secure payment powered by Stripe',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppTokens.spacingXL),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.spacingL),
              child: Column(
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 48,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: AppTokens.spacingM),
                  Text(
                    'Your payment information is secure',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppTokens.spacingS),
                  Text(
                    'We use Stripe to securely process payments. Your card details are never stored on our servers.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTokens.spacingL),
          
          if (_paymentMethodId == null)
            FilledButton.icon(
              onPressed: () async {
                // TODO: Setup Stripe payment method
                // TODO: Show Stripe payment sheet
              },
              icon: const Icon(Icons.add_card),
              label: const Text('Add Payment Method'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            )
          else
            Card(
              child: ListTile(
                leading: const Icon(Icons.credit_card),
                title: const Text('Payment Method Added'),
                subtitle: const Text('Card ending in ••••'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // TODO: Edit payment method
                  },
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
              onPressed: _currentStep == 3 && _paymentMethodId == null
                  ? null
                  : _nextStep,
              child: Text(_currentStep == 3 ? 'Complete' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }
}

