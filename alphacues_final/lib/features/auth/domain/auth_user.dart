/// Authenticated user profile from auth endpoints.
class AuthUser {
  const AuthUser({
    required this.userId,
    required this.email,
    this.name,
    this.avatarUrl,
    this.isNewUser = false,
    this.phone,
    this.gender,
    this.dateOfBirth,
    this.maritalStatus,
    this.incomeRange,
    this.occupation,
    this.sourceOfFund,
    this.identityType,
    this.identityNumber,
    this.address,
    this.primaryAddress,
    this.secondaryAddress,
    this.phoneType,
    this.investmentExperience,
    this.productType,
    this.tradingFrequency,
    this.investmentObjective,
    this.tradingStyle,
    this.riskTolerance,
    this.kycStatus,
  });

  final Object userId;
  final String email;
  final String? name;
  final String? avatarUrl;
  final bool isNewUser;
  final String? phone;
  final String? phoneType;
  final String? gender;
  final String? dateOfBirth;
  final String? maritalStatus;
  final String? incomeRange;
  final String? occupation;
  final String? sourceOfFund;
  final String? identityType;
  final String? identityNumber;
  final String? address;
  final String? primaryAddress;
  final String? secondaryAddress;
  final String? investmentExperience;
  final String? productType;
  final String? tradingFrequency;
  final String? investmentObjective;
  final String? tradingStyle;
  final String? riskTolerance;
  final String? kycStatus;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      userId: json['userId'] as Object,
      email: json['email'] as String,
      name: json['name'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      isNewUser: json['isNewUser'] as bool? ?? json['is_new_user'] as bool? ?? false,
      phone: json['phone'] as String?,
      phoneType: json['phoneType'] as String? ?? json['phone_type'] as String?,
      gender: json['gender'] as String?,
      dateOfBirth: json['dateOfBirth'] as String? ?? json['date_of_birth'] as String?,
      maritalStatus: json['maritalStatus'] as String? ?? json['marital_status'] as String?,
      incomeRange: json['incomeRange'] as String? ?? json['income_range'] as String?,
      occupation: json['occupation'] as String?,
      sourceOfFund: json['sourceOfFund'] as String? ?? json['source_of_fund'] as String?,
      identityType: json['identityType'] as String? ?? json['identity_type'] as String?,
      identityNumber: json['identityNumber'] as String? ?? json['identity_number'] as String?,
      address: json['address'] as String?,
      primaryAddress: json['primaryAddress'] as String? ?? json['primary_address'] as String?,
      secondaryAddress: json['secondaryAddress'] as String? ?? json['secondary_address'] as String?,
      investmentExperience: json['investmentExperience'] as String? ?? json['investment_experience'] as String?,
      productType: json['productType'] as String? ?? json['product_type'] as String?,
      tradingFrequency: json['tradingFrequency'] as String? ?? json['trading_frequency'] as String?,
      investmentObjective: json['investmentObjective'] as String? ?? json['investment_objective'] as String?,
      tradingStyle: json['tradingStyle'] as String? ?? json['trading_style'] as String?,
      riskTolerance: json['riskTolerance'] as String? ?? json['risk_tolerance'] as String?,
      kycStatus: json['kycStatus'] as String? ?? json['kyc_status'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'email': email,
    if (name != null) 'name': name,
    if (avatarUrl != null) 'avatarUrl': avatarUrl,
    'isNewUser': isNewUser,
    if (phone != null) 'phone': phone,
    if (phoneType != null) 'phoneType': phoneType,
    if (gender != null) 'gender': gender,
    if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
    if (maritalStatus != null) 'maritalStatus': maritalStatus,
    if (incomeRange != null) 'incomeRange': incomeRange,
    if (occupation != null) 'occupation': occupation,
    if (sourceOfFund != null) 'sourceOfFund': sourceOfFund,
    if (identityType != null) 'identityType': identityType,
    if (identityNumber != null) 'identityNumber': identityNumber,
    if (address != null) 'address': address,
    if (primaryAddress != null) 'primaryAddress': primaryAddress,
    if (secondaryAddress != null) 'secondaryAddress': secondaryAddress,
    if (investmentExperience != null) 'investmentExperience': investmentExperience,
    if (productType != null) 'productType': productType,
    if (tradingFrequency != null) 'tradingFrequency': tradingFrequency,
    if (investmentObjective != null) 'investmentObjective': investmentObjective,
    if (tradingStyle != null) 'tradingStyle': tradingStyle,
    if (riskTolerance != null) 'riskTolerance': riskTolerance,
    if (kycStatus != null) 'kycStatus': kycStatus,
  };

  AuthUser copyWith({
    Object? userId,
    String? email,
    String? name,
    String? avatarUrl,
    bool? isNewUser,
    String? phone,
    String? phoneType,
    String? gender,
    String? dateOfBirth,
    String? maritalStatus,
    String? incomeRange,
    String? occupation,
    String? sourceOfFund,
    String? identityType,
    String? identityNumber,
    String? address,
    String? primaryAddress,
    String? secondaryAddress,
    String? investmentExperience,
    String? productType,
    String? tradingFrequency,
    String? investmentObjective,
    String? tradingStyle,
    String? riskTolerance,
    String? kycStatus,
  }) {
    return AuthUser(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isNewUser: isNewUser ?? this.isNewUser,
      phone: phone ?? this.phone,
      phoneType: phoneType ?? this.phoneType,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      incomeRange: incomeRange ?? this.incomeRange,
      occupation: occupation ?? this.occupation,
      sourceOfFund: sourceOfFund ?? this.sourceOfFund,
      identityType: identityType ?? this.identityType,
      identityNumber: identityNumber ?? this.identityNumber,
      address: address ?? this.address,
      primaryAddress: primaryAddress ?? this.primaryAddress,
      secondaryAddress: secondaryAddress ?? this.secondaryAddress,
      investmentExperience: investmentExperience ?? this.investmentExperience,
      productType: productType ?? this.productType,
      tradingFrequency: tradingFrequency ?? this.tradingFrequency,
      investmentObjective: investmentObjective ?? this.investmentObjective,
      tradingStyle: tradingStyle ?? this.tradingStyle,
      riskTolerance: riskTolerance ?? this.riskTolerance,
      kycStatus: kycStatus ?? this.kycStatus,
    );
  }
}
