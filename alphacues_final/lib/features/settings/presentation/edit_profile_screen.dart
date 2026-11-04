import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/auth/auth_session.dart';
import 'package:frontend/features/auth/data/auth_repository.dart';
import 'package:frontend/features/settings/data/settings_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // Contact Information
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  String? _selectedPhoneType;

  // Personal Information
  DateTime? _selectedDate;
  String? _selectedGender;
  String? _selectedMaritalStatus;
  String? _selectedIncomeRange;

  // Professional Information
  String? _selectedOccupation;
  String? _selectedSourceOfFund;

  // Investment Information
  String? _selectedTradingStyle;
  String? _selectedRiskTolerance;
  String? _selectedInvestmentExperience;
  String? _selectedProductType;
  String? _selectedTradingFrequency;
  String? _selectedInvestmentObjective;

  // Primary Address
  String? _selectedAddressType1;
  String? _selectedCitizenship1;
  late final TextEditingController _houseNumber1Controller;
  late final TextEditingController _street1Controller;
  late final TextEditingController _city1Controller;
  late final TextEditingController _zipCode1Controller;
  late final TextEditingController _state1Controller;
  late final TextEditingController _country1Controller;
  bool _isEditingPrimaryAddress = false;

  // Secondary Address
  bool _sameAsPrimary = true;
  String? _selectedAddressType2;
  String? _selectedCitizenship2;
  late final TextEditingController _houseNumber2Controller;
  late final TextEditingController _street2Controller;
  late final TextEditingController _city2Controller;
  late final TextEditingController _zipCode2Controller;
  late final TextEditingController _state2Controller;
  late final TextEditingController _country2Controller;
  bool _isEditingSecondaryAddress = false;

  // Identity Information
  String? _selectedIdentityType;
  late final TextEditingController _identityNumberController;

  // Options
  static const List<String> _genderOptions = ['Male', 'Female', 'Other', 'Prefer not to say'];
  static const List<String> _maritalStatusOptions = ['Single', 'Married', 'Divorced', 'Widowed'];
  static const List<String> _incomeRanges = [
    'Below \$30,000',
    '\$30,000 - \$50,000',
    '\$50,000 - \$75,000',
    '\$75,000 - \$100,000',
    'Above \$100,000',
  ];
  static const List<String> _phoneTypeOptions = ['Mobile', 'Home', 'Work'];
  static const List<String> _occupationOptions = [
    'Employed',
    'Self-Employed',
    'Unemployed',
    'Retired',
    'Student',
    'Business Owner',
    'Professional',
  ];
  static const List<String> _sourceOfFundOptions = [
    'Savings/personal income',
    'Investment income',
    'Inheritance',
    'Business income',
    'Employment',
    'Other',
  ];
  static const List<String> _investmentExperienceOptions = [
    'None',
    'Limited',
    'A good amount',
    'Extensive',
  ];
  static const List<String> _tradingStyles = [
    'Swing Trader',
    'Day Trader',
    'Value Investor',
    'Options Scalper',
  ];
  static const List<String> _riskTolerances = [
    'Conservative',
    'Moderate',
    'Aggressive',
  ];
  static const List<String> _productTypeOptions = [
    'Stocks',
    'Bonds',
    'Mutual Funds',
    'ETFs',
    'Options',
    'Futures',
    'Crypto',
  ];
  static const List<String> _tradingFrequencyOptions = [
    'Daily',
    'Weekly',
    'Monthly',
    'Quarterly',
    'Rarely',
  ];
  static const List<String> _investmentObjectiveOptions = [
    'Growth',
    'Income',
    'Balance',
    'Preservation',
    'Speculation',
  ];
  static const List<String> _addressTypeOptions = [
    'Current',
    'Permanent',
    'Mailing',
    'Business',
  ];
  static const List<String> _citizenshipOptions = [
    'US Citizen',
    'Permanent Resident',
    'Work Visa',
    'Other',
  ];
  static const List<String> _identityTypeOptions = [
    'Govt ID Card / Aadhaar',
    'PAN Card',
    'Passport',
    'Driver License',
    'National ID',
    'SSN',
    'Tax ID',
  ];

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    final user = ref.read(authSessionProvider).session?.user;

    _nameController = TextEditingController(text: user?.name ?? settings.displayName);
    _phoneController = TextEditingController(text: user?.phone ?? '+1 (214) 714-5203');
    _selectedPhoneType = user?.phoneType ?? 'Mobile';

    if (user?.dateOfBirth != null && user!.dateOfBirth!.isNotEmpty) {
      try {
        _selectedDate = DateTime.parse(user.dateOfBirth!);
      } catch (_) {
        _selectedDate = DateTime(2000, 1, 15);
      }
    } else {
      _selectedDate = DateTime(2000, 1, 15);
    }

    _selectedGender = user?.gender ?? 'Male';
    _selectedMaritalStatus = user?.maritalStatus ?? 'Single';
    _selectedIncomeRange = user?.incomeRange ?? '\$75,000 - \$100,000';

    _selectedOccupation = user?.occupation ?? 'Professional';
    _selectedSourceOfFund = user?.sourceOfFund ?? 'Savings/personal income';

    _selectedTradingStyle = _tradingStyles.contains(user?.tradingStyle)
        ? user!.tradingStyle
        : (_tradingStyles.contains(settings.tradingStyle) ? settings.tradingStyle : 'Swing Trader');

    _selectedRiskTolerance = _riskTolerances.contains(user?.riskTolerance)
        ? user!.riskTolerance
        : (_riskTolerances.contains(settings.riskTolerance) ? settings.riskTolerance : 'Moderate');

    _selectedInvestmentExperience = user?.investmentExperience ?? 'A good amount';
    _selectedProductType = user?.productType ?? 'Stocks';
    _selectedTradingFrequency = user?.tradingFrequency ?? 'Weekly';
    _selectedInvestmentObjective = user?.investmentObjective ?? 'Growth';

    _selectedAddressType1 = 'Permanent';
    _selectedCitizenship1 = 'US Citizen';

    // Parse existing address or defaults
    _houseNumber1Controller = TextEditingController(text: '974');
    _street1Controller = TextEditingController(text: 'Cedar Trace Blvd');
    _city1Controller = TextEditingController(text: 'Westerville');
    _zipCode1Controller = TextEditingController(text: '43081');
    _state1Controller = TextEditingController(text: 'OH');
    _country1Controller = TextEditingController(text: 'United States');

    if (user?.address != null && user!.address!.isNotEmpty) {
      final parts = user.address!.split(',');
      if (parts.isNotEmpty) _street1Controller.text = parts[0].trim();
      if (parts.length > 1) _city1Controller.text = parts[1].trim();
      if (parts.length > 2) _state1Controller.text = parts[2].trim();
    }

    _selectedAddressType2 = 'Current';
    _selectedCitizenship2 = 'US Citizen';
    _houseNumber2Controller = TextEditingController(text: '974');
    _street2Controller = TextEditingController(text: 'Cedar Trace Blvd');
    _city2Controller = TextEditingController(text: 'Westerville');
    _zipCode2Controller = TextEditingController(text: '43081');
    _state2Controller = TextEditingController(text: 'OH');
    _country2Controller = TextEditingController(text: 'United States');

    _selectedIdentityType = user?.identityType ?? 'Govt ID Card / Aadhaar';
    _identityNumberController = TextEditingController(text: user?.identityNumber ?? 'AC-88921-X9');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _houseNumber1Controller.dispose();
    _street1Controller.dispose();
    _city1Controller.dispose();
    _zipCode1Controller.dispose();
    _state1Controller.dispose();
    _country1Controller.dispose();
    _houseNumber2Controller.dispose();
    _street2Controller.dispose();
    _city2Controller.dispose();
    _zipCode2Controller.dispose();
    _state2Controller.dispose();
    _country2Controller.dispose();
    _identityNumberController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day.toString().padLeft(2, '0')}, ${d.year}';
  }

  String _formatPrimaryAddress() {
    return '${_houseNumber1Controller.text.trim()} ${_street1Controller.text.trim()}\n${_city1Controller.text.trim()}, ${_state1Controller.text.trim()} ${_zipCode1Controller.text.trim()}\n${_country1Controller.text.trim()}';
  }

  String _formatSecondaryAddress() {
    if (_sameAsPrimary) {
      return _formatPrimaryAddress();
    }
    return '${_houseNumber2Controller.text.trim()} ${_street2Controller.text.trim()}\n${_city2Controller.text.trim()}, ${_state2Controller.text.trim()} ${_zipCode2Controller.text.trim()}\n${_country2Controller.text.trim()}';
  }

  void _syncSecondaryFromPrimary() {
    _houseNumber2Controller.text = _houseNumber1Controller.text;
    _street2Controller.text = _street1Controller.text;
    _city2Controller.text = _city1Controller.text;
    _zipCode2Controller.text = _zipCode1Controller.text;
    _state2Controller.text = _state1Controller.text;
    _country2Controller.text = _country1Controller.text;
    _selectedAddressType2 = _selectedAddressType1;
    _selectedCitizenship2 = _selectedCitizenship1;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final primaryAddr = '${_houseNumber1Controller.text.trim()} ${_street1Controller.text.trim()}, ${_city1Controller.text.trim()}, ${_state1Controller.text.trim()} ${_zipCode1Controller.text.trim()}, ${_country1Controller.text.trim()}';
    final secondaryAddr = _sameAsPrimary
        ? primaryAddr
        : '${_houseNumber2Controller.text.trim()} ${_street2Controller.text.trim()}, ${_city2Controller.text.trim()}, ${_state2Controller.text.trim()} ${_zipCode2Controller.text.trim()}, ${_country2Controller.text.trim()}';

    final dobStr = _selectedDate != null
        ? '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}'
        : null;

    final updatePayload = {
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'phoneType': _selectedPhoneType,
      'gender': _selectedGender,
      'dateOfBirth': dobStr,
      'maritalStatus': _selectedMaritalStatus,
      'incomeRange': _selectedIncomeRange,
      'occupation': _selectedOccupation,
      'sourceOfFund': _selectedSourceOfFund,
      'primaryAddress': primaryAddr,
      'address': primaryAddr,
      'secondaryAddress': secondaryAddr,
      'investmentExperience': _selectedInvestmentExperience,
      'productType': _selectedProductType,
      'tradingFrequency': _selectedTradingFrequency,
      'investmentObjective': _selectedInvestmentObjective,
      'tradingStyle': _selectedTradingStyle,
      'riskTolerance': _selectedRiskTolerance,
      'identityType': _selectedIdentityType,
      'identityNumber': _identityNumberController.text.trim(),
    };

    // Update settings provider locally
    ref.read(settingsProvider.notifier).updateProfile(
          displayName: _nameController.text.trim(),
          bio: ref.read(settingsProvider).bio,
          tradingStyle: _selectedTradingStyle,
          riskTolerance: _selectedRiskTolerance,
        );

    try {
      final updated = await ref.read(authRepositoryProvider).updateProfile(updatePayload);
      ref.read(authSessionProvider.notifier).updateUser(updated);

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile information updated and synced successfully!'),
            backgroundColor: Color(0xFF00C805),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved locally.'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const purple = Color(0xFF7246C0);

    final user = ref.read(authSessionProvider).session?.user;
    final userEmail = user?.email ?? 'trader@alphacues.com';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF141416) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF141416) : Colors.white,
        elevation: 0,
        title: Text(
          'Personal information',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. PERSONAL INFORMATION ──────────────────────────────────
                _buildSectionTitle('Personal Information', purple),
                const SizedBox(height: 12),
                _buildDropdownRow(
                  label: 'Gender',
                  value: _selectedGender,
                  options: _genderOptions,
                  isDark: isDark,
                  onChanged: (val) => setState(() => _selectedGender = val),
                ),
                _buildDatePickerRow(isDark: isDark, purple: purple),
                _buildDropdownRow(
                  label: 'Marital Status',
                  value: _selectedMaritalStatus,
                  options: _maritalStatusOptions,
                  isDark: isDark,
                  onChanged: (val) => setState(() => _selectedMaritalStatus = val),
                ),
                _buildDropdownRow(
                  label: 'Income Range',
                  value: _selectedIncomeRange,
                  options: _incomeRanges,
                  isDark: isDark,
                  onChanged: (val) => setState(() => _selectedIncomeRange = val),
                ),

                const SizedBox(height: 32),

                // ── 2. CONTACT INFORMATION ───────────────────────────────────
                _buildSectionTitle('Contact Information', purple),
                const SizedBox(height: 12),
                _buildEditableField(
                  label: 'Full Name',
                  controller: _nameController,
                  isDark: isDark,
                  purple: purple,
                ),
                const SizedBox(height: 10),
                _buildInfoRow(
                  label: 'Email address',
                  value: userEmail,
                  isDark: isDark,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Verified', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
                _buildInfoRow(
                  label: 'Phone number',
                  value: _phoneController.text,
                  isDark: isDark,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Verified', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
                _buildDropdownRow(
                  label: 'Phone Type',
                  value: _selectedPhoneType,
                  options: _phoneTypeOptions,
                  isDark: isDark,
                  onChanged: (val) => setState(() => _selectedPhoneType = val),
                ),

                const SizedBox(height: 32),

                // ── 3. PROFESSIONAL INFORMATION ──────────────────────────────
                _buildSectionTitle('Professional Information', purple),
                const SizedBox(height: 12),
                _buildDropdownRow(
                  label: 'Occupation',
                  value: _selectedOccupation,
                  options: _occupationOptions,
                  isDark: isDark,
                  onChanged: (val) => setState(() => _selectedOccupation = val),
                ),
                _buildDropdownRow(
                  label: 'Source of Fund',
                  value: _selectedSourceOfFund,
                  options: _sourceOfFundOptions,
                  isDark: isDark,
                  onChanged: (val) => setState(() => _selectedSourceOfFund = val),
                ),

                const SizedBox(height: 32),

                // ── 4. PRIMARY ADDRESS ───────────────────────────────────────
                _buildSectionTitle('Primary Address', purple),
                const SizedBox(height: 12),
                _buildDropdownRow(
                  label: 'Primary Address Type',
                  value: _selectedAddressType1,
                  options: _addressTypeOptions,
                  isDark: isDark,
                  onChanged: (val) {
                    setState(() => _selectedAddressType1 = val);
                    if (_sameAsPrimary) _syncSecondaryFromPrimary();
                  },
                ),
                _buildDropdownRow(
                  label: 'Primary Citizenship',
                  value: _selectedCitizenship1,
                  options: _citizenshipOptions,
                  isDark: isDark,
                  onChanged: (val) {
                    setState(() => _selectedCitizenship1 = val);
                    if (_sameAsPrimary) _syncSecondaryFromPrimary();
                  },
                ),

                if (!_isEditingPrimaryAddress) ...[
                  _buildInfoRow(label: 'Address', value: _formatPrimaryAddress(), isDark: isDark),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () => setState(() => _isEditingPrimaryAddress = true),
                    icon: const Icon(Icons.edit_outlined, color: purple, size: 18),
                    label: const Text('Edit Primary Address', style: TextStyle(color: purple, fontWeight: FontWeight.w600)),
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  _buildEditableField(label: 'House / Unit Number', controller: _houseNumber1Controller, isDark: isDark, purple: purple),
                  const SizedBox(height: 10),
                  _buildEditableField(label: 'Street Address', controller: _street1Controller, isDark: isDark, purple: purple),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _buildEditableField(label: 'City', controller: _city1Controller, isDark: isDark, purple: purple)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildEditableField(label: 'State', controller: _state1Controller, isDark: isDark, purple: purple)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _buildEditableField(label: 'ZIP Code', controller: _zipCode1Controller, keyboardType: TextInputType.number, isDark: isDark, purple: purple)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildEditableField(label: 'Country', controller: _country1Controller, isDark: isDark, purple: purple)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () {
                      setState(() => _isEditingPrimaryAddress = false);
                      if (_sameAsPrimary) _syncSecondaryFromPrimary();
                    },
                    icon: const Icon(Icons.check_circle_outline_rounded, color: purple, size: 18),
                    label: const Text('Done Editing Primary Address', style: TextStyle(color: purple, fontWeight: FontWeight.bold)),
                  ),
                ],

                const SizedBox(height: 32),

                // ── 5. SECONDARY ADDRESS (WITH "SAME AS PRIMARY" TICK) ────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionTitle('Secondary Address', purple),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: _sameAsPrimary,
                          activeColor: purple,
                          onChanged: (val) {
                            setState(() {
                              _sameAsPrimary = val ?? false;
                              if (_sameAsPrimary) {
                                _isEditingSecondaryAddress = false;
                                _syncSecondaryFromPrimary();
                              }
                            });
                          },
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _sameAsPrimary = !_sameAsPrimary;
                              if (_sameAsPrimary) {
                                _isEditingSecondaryAddress = false;
                                _syncSecondaryFromPrimary();
                              }
                            });
                          },
                          child: Text(
                            'Same as primary',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (_sameAsPrimary) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1B1B1F) : const Color(0xFFF7F7FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: purple, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Secondary address is synced with your Primary Address.',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  _buildDropdownRow(
                    label: 'Secondary Address Type',
                    value: _selectedAddressType2,
                    options: _addressTypeOptions,
                    isDark: isDark,
                    onChanged: (val) => setState(() => _selectedAddressType2 = val),
                  ),
                  _buildDropdownRow(
                    label: 'Secondary Citizenship',
                    value: _selectedCitizenship2,
                    options: _citizenshipOptions,
                    isDark: isDark,
                    onChanged: (val) => setState(() => _selectedCitizenship2 = val),
                  ),

                  if (!_isEditingSecondaryAddress) ...[
                    _buildInfoRow(label: 'Address', value: _formatSecondaryAddress(), isDark: isDark),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () => setState(() => _isEditingSecondaryAddress = true),
                      icon: const Icon(Icons.edit_outlined, color: purple, size: 18),
                      label: const Text('Edit Secondary Address', style: TextStyle(color: purple, fontWeight: FontWeight.w600)),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    _buildEditableField(label: 'House / Unit Number', controller: _houseNumber2Controller, isDark: isDark, purple: purple),
                    const SizedBox(height: 10),
                    _buildEditableField(label: 'Street Address', controller: _street2Controller, isDark: isDark, purple: purple),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _buildEditableField(label: 'City', controller: _city2Controller, isDark: isDark, purple: purple)),
                        const SizedBox(width: 10),
                        Expanded(child: _buildEditableField(label: 'State', controller: _state2Controller, isDark: isDark, purple: purple)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _buildEditableField(label: 'ZIP Code', controller: _zipCode2Controller, keyboardType: TextInputType.number, isDark: isDark, purple: purple)),
                        const SizedBox(width: 10),
                        Expanded(child: _buildEditableField(label: 'Country', controller: _country2Controller, isDark: isDark, purple: purple)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () => setState(() => _isEditingSecondaryAddress = false),
                      icon: const Icon(Icons.check_circle_outline_rounded, color: purple, size: 18),
                      label: const Text('Done Editing Secondary Address', style: TextStyle(color: purple, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],

                const SizedBox(height: 32),

                // ── 6. INVESTMENT INFORMATION ────────────────────────────────
                _buildSectionTitle('Investment Information', purple),
                const SizedBox(height: 12),
                _buildDropdownRow(
                  label: 'Trading Strategy Style',
                  value: _selectedTradingStyle,
                  options: _tradingStyles,
                  isDark: isDark,
                  onChanged: (val) => setState(() => _selectedTradingStyle = val),
                ),
                _buildDropdownRow(
                  label: 'Risk Tolerance',
                  value: _selectedRiskTolerance,
                  options: _riskTolerances,
                  isDark: isDark,
                  onChanged: (val) => setState(() => _selectedRiskTolerance = val),
                ),
                _buildDropdownRow(
                  label: 'Investment Experience',
                  value: _selectedInvestmentExperience,
                  options: _investmentExperienceOptions,
                  isDark: isDark,
                  onChanged: (val) => setState(() => _selectedInvestmentExperience = val),
                ),
                _buildDropdownRow(
                  label: 'Product Type',
                  value: _selectedProductType,
                  options: _productTypeOptions,
                  isDark: isDark,
                  onChanged: (val) => setState(() => _selectedProductType = val),
                ),
                _buildDropdownRow(
                  label: 'Trading Frequency',
                  value: _selectedTradingFrequency,
                  options: _tradingFrequencyOptions,
                  isDark: isDark,
                  onChanged: (val) => setState(() => _selectedTradingFrequency = val),
                ),
                _buildDropdownRow(
                  label: 'Investment Objective',
                  value: _selectedInvestmentObjective,
                  options: _investmentObjectiveOptions,
                  isDark: isDark,
                  onChanged: (val) => setState(() => _selectedInvestmentObjective = val),
                ),

                const SizedBox(height: 32),

                // ── 7. IDENTITY INFORMATION (GOVT DETAILS) ───────────────────
                _buildSectionTitle('Identity Information', purple),
                const SizedBox(height: 12),
                _buildDropdownRow(
                  label: 'Identity Document Type',
                  value: _selectedIdentityType,
                  options: _identityTypeOptions,
                  isDark: isDark,
                  onChanged: (val) => setState(() => _selectedIdentityType = val),
                ),
                _buildEditableField(
                  label: 'Identity / Document Number',
                  controller: _identityNumberController,
                  isDark: isDark,
                  purple: purple,
                ),

                const SizedBox(height: 40),

                // ── 8. SAVE CHANGES BUTTON ───────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: purple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color accentColor) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    required bool isDark,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white54 : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required bool isDark,
    required Color purple,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1B1F) : const Color(0xFFF7F7FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey[600], fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdownRow({
    required String label,
    required String? value,
    required List<String> options,
    required bool isDark,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white54 : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => _showBottomSheet(label, options, isDark, onChanged),
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    value ?? 'Select $label',
                    style: TextStyle(
                      fontSize: 15,
                      color: value != null
                          ? (isDark ? Colors.white : Colors.black87)
                          : (isDark ? Colors.white38 : Colors.grey[400]),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: isDark ? Colors.white38 : Colors.grey[400]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerRow({required bool isDark, required Color purple}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Date of Birth',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white54 : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? DateTime(2000),
                firstDate: DateTime(1920),
                lastDate: DateTime.now(),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: isDark
                          ? ColorScheme.dark(
                              primary: purple,
                              onPrimary: Colors.white,
                              surface: const Color(0xFF1B1B1F),
                              onSurface: Colors.white,
                            )
                          : ColorScheme.light(
                              primary: purple,
                              onPrimary: Colors.white,
                              surface: Colors.white,
                              onSurface: Colors.black,
                            ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
              }
            },
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _selectedDate == null ? 'Select Date of Birth' : _formatDate(_selectedDate!),
                    style: TextStyle(
                      fontSize: 15,
                      color: _selectedDate != null
                          ? (isDark ? Colors.white : Colors.black87)
                          : (isDark ? Colors.white38 : Colors.grey[400]),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(Icons.calendar_today_rounded, size: 18, color: isDark ? Colors.white38 : Colors.grey[400]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showBottomSheet(
    String title,
    List<String> options,
    bool isDark,
    Function(String?) onChanged,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1B1B1F) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: isDark ? Colors.white54 : Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.2),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: options.map((option) {
                    return ListTile(
                      title: Text(
                        option,
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      onTap: () {
                        onChanged(option);
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
