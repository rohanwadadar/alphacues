import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for Primary Address
  final _houseNumber1Controller = TextEditingController();
  final _street1Controller = TextEditingController();
  final _city1Controller = TextEditingController();
  final _zipCode1Controller = TextEditingController();
  final _state1Controller = TextEditingController();
  final _country1Controller = TextEditingController();
  
  // Controllers for Secondary Address
  final _houseNumber2Controller = TextEditingController();
  final _street2Controller = TextEditingController();
  final _city2Controller = TextEditingController();
  final _zipCode2Controller = TextEditingController();
  final _state2Controller = TextEditingController();
  final _country2Controller = TextEditingController();

  // State variables for selections - Personal Information
  DateTime? _selectedDate;
  String? _selectedGender;
  String? _selectedMaritalStatus;
  String? _selectedIncomeRange;
  
  // Contact Information
  String? _selectedPhoneType;
  
  // Professional Information
  String? _selectedOccupation;
  String? _selectedSourceOfFund;
  
  // Investment Information
  String? _selectedInvestmentExperience;
  String? _selectedProductType;
  String? _selectedTradingFrequency;
  String? _selectedInvestmentObjective;
  
  // Address Information
  String? _selectedAddressType1;
  String? _selectedCitizenship1;
  String? _selectedAddressType2;
  String? _selectedCitizenship2;
  
  // Identity Information
  String? _selectedIdentityType;

  // Lists for dropdown options - Personal Information
  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  final List<String> _maritalStatusOptions = ['Single', 'Married', 'Divorced', 'Widowed'];
  final List<String> _incomeRanges = [
    'Below \$30,000',
    '\$30,000 - \$50,000',
    '\$50,000 - \$75,000',
    '\$75,000 - \$100,000',
    'Above \$100,000'
  ];
  
  // Contact Information
  final List<String> _phoneTypeOptions = ['Mobile', 'Home', 'Work'];
  
  // Professional Information
  final List<String> _occupationOptions = [
    'Employed', 
    'Self-Employed', 
    'Unemployed', 
    'Retired', 
    'Student',
    'Business Owner',
    'Professional'
  ];
  final List<String> _sourceOfFundOptions = [
    'Savings/personal income',
    'Investment income',
    'Inheritance',
    'Business income',
    'Employment',
    'Other'
  ];
  
  // Investment Information
  final List<String> _investmentExperienceOptions = ['None', 'Limited', 'A good amount', 'Extensive'];
  final List<String> _productTypeOptions = ['Stocks', 'Bonds', 'Mutual Funds', 'ETFs', 'Options', 'Futures', 'Crypto'];
  final List<String> _tradingFrequencyOptions = [
    'Daily',
    'Weekly',
    'Monthly',
    'Quarterly',
    'Rarely'
  ];
  final List<String> _investmentObjectiveOptions = ['Growth', 'Income', 'Balance', 'Preservation', 'Speculation'];
  
  // Address Information
  final List<String> _addressTypeOptions = ['Current', 'Permanent', 'Mailing', 'Business'];
  final List<String> _citizenshipOptions = ['US Citizen', 'Permanent Resident', 'Work Visa', 'Other'];
  
  // Identity Information
  final List<String> _identityTypeOptions = ['SSN', 'Passport', 'Driver License', 'National ID', 'Tax ID'];

  bool _isEditingPrimaryAddress = false;
  bool _isEditingSecondaryAddress = false;

  @override
  void initState() {
    super.initState();
    // Initialize with sample data
    _houseNumber1Controller.text = '974';
    _street1Controller.text = 'Cedar Trace Blvd';
    _city1Controller.text = 'Westerville';
    _zipCode1Controller.text = '43081';
    _state1Controller.text = 'OH';
    _country1Controller.text = 'United States';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Personal information',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Personal Information Section
                _buildSectionTitle('Personal Information'),
                SizedBox(height: 16),
                _buildDropdownRow('Gender', _selectedGender, _genderOptions, (value) {
                  setState(() => _selectedGender = value);
                }),
                _buildDatePickerRow(),
                _buildDropdownRow('Marital Status', _selectedMaritalStatus, _maritalStatusOptions, (value) {
                  setState(() => _selectedMaritalStatus = value);
                }),
                _buildDropdownRow('Income Range', _selectedIncomeRange, _incomeRanges, (value) {
                  setState(() => _selectedIncomeRange = value);
                }),
                
                SizedBox(height: 32),
                
                // Contact Information Section (NON-EDITABLE)
                _buildSectionTitle('Contact Information'),
                SizedBox(height: 16),
                _buildInfoRow('Name', 'Donal Trump'),
                _buildInfoRow('Email address', 'Lord_trump@gmail.com', 
                  trailing: Text('Unverified', style: TextStyle(color: Colors.orange, fontSize: 14))),
                _buildInfoRow('Phone number', '+1 (214) 714-5203',
                  trailing: Text('Verified', style: TextStyle(color: Colors.green, fontSize: 14))),
                _buildDropdownRow('Phone Type', _selectedPhoneType, _phoneTypeOptions, (value) {
                  setState(() => _selectedPhoneType = value);
                }),
                
                SizedBox(height: 32),
                
                // Professional Information Section
                _buildSectionTitle('Professional Information'),
                SizedBox(height: 16),
                _buildDropdownRow('Occupation', _selectedOccupation, _occupationOptions, (value) {
                  setState(() => _selectedOccupation = value);
                }),
                _buildDropdownRow('Source of Fund', _selectedSourceOfFund, _sourceOfFundOptions, (value) {
                  setState(() => _selectedSourceOfFund = value);
                }),
                
                SizedBox(height: 32),
                
                // Investment Information Section
                _buildSectionTitle('Investment Information'),
                SizedBox(height: 16),
                _buildDropdownRow('Investment Experience', _selectedInvestmentExperience, _investmentExperienceOptions, (value) {
                  setState(() => _selectedInvestmentExperience = value);
                }),
                _buildDropdownRow('Product Type', _selectedProductType, _productTypeOptions, (value) {
                  setState(() => _selectedProductType = value);
                }),
                _buildDropdownRow('Trading Frequency', _selectedTradingFrequency, _tradingFrequencyOptions, (value) {
                  setState(() => _selectedTradingFrequency = value);
                }),
                _buildDropdownRow('Investment Objective', _selectedInvestmentObjective, _investmentObjectiveOptions, (value) {
                  setState(() => _selectedInvestmentObjective = value);
                }),
                
                SizedBox(height: 32),
                
                // Primary Address Section (Editable)
                _buildSectionTitle('Primary Address'),
                SizedBox(height: 16),
                
                _buildDropdownRow('Primary Address Type', _selectedAddressType1, _addressTypeOptions, (value) {
                  setState(() => _selectedAddressType1 = value);
                }),
                _buildDropdownRow('Primary Citizenship', _selectedCitizenship1, _citizenshipOptions, (value) {
                  setState(() => _selectedCitizenship1 = value);
                }),
                
                if (!_isEditingPrimaryAddress) ...[
                  _buildInfoRow('Address', 
                    '${_houseNumber1Controller.text} ${_street1Controller.text}\n${_city1Controller.text}, ${_state1Controller.text} ${_zipCode1Controller.text}\n${_country1Controller.text}'),
                  SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () {
                      setState(() => _isEditingPrimaryAddress = true);
                    },
                    icon: Icon(Icons.edit, color: Color.fromARGB(255, 114, 70, 192)),
                    label: Text(
                      'Edit Primary Address',
                      style: TextStyle(color: Color.fromARGB(255, 114, 70, 192)),
                    ),
                  ),
                ] else ...[
                  _buildEditableField('House Number', _houseNumber1Controller),
                  SizedBox(height: 12),
                  _buildEditableField('Street', _street1Controller),
                  SizedBox(height: 12),
                  _buildEditableField('City', _city1Controller),
                  SizedBox(height: 12),
                  _buildEditableField('ZIP Code', _zipCode1Controller, keyboardType: TextInputType.number),
                  SizedBox(height: 12),
                  _buildEditableField('State', _state1Controller),
                  SizedBox(height: 12),
                  _buildEditableField('Country', _country1Controller),
                  SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () {
                      setState(() => _isEditingPrimaryAddress = false);
                    },
                    icon: Icon(Icons.check, color: Color.fromARGB(255, 114, 70, 192)),
                    label: Text(
                      'Done Editing',
                      style: TextStyle(color: Color.fromARGB(255, 114, 70, 192)),
                    ),
                  ),
                ],
                
                SizedBox(height: 32),
                
                // Secondary Address Section (Editable)
                _buildSectionTitle('Secondary Address'),
                SizedBox(height: 16),
                
                _buildDropdownRow('Secondary Address Type', _selectedAddressType2, _addressTypeOptions, (value) {
                  setState(() => _selectedAddressType2 = value);
                }),
                _buildDropdownRow('Secondary Citizenship', _selectedCitizenship2, _citizenshipOptions, (value) {
                  setState(() => _selectedCitizenship2 = value);
                }),
                
                if (!_isEditingSecondaryAddress) ...[
                  _buildInfoRow('Address', 
                    _houseNumber2Controller.text.isEmpty 
                      ? 'Not provided' 
                      : '${_houseNumber2Controller.text} ${_street2Controller.text}\n${_city2Controller.text}, ${_state2Controller.text} ${_zipCode2Controller.text}\n${_country2Controller.text}'),
                  SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () {
                      setState(() => _isEditingSecondaryAddress = true);
                    },
                    icon: Icon(Icons.edit, color: Color.fromARGB(255, 114, 70, 192)),
                    label: Text(
                      'Edit Secondary Address',
                      style: TextStyle(color: Color.fromARGB(255, 114, 70, 192)),
                    ),
                  ),
                ] else ...[
                  _buildEditableField('House Number', _houseNumber2Controller),
                  SizedBox(height: 12),
                  _buildEditableField('Street', _street2Controller),
                  SizedBox(height: 12),
                  _buildEditableField('City', _city2Controller),
                  SizedBox(height: 12),
                  _buildEditableField('ZIP Code', _zipCode2Controller, keyboardType: TextInputType.number),
                  SizedBox(height: 12),
                  _buildEditableField('State', _state2Controller),
                  SizedBox(height: 12),
                  _buildEditableField('Country', _country2Controller),
                  SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () {
                      setState(() => _isEditingSecondaryAddress = false);
                    },
                    icon: Icon(Icons.check, color: Color.fromARGB(255, 114, 70, 192)),
                    label: Text(
                      'Done Editing',
                      style: TextStyle(color: Color.fromARGB(255, 114, 70, 192)),
                    ),
                  ),
                ],
                
                SizedBox(height: 32),
                
                // Identity Information Section (NON-EDITABLE)
                _buildSectionTitle('Identity Information'),
                SizedBox(height: 16),
                
                _buildDropdownRow('Identity Type', _selectedIdentityType, _identityTypeOptions, (value) {
                  setState(() => _selectedIdentityType = value);
                }),
                
                _buildInfoRow('Identity Number', '*** *** 1234'),
                
                SizedBox(height: 40),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // Save profile changes
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Profile updated successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 114, 70, 192),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Widget? trailing}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.w400,
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

  Widget _buildEditableField(String label, TextEditingController controller, {TextInputType? keyboardType}) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color.fromARGB(255, 114, 70, 192).withOpacity(0.3)),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(color: Colors.black, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600]),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdownRow(String label, String? value, List<String> options, Function(String?) onChanged) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _showBottomSheet(label, options, onChanged),
                  child: Text(
                    value ?? 'Select $label',
                    style: TextStyle(
                      fontSize: 16,
                      color: value != null ? Colors.black : Colors.grey[400],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerRow() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Date of Birth',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? DateTime(2000),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.light(
                              primary: Color.fromARGB(255, 114, 70, 192),
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
                  child: Text(
                    _selectedDate == null 
                      ? 'Select Date of Birth' 
                      : DateFormat('MMM dd, yyyy').format(_selectedDate!),
                    style: TextStyle(
                      fontSize: 16,
                      color: _selectedDate != null ? Colors.black : Colors.grey[400],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ],
      ),
    );
  }

  void _showBottomSheet(String title, List<String> options, Function(String?) onChanged) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Divider(),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: options.map((option) {
                    return ListTile(
                      title: Text(
                        option,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
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

  @override
  void dispose() {
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
    super.dispose();
  }
}