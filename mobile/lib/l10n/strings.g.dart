/// Generated file. Do not edit.
///
/// Original: lib/l10n
/// To regenerate, run: `dart run slang`
///
/// Locales: 2
/// Strings: 704 (352 per locale)
///
/// Built on 2026-05-13 at 20:25 UTC

// coverage:ignore-file
// ignore_for_file: type=lint

import 'package:flutter/widgets.dart';
import 'package:slang/builder/model/node.dart';
import 'package:slang_flutter/slang_flutter.dart';
export 'package:slang_flutter/slang_flutter.dart';

const AppLocale _baseLocale = AppLocale.en;

/// Supported locales, see extension methods below.
///
/// Usage:
/// - LocaleSettings.setLocale(AppLocale.en) // set locale
/// - Locale locale = AppLocale.en.flutterLocale // get flutter locale from enum
/// - if (LocaleSettings.currentLocale == AppLocale.en) // locale check
enum AppLocale with BaseAppLocale<AppLocale, Translations> {
	en(languageCode: 'en', build: Translations.build),
	tr(languageCode: 'tr', build: _StringsTr.build);

	const AppLocale({required this.languageCode, this.scriptCode, this.countryCode, required this.build}); // ignore: unused_element

	@override final String languageCode;
	@override final String? scriptCode;
	@override final String? countryCode;
	@override final TranslationBuilder<AppLocale, Translations> build;

	/// Gets current instance managed by [LocaleSettings].
	Translations get translations => LocaleSettings.instance.translationMap[this]!;
}

/// Method A: Simple
///
/// No rebuild after locale change.
/// Translation happens during initialization of the widget (call of t).
/// Configurable via 'translate_var'.
///
/// Usage:
/// String a = t.someKey.anotherKey;
/// String b = t['someKey.anotherKey']; // Only for edge cases!
Translations get t => LocaleSettings.instance.currentTranslations;

/// Method B: Advanced
///
/// All widgets using this method will trigger a rebuild when locale changes.
/// Use this if you have e.g. a settings page where the user can select the locale during runtime.
///
/// Step 1:
/// wrap your App with
/// TranslationProvider(
/// 	child: MyApp()
/// );
///
/// Step 2:
/// final t = Translations.of(context); // Get t variable.
/// String a = t.someKey.anotherKey; // Use t variable.
/// String b = t['someKey.anotherKey']; // Only for edge cases!
class TranslationProvider extends BaseTranslationProvider<AppLocale, Translations> {
	TranslationProvider({required super.child}) : super(settings: LocaleSettings.instance);

	static InheritedLocaleData<AppLocale, Translations> of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context);
}

/// Method B shorthand via [BuildContext] extension method.
/// Configurable via 'translate_var'.
///
/// Usage (e.g. in a widget's build method):
/// context.t.someKey.anotherKey
extension BuildContextTranslationsExtension on BuildContext {
	Translations get t => TranslationProvider.of(this).translations;
}

/// Manages all translation instances and the current locale
class LocaleSettings extends BaseFlutterLocaleSettings<AppLocale, Translations> {
	LocaleSettings._() : super(utils: AppLocaleUtils.instance);

	static final instance = LocaleSettings._();

	// static aliases (checkout base methods for documentation)
	static AppLocale get currentLocale => instance.currentLocale;
	static Stream<AppLocale> getLocaleStream() => instance.getLocaleStream();
	static AppLocale setLocale(AppLocale locale, {bool? listenToDeviceLocale = false}) => instance.setLocale(locale, listenToDeviceLocale: listenToDeviceLocale);
	static AppLocale setLocaleRaw(String rawLocale, {bool? listenToDeviceLocale = false}) => instance.setLocaleRaw(rawLocale, listenToDeviceLocale: listenToDeviceLocale);
	static AppLocale useDeviceLocale() => instance.useDeviceLocale();
	@Deprecated('Use [AppLocaleUtils.supportedLocales]') static List<Locale> get supportedLocales => instance.supportedLocales;
	@Deprecated('Use [AppLocaleUtils.supportedLocalesRaw]') static List<String> get supportedLocalesRaw => instance.supportedLocalesRaw;
	static void setPluralResolver({String? language, AppLocale? locale, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver}) => instance.setPluralResolver(
		language: language,
		locale: locale,
		cardinalResolver: cardinalResolver,
		ordinalResolver: ordinalResolver,
	);
}

/// Provides utility functions without any side effects.
class AppLocaleUtils extends BaseAppLocaleUtils<AppLocale, Translations> {
	AppLocaleUtils._() : super(baseLocale: _baseLocale, locales: AppLocale.values);

	static final instance = AppLocaleUtils._();

	// static aliases (checkout base methods for documentation)
	static AppLocale parse(String rawLocale) => instance.parse(rawLocale);
	static AppLocale parseLocaleParts({required String languageCode, String? scriptCode, String? countryCode}) => instance.parseLocaleParts(languageCode: languageCode, scriptCode: scriptCode, countryCode: countryCode);
	static AppLocale findDeviceLocale() => instance.findDeviceLocale();
	static List<Locale> get supportedLocales => instance.supportedLocales;
	static List<String> get supportedLocalesRaw => instance.supportedLocalesRaw;
}

// translations

// Path: <root>
class Translations implements BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations.build({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	dynamic operator[](String key) => $meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	// Translations
	late final _StringsCommonEn common = _StringsCommonEn._(_root);
	late final _StringsValidationEn validation = _StringsValidationEn._(_root);
	late final _StringsFeaturesEn features = _StringsFeaturesEn._(_root);
	late final _StringsDbContextEn db_context = _StringsDbContextEn._(_root);
}

// Path: common
class _StringsCommonEn {
	_StringsCommonEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get logout => 'Logout';
	String get cancel => 'Cancel';
	String get confirm => 'Confirm';
	String get save => 'Save';
	String get delete => 'Delete';
	String get edit => 'Edit';
	String get close => 'Close';
	String get yes => 'Yes';
	String get no => 'No';
	String get register => 'Register';
	String get login => 'Login';
	String get join => 'Join';
	String get confirmMessage => 'Are you sure?';
	String get logoutConfirm => 'Are you sure you want to logout?';
	String get logoutSuccess => 'Signed out successfully.';
	String get account => 'Account';
	String get changePassword => 'Change Password';
	String get language => 'Language';
	String get turkish => 'Turkish';
	String get notifications => 'Notifications';
	String get info => 'Info';
	String get privacyPolicy => 'Privacy Policy';
	String get kvkk => 'KVKK';
	String get helpSupport => 'Help & Support';
	String get about => 'About';
	String get comingSoon => 'This feature will be added soon';
	String get multiLanguageComingSoon => 'Multi-language support coming soon';
	String get copyright => ' 2026 AidatPanel\nAll rights reserved.';
	String get aboutDescription => 'Dues management platform for Turkish apartment and site managers.';
	String get manager => 'Manager';
	String get resident => 'Resident';
	String get tokenExpiryTest => 'Token Expiry Check (Test)';
	String get tokenExpired => 'Token EXPIRED! Redirecting to login screen.';
	String get tokenActive => 'Token active! Remaining time';
	String get pressBackAgainToExit => 'Press back again to exit';
	String get loading => 'Loading…';
	String get loadingBuildings => 'Loading buildings…';
	String get loadFailed => 'Failed to load';
	String get tryAgain => 'Try Again';
	String get home => 'Home';
	String get buildings => 'Buildings';
	String get dues => 'Dues';
	String get settings => 'Settings';
	String get user => 'User';
	String get welcome => 'Welcome';
	String get managedBuildings => 'Managed Buildings';
	String get issues => 'Issues';
	String get issuesTab => 'Issues Tab';
	String get apartment => 'Apartment';
	String get addBuilding => 'Add Building';
	String get inviteCode => 'Invite Code';
	String get myBuildings => 'My Buildings';
	String get apartments => 'Apartments';
	String get collection => 'Collection';
	String get monthlyDues => 'Monthly Dues';
	String get duesTab => 'Dues Tab';
	String get totalApartments => 'Total Apartments';
	String get occupiedApartments => 'Occupied Apartments';
	String get duesCollection => 'Dues Collection';
	String get totalDues => 'Total Dues';
	String get recentTransactions => 'Recent Transactions';
	String get paid => 'Paid';
	String get pending => 'Pending';
	String get overdue => 'Overdue';
	String get balance => 'Balance';
	String get amountDue => 'Amount Due';
	String get lastPayment => 'Last Payment';
	String get makePayment => 'Make Payment';
	String get bills => 'Bills';
	String get support => 'Support';
	String get residentName => 'Resident Name';
	String get addBuildingNew => 'Add New Building';
	String get basicInfo => 'Basic Info';
	String get buildingName => 'Building Name';
	String get buildingNameHint => 'Ex: Güneş Apartmanı';
	String get location => 'Location';
	String get streetAddress => 'Street Address';
	String get streetAddressHint => 'Ex: Bağdat Cad. No: 123';
	String get details => 'Details';
	String get floorCount => 'Floor Count';
	String get floorCountHint => 'Between 1 and 200';
	String get apartmentsPerFloor => 'Apartments Per Floor';
	String get apartmentsPerFloorHint => 'Between 1 and 50';
	String get floorRangeError => 'Floor count must be between 1 and 200';
	String get apartmentsPerFloorRangeError => 'Apartments per floor must be between 1 and 50';
	String get buildingAddFailed => 'Could not add building. Please try again.';
	String get monthlyDuesLabel => 'Monthly Dues (₺)';
	String get monthlyDuesHint => 'Ex: 1000';
	String get createBuilding => 'Create Building';
	String get cancelBtn => 'Cancel';
	String get cityRequired => 'City *';
	String get selectCity => 'Select City';
	String get districtRequired => 'District *';
	String get selectDistrict => 'Select District';
	String get selectCityFirst => 'Select city first';
	String get selectCityTitle => 'Select City';
	String get selectDistrictTitle => 'Select District';
	String get search => 'Search...';
	String get noResults => 'No results found';
	String get fieldRequired => 'cannot be empty';
	String get fillRequiredFields => 'Please fill required fields';
	String get selectCityAndDistrict => 'You must select city and district';
	String get floorApartmentMustBePositive => 'Floor count and apartment count must be greater than 0';
	String get buildingAddedSuccess => 'Building added successfully';
	String get createInviteCode => 'Create Invite Code';
	String get whichBuildingForCode => 'Which building to generate code for?';
	String get whichApartmentForCode => 'Which apartment to generate code for?';
	String get noApartmentsInBuilding => 'No apartments added to this building yet';
	String get activeCodeBadge => 'Active Code';
	String get occupiedBadge => 'Occupied';
	String get emptyBadge => 'Empty';
	String get activeCodePrefix => 'Active code';
	String get residentPrefix => 'Resident';
	String get emptyApartment => 'Empty apartment';
	String get codeRevoked => 'Code revoked';
	String get codeCopied => 'Code copied';
	String get clipboardCopied => 'Message copied to clipboard';
	String get expiresAtPrefix => 'Expires at';
	String get remainingPrefix => 'Remaining';
	String get buildingDetail => 'Building Detail';
	String get residents => 'Residents';
	String get apartmentsBadge => 'Apartments';
	String get emptyApartmentText => 'Empty Apartment';
	String get vacantBadge => 'Vacant';
	String get phoneNotShared => 'Phone not shared';
	String get residentDetailsLink => 'Details..';
	String get residentDetailsSheetTitle => 'Resident information';
	String get apartmentDetailsSheetTitle => 'Apartment information';
	String get noResidentAssigned => 'No resident assigned';
	String get noApartmentsYet => 'No apartments added yet';
	String get paidStatus => 'Paid';
	String get pendingStatus => 'Pending';
	String get overdueStatus => 'Overdue';
	String get waivedStatus => 'Waived';
	String get all => 'All';
	String get status => 'Status';
	String get month => 'Month';
	String get monthJanuary => 'January';
	String get monthFebruary => 'February';
	String get monthMarch => 'March';
	String get monthApril => 'April';
	String get monthMay => 'May';
	String get monthJune => 'June';
	String get monthJuly => 'July';
	String get monthAugust => 'August';
	String get monthSeptember => 'September';
	String get monthOctober => 'October';
	String get monthNovember => 'November';
	String get monthDecember => 'December';
	String get allMonths => 'All months';
	String get year => 'Year';
	String get allYears => 'All years';
	String get note => 'Note';
	String get myDuesHistory => 'My Dues History';
	String get buildingDues => 'Building Dues';
	String get noDuesYet => 'No dues records yet';
	String get duesUpdated => 'Dues status updated';
	String get amount => 'Amount';
	String get updateDueAmount => 'Update Due Amount';
	String get dueAmountUpdated => 'Due amount updated';
	String get dueAmountUpdateFailed => 'Could not update due amount';
	String get dueDay => 'Due Day (1-28)';
	String get affectCurrentDues => 'Apply to pending dues';
	String get affectCurrentDuesHint => 'When enabled, current PENDING due amounts are updated to the new amount.';
	String get dueUpdateNeedAmountOrDay => 'Enter an amount or a due day (or both) to update.';
	String get dueUpdateNeedStoredAmount => 'This building has no saved amount yet. Enter an amount before updating the due day only.';
	String get dueAmountInvalidPositive => 'Enter a valid amount.';
	String get dueDayOutOfRange => 'Due day must be between 1 and 28.';
	String get update => 'Update';
	String get overdueDays => 'days overdue';
	String get dueDateLabel => 'Due date';
	String get perMonth => '/ month';
	String get floorLabel => 'FLOOR';
	String get apartmentLabel => 'APT';
	String get turkishLanguage => 'Türkçe';
	String get englishLanguage => 'English';
	String get stepBuilding => 'Building';
	String get stepApartment => 'Apartment';
	String get stepCode => 'Code';
	String get editBuilding => 'Edit Building';
	String get deleteBuilding => 'Delete Building';
	String get buildingUpdated => 'Building updated';
	String get buildingDeleted => 'Building deleted';
	String get buildingUpdateFailed => 'Could not update building';
	String get buildingDeleteFailed => 'Could not delete building';
	String get buildingDeleteFailedFK => 'Cannot delete this building: apartments, residents, or dues records still exist. Clean up apartments/dues first.';
	String get deleteBuildingHeader => 'This action cannot be undone.';
	String get deleteBuildingTypeHint => 'To confirm, type the building name below exactly:';
	String get deleteBuildingTypeFieldLabel => 'Building name';
	String get buildingNameMismatch => 'What you typed does not match the building name.';
	String get editApartment => 'Edit Apartment';
	String get deleteApartment => 'Delete Apartment';
	String get apartmentUpdated => 'Apartment updated';
	String get apartmentDeleted => 'Apartment deleted';
	String get apartmentUpdateFailed => 'Could not update apartment';
	String get apartmentDeleteFailed => 'Could not delete apartment';
	String get apartmentDeleteFailedFK => 'Cannot delete this apartment: resident or dues records exist. Wait for the resident to close their account and clean up dues.';
	String get deleteApartmentConfirm => 'Are you sure you want to delete this apartment?';
	String get apartmentNumberLabel => 'Apt No (e.g. 5A)';
	String get floorLabel2 => 'Floor (optional)';
	String get floorOptional => 'Floor (-5 to 200)';
	String get buildingNameField => 'Building name';
	String get buildingAddressField => 'Address';
	String get buildingCityField => 'City';
	String get monthlyDuesPerApartment => 'Monthly dues / apt';
	String get remove => 'Remove';
	String get removeResident => 'Remove Resident';
	String get removeResidentConfirm => 'Are you sure you want to remove this resident from the apartment?';
	String get removeResidentNote => 'The resident\'s account will not be deleted; only their link to this apartment is removed. Past dues records are kept. The resident can join another apartment later using an invite code.';
	String get residentRemoved => 'Resident removed from apartment';
	String get residentRemoveFailed => 'Could not remove resident';
	String get residentRemoveForbidden => 'You are not allowed to perform this action. Only the building manager can remove residents.';
	String get residentRemoveNotFound => 'No resident to remove from this apartment.';
	String get multiSelectResidents => 'Select multiple';
	String get multiSelectTapHint => 'Tap the card to select or clear';
	String get removeSelectedResidents => 'Remove selected';
	String get removeSelectedResidentsTitle => 'Remove selected residents';
	String get removeSelectedResidentsMessage => 'Residents in the apartments listed below will be unlinked from their apartments. Accounts are not deleted—only the connection to this building is removed. Past dues records are kept.';
	String get removeSelectedResidentsAffectedListTitle => 'Apartments affected';
	String get removeSelectedResidentsListUnavailable => 'The apartment list could not be loaded. The count is shown below. If you confirm, removals will still proceed.';
	String get pickResidentsFirst => 'Select at least one occupied apartment from the list first';
	String get removeSelectedProgress => 'Working…';
	String get removeSelectedSuccess => 'Selected residents were removed from their apartments';
	String get removeSelectedFailed => 'Could not finish removing the selected residents';
	String get currentPassword => 'Current Password';
	String get newPassword => 'New Password';
	String get newPasswordConfirm => 'New Password (Repeat)';
	String get currentPasswordRequired => 'Enter your current password';
	String get passwordsMustDiffer => 'New password cannot be the same as the old one';
	String get changePasswordTitle => 'Change Password';
	String get changePasswordSubtitle => 'Update your password regularly to keep your account secure.';
	String get changePasswordSuccess => 'Your password has been changed. Please sign in again with your new password.';
	String get changePasswordFailed => 'Could not change password. Please try again.';
	String get changePasswordWrongCurrent => 'Current password is incorrect.';
	String get deleteAccount => 'Close My Account';
	String get deleteAccountTitle => 'Do you want to close your account?';
	String get deleteAccountWarning => 'This action cannot be undone. Your personal data will be removed, but for legal reasons some records (such as dues history) are kept anonymously.';
	String get deleteAccountTypeHint => 'To confirm, type "CLOSE MY ACCOUNT" below:';
	String get deleteAccountTypePhrase => 'CLOSE MY ACCOUNT';
	String get deleteAccountTypeMismatch => 'What you typed does not match.';
	String get deleteAccountConfirmButton => 'Close My Account';
	String get deleteAccountSuccess => 'Your account has been closed. Thank you for using AidatPanel.';
	String get deleteAccountFailed => 'Could not close account. Please try again.';
	String get deleteAccountFailedManager => 'You first need to delete the buildings you manage or transfer them to another manager.';
	String get dangerZone => 'Danger Zone';
	String get forgotPassword => 'Forgot Password';
	String get forgotPasswordTitle => 'Forgot Password';
	String get forgotPasswordSubtitle => 'Enter your registered email and we\'ll send you a reset code.';
	String get forgotPasswordSuccess => 'If this email is registered, a reset code has been sent. Please check your inbox.';
	String get sendResetCode => 'Send Code';
	String get iHaveACode => 'I already have a code';
	String get resetPasswordTitle => 'Set New Password';
	String get resetPasswordSubtitle => 'Enter the 6-character code from your email and a new password.';
	String get resetCode => 'Reset Code';
	String get resetCodeHint => 'ABC123';
	String get resetCodeRequired => 'Reset code required';
	String get resetCodeInvalid => 'Code must be 6 characters';
	String get resetPasswordSuccess => 'Your password has been reset. You can sign in with your new password.';
	String get resetPasswordFailed => 'Could not reset password. The code may be invalid or expired.';
	String get resetPasswordSubmit => 'Reset Password';
	String get backToLogin => 'Back to login';
}

// Path: validation
class _StringsValidationEn {
	_StringsValidationEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get emailRequired => 'Email address cannot be empty';
	String get emailInvalid => 'Please enter a valid email address';
	String get emailTooLong => 'Email address is too long';
	String get phoneRequired => 'Phone number cannot be empty';
	String get phoneInvalid => 'Phone number must be 10 digits';
	String get passwordRequired => 'Password cannot be empty';
	String get passwordTooShort => 'Password must be at least 6 characters';
	String get passwordTooLong => 'Password is too long';
	String get passwordUppercaseRequired => 'Password must contain at least 1 uppercase letter';
	String get passwordLowercaseRequired => 'Password must contain at least 1 lowercase letter';
	String get passwordNumberRequired => 'Password must contain at least 1 number';
	String get passwordSpecialCharRequired => 'Password must contain at least 1 special character';
}

// Path: features
class _StringsFeaturesEn {
	_StringsFeaturesEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final _StringsFeaturesBuildingsEn buildings = _StringsFeaturesBuildingsEn._(_root);
	late final _StringsFeaturesAuthEn auth = _StringsFeaturesAuthEn._(_root);
	late final _StringsFeaturesApartmentsEn apartments = _StringsFeaturesApartmentsEn._(_root);
}

// Path: db_context
class _StringsDbContextEn {
	_StringsDbContextEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get user_entry => 'Record: {value}';
	String get building_name => 'Building: {value}';
	String get apartment_label => 'Apartment: {value}';
	String get code_value => 'Code: {value}';
	String get expiry_date => 'Expires at: {value}';
}

// Path: features.buildings
class _StringsFeaturesBuildingsEn {
	_StringsFeaturesBuildingsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get managerPanel => 'Manager Panel';
	String get buildingDetail => 'Building Detail';
	String get addBuilding => 'Add Building';
	String get newBuilding => 'Add New Building';
	String get inviteCode => 'Invite Code';
	String get createInviteCode => 'Create Invite Code';
	String get cancelCode => 'Cancel Code';
	String get apartmentOccupied => 'Apartment Occupied';
	String get copy => 'Copy';
	String get share => 'Share';
	String get anotherApartment => 'Another Apartment';
	String get codeRevoked => 'Code revoked';
	String get occupiedDialog => 'If you generate a new code, the old user will be removed. Are you sure?';
	String get revokeDialog => 'The current code will become invalid. Are you sure?';
	String get produceAnyway => 'Produce Anyway';
	String get newCodePrefix => 'If you generate a new code, ';
	String get oldUserRemoved => 'the old user will be removed';
	String get currentCodePrefix => 'The current code ';
	String get codeInvalid => 'will become invalid';
	String get codeReady => 'Invite Code Ready';
	String get code => 'CODE';
	String get validFor7Days => 'Valid for 7 days';
	String get expiresAt => 'Expires at:';
	String get remaining => 'Remaining:';
	String get activeCodeNote => 'While this code is active, you cannot generate a new code for the same apartment. You must revoke the current code first.';
	String get backToMainMenu => 'Back to Main Menu';
	String get tekrarDene => 'Try Again';
}

// Path: features.auth
class _StringsFeaturesAuthEn {
	_StringsFeaturesAuthEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get register => 'Register';
	String get login => 'Login';
	String get join => 'Join';
	String get passwordRequired => 'Password required';
	String get errorOccurred => 'An error occurred';
	String get registrationSuccess => 'Account created. You can now log in.';
	String get loginSuccess => 'Signed in successfully. Welcome.';
	String get appTitle => 'AidatPanel';
	String get appSubtitle => 'Apartment Management System';
	String get splashConnectionError => 'Could not connect to server';
	String get splashConnectionHint => 'Check your connection and try again.';
	String get skipToLogin => 'Go to login';
	String get phone => 'Phone';
	String get email => 'Email';
	String get phoneHint => '5XX XXX XX XX';
	String get emailHint => 'example@email.com';
	String get password => 'Password';
	String get passwordHint => '••••••••';
	String get emailLogin => 'Login with Email';
	String get phoneLogin => 'Login with Phone';
	String get or => 'or';
	String get noAccount => 'Don\'t have an account? Register';
	String get joinWithCode => 'Join with Invite Code';
	String get copyright => '© Vefa Yazılım';
	String get createAccount => 'Create New Account';
	String get name => 'Full Name';
	String get nameHint => 'Ex: Furkan Kaya';
	String get phoneOptional => 'Phone (Optional)';
	String get phoneHintOptional => '5XX XXX XXXX';
	String get minLength => 'At least 6 characters';
	String get hasUpperCase => 'At least 1 uppercase letter';
	String get hasLowerCase => 'At least 1 lowercase letter';
	String get hasNumber => 'At least 1 number';
	String get hasSpecialChar => 'At least 1 special character';
	String get confirmPassword => 'Confirm Password';
	String get passwordsDoNotMatch => 'Passwords do not match';
	String get emailAndPasswordRequired => 'Email and password cannot be empty';
	String get hasAccount => 'Already have an account? Login';
	String get joinApartment => 'Join Apartment';
	String get inviteCode => 'Invite Code';
	String get inviteCodeHint => 'AP3-B12-A9F0';
	String get invalidInviteCodeFormat => 'Invalid invite code format (Ex: AP3-B12-A9F0)';
	String get invalidPhoneFormat => 'Enter a valid phone number (5XX XXX XX XX)';
	String get inviteCodeAndPasswordRequired => 'Invite code, name and password cannot be empty';
	String get invalidPhoneNumber => 'Enter a valid phone number';
	String get areYouManager => 'Are you a manager? Register';
}

// Path: features.apartments
class _StringsFeaturesApartmentsEn {
	_StringsFeaturesApartmentsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get residentPanel => 'Resident Panel';
}

// Path: <root>
class _StringsTr implements Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	_StringsTr.build({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = TranslationMetadata(
		    locale: AppLocale.tr,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <tr>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key);

	@override late final _StringsTr _root = this; // ignore: unused_field

	// Translations
	@override late final _StringsCommonTr common = _StringsCommonTr._(_root);
	@override late final _StringsValidationTr validation = _StringsValidationTr._(_root);
	@override late final _StringsFeaturesTr features = _StringsFeaturesTr._(_root);
	@override late final _StringsDbContextTr db_context = _StringsDbContextTr._(_root);
}

// Path: common
class _StringsCommonTr implements _StringsCommonEn {
	_StringsCommonTr._(this._root);

	@override final _StringsTr _root; // ignore: unused_field

	// Translations
	@override String get logout => 'Çıkış Yap';
	@override String get cancel => 'İptal';
	@override String get confirm => 'Onayla';
	@override String get save => 'Kaydet';
	@override String get delete => 'Sil';
	@override String get edit => 'Düzenle';
	@override String get close => 'Kapat';
	@override String get yes => 'Evet';
	@override String get no => 'Hayır';
	@override String get register => 'Kaydol';
	@override String get login => 'Giriş Yap';
	@override String get join => 'Katıl';
	@override String get confirmMessage => 'Emin misiniz?';
	@override String get logoutConfirm => 'Çıkış yapmak istediğinize emin misiniz?';
	@override String get logoutSuccess => 'Başarıyla çıkış yaptınız.';
	@override String get account => 'Hesap';
	@override String get changePassword => 'Şifre Değiştir';
	@override String get language => 'Dil';
	@override String get turkish => 'Türkçe';
	@override String get notifications => 'Bildirimler';
	@override String get info => 'Bilgi';
	@override String get privacyPolicy => 'Gizlilik Politikası';
	@override String get kvkk => 'KVKK';
	@override String get helpSupport => 'Yardım ve Destek';
	@override String get about => 'Hakkında';
	@override String get comingSoon => 'Bu özellik yakında eklenecek';
	@override String get multiLanguageComingSoon => 'Çoklu dil desteği yakında eklenecek';
	@override String get copyright => ' 2026 AidatPanel\nTüm hakları saklıdır.';
	@override String get aboutDescription => 'Türk apartman ve site yöneticileri için aidat yönetim platformu.';
	@override String get manager => 'Yönetici';
	@override String get resident => 'Sakin';
	@override String get tokenExpiryTest => 'Token Süresi Kontrol (Test)';
	@override String get tokenExpired => 'Token süresi DOLMUŞ! Login ekranına atılıyorsunuz.';
	@override String get tokenActive => 'Token aktif! Kalan süre';
	@override String get pressBackAgainToExit => 'Çıkmak için geri tuşuna tekrar basın';
	@override String get loading => 'Yükleniyor…';
	@override String get loadingBuildings => 'Binalar yükleniyor…';
	@override String get loadFailed => 'Yüklenemedi';
	@override String get tryAgain => 'Tekrar Dene';
	@override String get home => 'Ana Sayfa';
	@override String get buildings => 'Binalar';
	@override String get dues => 'Aidatlar';
	@override String get settings => 'Ayarlar';
	@override String get user => 'Kullanıcı';
	@override String get welcome => 'Hoş Geldiniz';
	@override String get managedBuildings => 'Yönetilen Binalar';
	@override String get issues => 'Arızalar';
	@override String get issuesTab => 'Arızalar Sekmesi';
	@override String get apartment => 'Daire';
	@override String get addBuilding => 'Bina Ekle';
	@override String get inviteCode => 'Davet Kodu';
	@override String get myBuildings => 'Binalarım';
	@override String get apartments => 'Daireler';
	@override String get collection => 'Tahsilat';
	@override String get duesTab => 'Aidatlar Sekmesi';
	@override String get totalApartments => 'Toplam Daire';
	@override String get occupiedApartments => 'Dolu Daire';
	@override String get duesCollection => 'Aidat Tahsilatı';
	@override String get totalDues => 'Toplam Aidat';
	@override String get recentTransactions => 'Son İşlemler';
	@override String get paid => 'Ödendi';
	@override String get pending => 'Beklemede';
	@override String get overdue => 'Gecikmiş';
	@override String get balance => 'Bakiye';
	@override String get amountDue => 'Ödenmesi Gereken';
	@override String get lastPayment => 'Son Ödeme';
	@override String get makePayment => 'Ödeme Yap';
	@override String get bills => 'Faturalar';
	@override String get support => 'Destek';
	@override String get residentName => 'Sakin Adı';
	@override String get addBuildingNew => 'Yeni Bina Ekle';
	@override String get basicInfo => 'Temel Bilgiler';
	@override String get buildingName => 'Bina Adı';
	@override String get buildingNameHint => 'Örn: Güneş Apartmanı';
	@override String get location => 'Konum';
	@override String get streetAddress => 'Sokak / Cadde Adresi';
	@override String get streetAddressHint => 'Örn: Bağdat Cad. No: 123';
	@override String get details => 'Detaylar';
	@override String get floorCount => 'Kat Sayısı';
	@override String get floorCountHint => '1 ile 200 arası';
	@override String get apartmentsPerFloor => 'Kattaki Daire';
	@override String get apartmentsPerFloorHint => '1 ile 50 arası';
	@override String get floorRangeError => 'Kat sayısı 1 ile 200 arasında olmalı';
	@override String get apartmentsPerFloorRangeError => 'Kat başına daire 1 ile 50 arasında olmalı';
	@override String get buildingAddFailed => 'Bina eklenemedi. Lütfen tekrar deneyin.';
	@override String get monthlyDues => 'Aylık Aidat';
	@override String get monthlyDuesLabel => 'Aylık Aidat (₺)';
	@override String get monthlyDuesHint => 'Örn: 1000';
	@override String get createBuilding => 'Bina Oluştur';
	@override String get cancelBtn => 'Vazgeç';
	@override String get cityRequired => 'Şehir *';
	@override String get selectCity => 'Şehir seçin';
	@override String get districtRequired => 'İlçe *';
	@override String get selectDistrict => 'İlçe seçin';
	@override String get selectCityFirst => 'Önce şehir seçin';
	@override String get selectCityTitle => 'Şehir Seçin';
	@override String get selectDistrictTitle => 'İlçe Seçin';
	@override String get search => 'Ara...';
	@override String get noResults => 'Sonuç bulunamadı';
	@override String get fieldRequired => 'boş bırakılamaz';
	@override String get fillRequiredFields => 'Lütfen zorunlu alanları doldurun';
	@override String get selectCityAndDistrict => 'Şehir ve ilçe seçmelisiniz';
	@override String get floorApartmentMustBePositive => 'Kat sayısı ve daire sayısı 0\'dan büyük olmalı';
	@override String get buildingAddedSuccess => 'Bina başarıyla eklendi';
	@override String get createInviteCode => 'Davet Kodu Oluştur';
	@override String get whichBuildingForCode => 'Hangi binadan kod üretilecek?';
	@override String get whichApartmentForCode => 'Hangi daire için kod üretilecek?';
	@override String get noApartmentsInBuilding => 'Bu binaya henüz daire eklenmemiş';
	@override String get activeCodeBadge => 'Aktif Kod';
	@override String get occupiedBadge => 'Dolu';
	@override String get emptyBadge => 'Boş';
	@override String get activeCodePrefix => 'Aktif kod';
	@override String get residentPrefix => 'Sakin';
	@override String get emptyApartment => 'Boş daire';
	@override String get codeRevoked => 'Kod iptal edildi';
	@override String get codeCopied => 'Kod kopyalandı';
	@override String get clipboardCopied => 'Mesaj panoya kopyalandı';
	@override String get expiresAtPrefix => 'Son kullanma';
	@override String get remainingPrefix => 'Kalan';
	@override String get buildingDetail => 'Bina Detayı';
	@override String get residents => 'Sakinler';
	@override String get apartmentsBadge => 'Daire';
	@override String get emptyApartmentText => 'Boş Daire';
	@override String get vacantBadge => 'Boş';
	@override String get phoneNotShared => 'Telefon paylaşılmadı';
	@override String get residentDetailsLink => 'Detaylar..';
	@override String get residentDetailsSheetTitle => 'Sakin bilgileri';
	@override String get apartmentDetailsSheetTitle => 'Daire bilgileri';
	@override String get noResidentAssigned => 'Sakin atanmamış';
	@override String get noApartmentsYet => 'Henüz daire eklenmemiş';
	@override String get paidStatus => 'Ödendi';
	@override String get pendingStatus => 'Bekliyor';
	@override String get overdueStatus => 'Gecikmiş';
	@override String get waivedStatus => 'Muaf';
	@override String get all => 'Tümü';
	@override String get status => 'Durum';
	@override String get month => 'Ay';
	@override String get monthJanuary => 'Ocak';
	@override String get monthFebruary => 'Şubat';
	@override String get monthMarch => 'Mart';
	@override String get monthApril => 'Nisan';
	@override String get monthMay => 'Mayıs';
	@override String get monthJune => 'Haziran';
	@override String get monthJuly => 'Temmuz';
	@override String get monthAugust => 'Ağustos';
	@override String get monthSeptember => 'Eylül';
	@override String get monthOctober => 'Ekim';
	@override String get monthNovember => 'Kasım';
	@override String get monthDecember => 'Aralık';
	@override String get allMonths => 'Tüm aylar';
	@override String get year => 'Yıl';
	@override String get allYears => 'Tüm yıllar';
	@override String get note => 'Not';
	@override String get myDuesHistory => 'Aidat Geçmişim';
	@override String get buildingDues => 'Bina Aidatları';
	@override String get noDuesYet => 'Henüz aidat kaydı yok';
	@override String get duesUpdated => 'Aidat durumu güncellendi';
	@override String get amount => 'Tutar';
	@override String get updateDueAmount => 'Aidat Tutarını Güncelle';
	@override String get dueAmountUpdated => 'Aidat tutarı güncellendi';
	@override String get dueAmountUpdateFailed => 'Aidat tutarı güncellenemedi';
	@override String get dueDay => 'Aidat Günü (1-28)';
	@override String get affectCurrentDues => 'Bekleyen aidatlara da uygula';
	@override String get affectCurrentDuesHint => 'Açık olduğunda mevcut bekleyen (PENDING) aidat tutarları da yeni tutara güncellenir.';
	@override String get dueUpdateNeedAmountOrDay => 'Güncellemek için tutar veya aidat gününden en az birini yazın.';
	@override String get dueUpdateNeedStoredAmount => 'Bu bina için kayıtlı tutar yok. Aidat gününü güncellemek için önce tutar yazın.';
	@override String get dueAmountInvalidPositive => 'Geçerli bir tutar yazın.';
	@override String get dueDayOutOfRange => 'Aidat günü 1 ile 28 arasında olmalıdır.';
	@override String get update => 'Güncelle';
	@override String get overdueDays => 'gün gecikmiş';
	@override String get dueDateLabel => 'Son ödeme';
	@override String get perMonth => '/ ay';
	@override String get floorLabel => 'KAT';
	@override String get apartmentLabel => 'DAİRE';
	@override String get turkishLanguage => 'Türkçe';
	@override String get englishLanguage => 'English';
	@override String get stepBuilding => 'Bina';
	@override String get stepApartment => 'Daire';
	@override String get stepCode => 'Kod';
	@override String get editBuilding => 'Binayı Düzenle';
	@override String get deleteBuilding => 'Binayı Sil';
	@override String get buildingUpdated => 'Bina güncellendi';
	@override String get buildingDeleted => 'Bina silindi';
	@override String get buildingUpdateFailed => 'Bina güncellenemedi';
	@override String get buildingDeleteFailed => 'Bina silinemedi';
	@override String get buildingDeleteFailedFK => 'Bu binayı silemezsiniz: hâlâ daire, sakin veya aidat kayıtları var. Önce daireleri/aidatları temizleyip tekrar deneyin.';
	@override String get deleteBuildingHeader => 'Bu işlem geri alınamaz.';
	@override String get deleteBuildingTypeHint => 'Onaylamak için aşağıya bina adını aynen yazın:';
	@override String get deleteBuildingTypeFieldLabel => 'Bina adı';
	@override String get buildingNameMismatch => 'Yazdığınız metin bina adıyla aynı değil.';
	@override String get editApartment => 'Daireyi Düzenle';
	@override String get deleteApartment => 'Daireyi Sil';
	@override String get apartmentUpdated => 'Daire güncellendi';
	@override String get apartmentDeleted => 'Daire silindi';
	@override String get apartmentUpdateFailed => 'Daire güncellenemedi';
	@override String get apartmentDeleteFailed => 'Daire silinemedi';
	@override String get apartmentDeleteFailedFK => 'Bu daireyi silemezsiniz: sakin veya aidat kayıtları var. Önce sakinin hesap kapatmasını bekleyip aidatları temizleyin.';
	@override String get deleteApartmentConfirm => 'Daireyi silmek istediğinize emin misiniz?';
	@override String get apartmentNumberLabel => 'Daire No (örn. 5A)';
	@override String get floorLabel2 => 'Kat (opsiyonel)';
	@override String get floorOptional => 'Kat (-5 ile 200 arası)';
	@override String get buildingNameField => 'Bina adı';
	@override String get buildingAddressField => 'Adres';
	@override String get buildingCityField => 'Şehir';
	@override String get monthlyDuesPerApartment => 'Aylık aidat / daire';
	@override String get remove => 'Çıkar';
	@override String get removeResident => 'Sakini Çıkar';
	@override String get removeResidentConfirm => 'Bu sakini daireden çıkarmak istediğinize emin misiniz?';
	@override String get removeResidentNote => 'Sakinin hesabı silinmez, sadece bu daireden bağlantısı kopar. Geçmiş aidat kayıtları korunur. Sakin başka bir daireye davet kodu ile tekrar katılabilir.';
	@override String get residentRemoved => 'Sakin daireden çıkarıldı';
	@override String get residentRemoveFailed => 'Sakin çıkarılamadı';
	@override String get residentRemoveForbidden => 'Bu işlem için yetkiniz yok. Yalnızca binanın yöneticisi sakin çıkarabilir.';
	@override String get residentRemoveNotFound => 'Bu dairede çıkarılacak sakin bulunamadı.';
	@override String get multiSelectResidents => 'Çoklu seç';
	@override String get multiSelectTapHint => 'Seçmek için karta dokunun';
	@override String get removeSelectedResidents => 'Seçilenleri çıkar';
	@override String get removeSelectedResidentsTitle => 'Seçilen sakinleri çıkar';
	@override String get removeSelectedResidentsMessage => 'Aşağıda listelenen dairelerde oturan sakinler daireden çıkarılır. Hesapları silinmez; yalnızca bu binadaki bağlantıları kalkar. Geçmiş aidat kayıtları korunur.';
	@override String get removeSelectedResidentsAffectedListTitle => 'Etkilenecek daireler';
	@override String get removeSelectedResidentsListUnavailable => 'Daire listesi şu an gösterilemiyor. Seçilen daire sayısı aşağıda; onaylarsanız işlem yine de uygulanır.';
	@override String get pickResidentsFirst => 'Önce listeden en az bir dolu daire seçin';
	@override String get removeSelectedProgress => 'İşlem yapılıyor…';
	@override String get removeSelectedSuccess => 'Seçilen sakinler dairelerden çıkarıldı';
	@override String get removeSelectedFailed => 'Seçilenleri çıkarma tamamlanamadı';
	@override String get currentPassword => 'Mevcut Şifre';
	@override String get newPassword => 'Yeni Şifre';
	@override String get newPasswordConfirm => 'Yeni Şifre (Tekrar)';
	@override String get currentPasswordRequired => 'Mevcut şifrenizi girin';
	@override String get passwordsMustDiffer => 'Yeni şifre eski şifre ile aynı olamaz';
	@override String get changePasswordTitle => 'Şifre Değiştir';
	@override String get changePasswordSubtitle => 'Güvenliğiniz için şifrenizi düzenli olarak değiştirin.';
	@override String get changePasswordSuccess => 'Şifreniz değiştirildi. Lütfen yeni şifrenizle tekrar giriş yapın.';
	@override String get changePasswordFailed => 'Şifre değiştirilemedi. Lütfen tekrar deneyin.';
	@override String get changePasswordWrongCurrent => 'Mevcut şifre hatalı.';
	@override String get deleteAccount => 'Hesabımı Kapat';
	@override String get deleteAccountTitle => 'Hesabınızı kapatmak istiyor musunuz?';
	@override String get deleteAccountWarning => 'Bu işlem geri alınamaz. Kişisel bilgileriniz silinir, ancak yasal nedenlerle bazı kayıtlar (aidat geçmişi gibi) anonim olarak saklanır.';
	@override String get deleteAccountTypeHint => 'Onaylamak için aşağıya "HESABIMI KAPAT" yazın:';
	@override String get deleteAccountTypePhrase => 'HESABIMI KAPAT';
	@override String get deleteAccountTypeMismatch => 'Yazdığınız metin eşleşmiyor.';
	@override String get deleteAccountConfirmButton => 'Hesabımı Kapat';
	@override String get deleteAccountSuccess => 'Hesabınız kapatıldı. Bizi tercih ettiğiniz için teşekkürler.';
	@override String get deleteAccountFailed => 'Hesap kapatılamadı. Lütfen tekrar deneyin.';
	@override String get deleteAccountFailedManager => 'Önce yönettiğiniz binaları silmeniz veya başka bir yöneticiye devretmeniz gerekiyor.';
	@override String get dangerZone => 'Tehlikeli Bölge';
	@override String get forgotPassword => 'Şifremi Unuttum';
	@override String get forgotPasswordTitle => 'Şifremi Unuttum';
	@override String get forgotPasswordSubtitle => 'Kayıtlı e-posta adresinizi girin, size bir sıfırlama kodu gönderelim.';
	@override String get forgotPasswordSuccess => 'Eğer bu e-posta sistemimizde kayıtlıysa, sıfırlama kodu gönderildi. Lütfen e-postanızı kontrol edin.';
	@override String get sendResetCode => 'Kodu Gönder';
	@override String get iHaveACode => 'Zaten kodum var';
	@override String get resetPasswordTitle => 'Yeni Şifre Belirle';
	@override String get resetPasswordSubtitle => 'E-postanıza gelen 6 haneli kodu ve yeni şifrenizi girin.';
	@override String get resetCode => 'Sıfırlama Kodu';
	@override String get resetCodeHint => 'ABC123';
	@override String get resetCodeRequired => 'Sıfırlama kodu gerekli';
	@override String get resetCodeInvalid => 'Kod 6 karakter olmalı';
	@override String get resetPasswordSuccess => 'Şifreniz sıfırlandı. Yeni şifrenizle giriş yapabilirsiniz.';
	@override String get resetPasswordFailed => 'Şifre sıfırlanamadı. Kod hatalı veya süresi dolmuş olabilir.';
	@override String get resetPasswordSubmit => 'Şifreyi Sıfırla';
	@override String get backToLogin => 'Giriş ekranına dön';
}

// Path: validation
class _StringsValidationTr implements _StringsValidationEn {
	_StringsValidationTr._(this._root);

	@override final _StringsTr _root; // ignore: unused_field

	// Translations
	@override String get emailRequired => 'Email adresi boş bırakılamaz';
	@override String get emailInvalid => 'Geçerli bir email adresi giriniz';
	@override String get emailTooLong => 'Email adresi çok uzun';
	@override String get phoneRequired => 'Telefon numarası boş bırakılamaz';
	@override String get phoneInvalid => 'Telefon numarası 10 haneli olmalıdır';
	@override String get passwordRequired => 'Şifre boş bırakılamaz';
	@override String get passwordTooShort => 'Şifre en az 6 karakter olmalıdır';
	@override String get passwordTooLong => 'Şifre çok uzun';
	@override String get passwordUppercaseRequired => 'Şifrede en az 1 büyük harf olmalıdır';
	@override String get passwordLowercaseRequired => 'Şifrede en az 1 küçük harf olmalıdır';
	@override String get passwordNumberRequired => 'Şifrede en az 1 rakam olmalıdır';
	@override String get passwordSpecialCharRequired => 'Şifrede en az 1 özel karakter olmalıdır';
}

// Path: features
class _StringsFeaturesTr implements _StringsFeaturesEn {
	_StringsFeaturesTr._(this._root);

	@override final _StringsTr _root; // ignore: unused_field

	// Translations
	@override late final _StringsFeaturesBuildingsTr buildings = _StringsFeaturesBuildingsTr._(_root);
	@override late final _StringsFeaturesAuthTr auth = _StringsFeaturesAuthTr._(_root);
	@override late final _StringsFeaturesApartmentsTr apartments = _StringsFeaturesApartmentsTr._(_root);
}

// Path: db_context
class _StringsDbContextTr implements _StringsDbContextEn {
	_StringsDbContextTr._(this._root);

	@override final _StringsTr _root; // ignore: unused_field

	// Translations
	@override String get user_entry => 'Kayıt: {value}';
	@override String get building_name => 'Bina: {value}';
	@override String get apartment_label => 'Daire: {value}';
	@override String get code_value => 'Kod: {value}';
	@override String get expiry_date => 'Son kullanma: {value}';
}

// Path: features.buildings
class _StringsFeaturesBuildingsTr implements _StringsFeaturesBuildingsEn {
	_StringsFeaturesBuildingsTr._(this._root);

	@override final _StringsTr _root; // ignore: unused_field

	// Translations
	@override String get managerPanel => 'Yönetici Paneli';
	@override String get buildingDetail => 'Bina Detayı';
	@override String get addBuilding => 'Bina Ekle';
	@override String get newBuilding => 'Yeni Bina Ekle';
	@override String get inviteCode => 'Davet Kodu';
	@override String get createInviteCode => 'Davet Kodu Oluştur';
	@override String get cancelCode => 'Kodu İptal Et';
	@override String get apartmentOccupied => 'Daire Dolu';
	@override String get copy => 'Kopyala';
	@override String get share => 'Paylaş';
	@override String get anotherApartment => 'Başka Daire';
	@override String get codeRevoked => 'Kod iptal edildi';
	@override String get occupiedDialog => 'Yeni kod üretirsen eski kullanıcı çıkarılır. Emin misiniz?';
	@override String get revokeDialog => 'Mevcut kod geçersiz hale gelir. Emin misiniz?';
	@override String get produceAnyway => 'Yine de Üret';
	@override String get newCodePrefix => 'Yeni kod üretirsen ';
	@override String get oldUserRemoved => 'eski kullanıcı çıkarılır';
	@override String get currentCodePrefix => 'Mevcut kod ';
	@override String get codeInvalid => 'geçersiz hale gelir';
	@override String get codeReady => 'Davet Kodu Hazır';
	@override String get code => 'KOD';
	@override String get validFor7Days => '7 gün geçerli';
	@override String get expiresAt => 'Son kullanma:';
	@override String get remaining => 'Kalan:';
	@override String get activeCodeNote => 'Bu kod aktifken aynı daireye yeni kod üretilemez. Yeni kod için önce mevcut kodu iptal etmelisin.';
	@override String get backToMainMenu => 'Ana Menüye Dön';
	@override String get tekrarDene => 'Tekrar Dene';
}

// Path: features.auth
class _StringsFeaturesAuthTr implements _StringsFeaturesAuthEn {
	_StringsFeaturesAuthTr._(this._root);

	@override final _StringsTr _root; // ignore: unused_field

	// Translations
	@override String get register => 'Kaydol';
	@override String get login => 'Giriş Yap';
	@override String get join => 'Katıl';
	@override String get passwordRequired => 'Şifre gerekli';
	@override String get errorOccurred => 'Bir hata oluştu';
	@override String get registrationSuccess => 'Hesabınız oluşturuldu. Giriş yapabilirsiniz.';
	@override String get loginSuccess => 'Giriş başarılı. Hoş geldiniz.';
	@override String get appTitle => 'AidatPanel';
	@override String get appSubtitle => 'Apartman Yönetim Sistemi';
	@override String get splashConnectionError => 'Sunucuya bağlanılamadı';
	@override String get splashConnectionHint => 'İnternet bağlantını kontrol edip tekrar dene.';
	@override String get skipToLogin => 'Giriş ekranına git';
	@override String get phone => 'Telefon';
	@override String get email => 'Email';
	@override String get phoneHint => '5XX XXX XX XX';
	@override String get emailHint => 'ornek@email.com';
	@override String get password => 'Şifre';
	@override String get passwordHint => '••••••••';
	@override String get emailLogin => 'Email ile Giriş Yap';
	@override String get phoneLogin => 'Telefon ile Giriş Yap';
	@override String get or => 'veya';
	@override String get noAccount => 'Hesabınız yok mu? Kaydolun';
	@override String get joinWithCode => 'Davet kodu ile katılın';
	@override String get copyright => '© Vefa Yazılım';
	@override String get createAccount => 'Yeni Hesap Oluştur';
	@override String get name => 'Ad Soyad';
	@override String get nameHint => 'Örn: Furkan Kaya';
	@override String get phoneOptional => 'Telefon (Opsiyonel)';
	@override String get phoneHintOptional => '5XX XXX XXXX';
	@override String get minLength => 'En az 6 karakter';
	@override String get hasUpperCase => 'En az 1 büyük harf';
	@override String get hasLowerCase => 'En az 1 küçük harf';
	@override String get hasNumber => 'En az 1 rakam';
	@override String get hasSpecialChar => 'En az 1 özel karakter';
	@override String get confirmPassword => 'Şifre Tekrar';
	@override String get passwordsDoNotMatch => 'Şifreler eşleşmiyor';
	@override String get emailAndPasswordRequired => 'Email ve şifre boş bırakılamaz';
	@override String get hasAccount => 'Zaten hesabınız var mı? Giriş yapın';
	@override String get joinApartment => 'Apartmana Katıl';
	@override String get inviteCode => 'Davet Kodu';
	@override String get inviteCodeHint => 'AP3-B12-A9F0';
	@override String get invalidInviteCodeFormat => 'Geçersiz davet kodu formatı (Örn: AP3-B12-A9F0)';
	@override String get invalidPhoneFormat => 'Geçerli bir telefon numarası giriniz (5XX XXX XX XX)';
	@override String get inviteCodeAndPasswordRequired => 'Davet kodu, ad ve şifre boş bırakılamaz';
	@override String get invalidPhoneNumber => 'Geçerli bir telefon numarası giriniz';
	@override String get areYouManager => 'Yönetici misiniz? Kaydolun';
}

// Path: features.apartments
class _StringsFeaturesApartmentsTr implements _StringsFeaturesApartmentsEn {
	_StringsFeaturesApartmentsTr._(this._root);

	@override final _StringsTr _root; // ignore: unused_field

	// Translations
	@override String get residentPanel => 'Sakin Paneli';
}

/// Flat map(s) containing all translations.
/// Only for edge cases! For simple maps, use the map function of this library.

extension on Translations {
	dynamic _flatMapFunction(String path) {
		switch (path) {
			case 'common.logout': return 'Logout';
			case 'common.cancel': return 'Cancel';
			case 'common.confirm': return 'Confirm';
			case 'common.save': return 'Save';
			case 'common.delete': return 'Delete';
			case 'common.edit': return 'Edit';
			case 'common.close': return 'Close';
			case 'common.yes': return 'Yes';
			case 'common.no': return 'No';
			case 'common.register': return 'Register';
			case 'common.login': return 'Login';
			case 'common.join': return 'Join';
			case 'common.confirmMessage': return 'Are you sure?';
			case 'common.logoutConfirm': return 'Are you sure you want to logout?';
			case 'common.logoutSuccess': return 'Signed out successfully.';
			case 'common.account': return 'Account';
			case 'common.changePassword': return 'Change Password';
			case 'common.language': return 'Language';
			case 'common.turkish': return 'Turkish';
			case 'common.notifications': return 'Notifications';
			case 'common.info': return 'Info';
			case 'common.privacyPolicy': return 'Privacy Policy';
			case 'common.kvkk': return 'KVKK';
			case 'common.helpSupport': return 'Help & Support';
			case 'common.about': return 'About';
			case 'common.comingSoon': return 'This feature will be added soon';
			case 'common.multiLanguageComingSoon': return 'Multi-language support coming soon';
			case 'common.copyright': return ' 2026 AidatPanel\nAll rights reserved.';
			case 'common.aboutDescription': return 'Dues management platform for Turkish apartment and site managers.';
			case 'common.manager': return 'Manager';
			case 'common.resident': return 'Resident';
			case 'common.tokenExpiryTest': return 'Token Expiry Check (Test)';
			case 'common.tokenExpired': return 'Token EXPIRED! Redirecting to login screen.';
			case 'common.tokenActive': return 'Token active! Remaining time';
			case 'common.pressBackAgainToExit': return 'Press back again to exit';
			case 'common.loading': return 'Loading…';
			case 'common.loadingBuildings': return 'Loading buildings…';
			case 'common.loadFailed': return 'Failed to load';
			case 'common.tryAgain': return 'Try Again';
			case 'common.home': return 'Home';
			case 'common.buildings': return 'Buildings';
			case 'common.dues': return 'Dues';
			case 'common.settings': return 'Settings';
			case 'common.user': return 'User';
			case 'common.welcome': return 'Welcome';
			case 'common.managedBuildings': return 'Managed Buildings';
			case 'common.issues': return 'Issues';
			case 'common.issuesTab': return 'Issues Tab';
			case 'common.apartment': return 'Apartment';
			case 'common.addBuilding': return 'Add Building';
			case 'common.inviteCode': return 'Invite Code';
			case 'common.myBuildings': return 'My Buildings';
			case 'common.apartments': return 'Apartments';
			case 'common.collection': return 'Collection';
			case 'common.monthlyDues': return 'Monthly Dues';
			case 'common.duesTab': return 'Dues Tab';
			case 'common.totalApartments': return 'Total Apartments';
			case 'common.occupiedApartments': return 'Occupied Apartments';
			case 'common.duesCollection': return 'Dues Collection';
			case 'common.totalDues': return 'Total Dues';
			case 'common.recentTransactions': return 'Recent Transactions';
			case 'common.paid': return 'Paid';
			case 'common.pending': return 'Pending';
			case 'common.overdue': return 'Overdue';
			case 'common.balance': return 'Balance';
			case 'common.amountDue': return 'Amount Due';
			case 'common.lastPayment': return 'Last Payment';
			case 'common.makePayment': return 'Make Payment';
			case 'common.bills': return 'Bills';
			case 'common.support': return 'Support';
			case 'common.residentName': return 'Resident Name';
			case 'common.addBuildingNew': return 'Add New Building';
			case 'common.basicInfo': return 'Basic Info';
			case 'common.buildingName': return 'Building Name';
			case 'common.buildingNameHint': return 'Ex: Güneş Apartmanı';
			case 'common.location': return 'Location';
			case 'common.streetAddress': return 'Street Address';
			case 'common.streetAddressHint': return 'Ex: Bağdat Cad. No: 123';
			case 'common.details': return 'Details';
			case 'common.floorCount': return 'Floor Count';
			case 'common.floorCountHint': return 'Between 1 and 200';
			case 'common.apartmentsPerFloor': return 'Apartments Per Floor';
			case 'common.apartmentsPerFloorHint': return 'Between 1 and 50';
			case 'common.floorRangeError': return 'Floor count must be between 1 and 200';
			case 'common.apartmentsPerFloorRangeError': return 'Apartments per floor must be between 1 and 50';
			case 'common.buildingAddFailed': return 'Could not add building. Please try again.';
			case 'common.monthlyDuesLabel': return 'Monthly Dues (₺)';
			case 'common.monthlyDuesHint': return 'Ex: 1000';
			case 'common.createBuilding': return 'Create Building';
			case 'common.cancelBtn': return 'Cancel';
			case 'common.cityRequired': return 'City *';
			case 'common.selectCity': return 'Select City';
			case 'common.districtRequired': return 'District *';
			case 'common.selectDistrict': return 'Select District';
			case 'common.selectCityFirst': return 'Select city first';
			case 'common.selectCityTitle': return 'Select City';
			case 'common.selectDistrictTitle': return 'Select District';
			case 'common.search': return 'Search...';
			case 'common.noResults': return 'No results found';
			case 'common.fieldRequired': return 'cannot be empty';
			case 'common.fillRequiredFields': return 'Please fill required fields';
			case 'common.selectCityAndDistrict': return 'You must select city and district';
			case 'common.floorApartmentMustBePositive': return 'Floor count and apartment count must be greater than 0';
			case 'common.buildingAddedSuccess': return 'Building added successfully';
			case 'common.createInviteCode': return 'Create Invite Code';
			case 'common.whichBuildingForCode': return 'Which building to generate code for?';
			case 'common.whichApartmentForCode': return 'Which apartment to generate code for?';
			case 'common.noApartmentsInBuilding': return 'No apartments added to this building yet';
			case 'common.activeCodeBadge': return 'Active Code';
			case 'common.occupiedBadge': return 'Occupied';
			case 'common.emptyBadge': return 'Empty';
			case 'common.activeCodePrefix': return 'Active code';
			case 'common.residentPrefix': return 'Resident';
			case 'common.emptyApartment': return 'Empty apartment';
			case 'common.codeRevoked': return 'Code revoked';
			case 'common.codeCopied': return 'Code copied';
			case 'common.clipboardCopied': return 'Message copied to clipboard';
			case 'common.expiresAtPrefix': return 'Expires at';
			case 'common.remainingPrefix': return 'Remaining';
			case 'common.buildingDetail': return 'Building Detail';
			case 'common.residents': return 'Residents';
			case 'common.apartmentsBadge': return 'Apartments';
			case 'common.emptyApartmentText': return 'Empty Apartment';
			case 'common.vacantBadge': return 'Vacant';
			case 'common.phoneNotShared': return 'Phone not shared';
			case 'common.residentDetailsLink': return 'Details..';
			case 'common.residentDetailsSheetTitle': return 'Resident information';
			case 'common.apartmentDetailsSheetTitle': return 'Apartment information';
			case 'common.noResidentAssigned': return 'No resident assigned';
			case 'common.noApartmentsYet': return 'No apartments added yet';
			case 'common.paidStatus': return 'Paid';
			case 'common.pendingStatus': return 'Pending';
			case 'common.overdueStatus': return 'Overdue';
			case 'common.waivedStatus': return 'Waived';
			case 'common.all': return 'All';
			case 'common.status': return 'Status';
			case 'common.month': return 'Month';
			case 'common.monthJanuary': return 'January';
			case 'common.monthFebruary': return 'February';
			case 'common.monthMarch': return 'March';
			case 'common.monthApril': return 'April';
			case 'common.monthMay': return 'May';
			case 'common.monthJune': return 'June';
			case 'common.monthJuly': return 'July';
			case 'common.monthAugust': return 'August';
			case 'common.monthSeptember': return 'September';
			case 'common.monthOctober': return 'October';
			case 'common.monthNovember': return 'November';
			case 'common.monthDecember': return 'December';
			case 'common.allMonths': return 'All months';
			case 'common.year': return 'Year';
			case 'common.allYears': return 'All years';
			case 'common.note': return 'Note';
			case 'common.myDuesHistory': return 'My Dues History';
			case 'common.buildingDues': return 'Building Dues';
			case 'common.noDuesYet': return 'No dues records yet';
			case 'common.duesUpdated': return 'Dues status updated';
			case 'common.amount': return 'Amount';
			case 'common.updateDueAmount': return 'Update Due Amount';
			case 'common.dueAmountUpdated': return 'Due amount updated';
			case 'common.dueAmountUpdateFailed': return 'Could not update due amount';
			case 'common.dueDay': return 'Due Day (1-28)';
			case 'common.affectCurrentDues': return 'Apply to pending dues';
			case 'common.affectCurrentDuesHint': return 'When enabled, current PENDING due amounts are updated to the new amount.';
			case 'common.dueUpdateNeedAmountOrDay': return 'Enter an amount or a due day (or both) to update.';
			case 'common.dueUpdateNeedStoredAmount': return 'This building has no saved amount yet. Enter an amount before updating the due day only.';
			case 'common.dueAmountInvalidPositive': return 'Enter a valid amount.';
			case 'common.dueDayOutOfRange': return 'Due day must be between 1 and 28.';
			case 'common.update': return 'Update';
			case 'common.overdueDays': return 'days overdue';
			case 'common.dueDateLabel': return 'Due date';
			case 'common.perMonth': return '/ month';
			case 'common.floorLabel': return 'FLOOR';
			case 'common.apartmentLabel': return 'APT';
			case 'common.turkishLanguage': return 'Türkçe';
			case 'common.englishLanguage': return 'English';
			case 'common.stepBuilding': return 'Building';
			case 'common.stepApartment': return 'Apartment';
			case 'common.stepCode': return 'Code';
			case 'common.editBuilding': return 'Edit Building';
			case 'common.deleteBuilding': return 'Delete Building';
			case 'common.buildingUpdated': return 'Building updated';
			case 'common.buildingDeleted': return 'Building deleted';
			case 'common.buildingUpdateFailed': return 'Could not update building';
			case 'common.buildingDeleteFailed': return 'Could not delete building';
			case 'common.buildingDeleteFailedFK': return 'Cannot delete this building: apartments, residents, or dues records still exist. Clean up apartments/dues first.';
			case 'common.deleteBuildingHeader': return 'This action cannot be undone.';
			case 'common.deleteBuildingTypeHint': return 'To confirm, type the building name below exactly:';
			case 'common.deleteBuildingTypeFieldLabel': return 'Building name';
			case 'common.buildingNameMismatch': return 'What you typed does not match the building name.';
			case 'common.editApartment': return 'Edit Apartment';
			case 'common.deleteApartment': return 'Delete Apartment';
			case 'common.apartmentUpdated': return 'Apartment updated';
			case 'common.apartmentDeleted': return 'Apartment deleted';
			case 'common.apartmentUpdateFailed': return 'Could not update apartment';
			case 'common.apartmentDeleteFailed': return 'Could not delete apartment';
			case 'common.apartmentDeleteFailedFK': return 'Cannot delete this apartment: resident or dues records exist. Wait for the resident to close their account and clean up dues.';
			case 'common.deleteApartmentConfirm': return 'Are you sure you want to delete this apartment?';
			case 'common.apartmentNumberLabel': return 'Apt No (e.g. 5A)';
			case 'common.floorLabel2': return 'Floor (optional)';
			case 'common.floorOptional': return 'Floor (-5 to 200)';
			case 'common.buildingNameField': return 'Building name';
			case 'common.buildingAddressField': return 'Address';
			case 'common.buildingCityField': return 'City';
			case 'common.monthlyDuesPerApartment': return 'Monthly dues / apt';
			case 'common.remove': return 'Remove';
			case 'common.removeResident': return 'Remove Resident';
			case 'common.removeResidentConfirm': return 'Are you sure you want to remove this resident from the apartment?';
			case 'common.removeResidentNote': return 'The resident\'s account will not be deleted; only their link to this apartment is removed. Past dues records are kept. The resident can join another apartment later using an invite code.';
			case 'common.residentRemoved': return 'Resident removed from apartment';
			case 'common.residentRemoveFailed': return 'Could not remove resident';
			case 'common.residentRemoveForbidden': return 'You are not allowed to perform this action. Only the building manager can remove residents.';
			case 'common.residentRemoveNotFound': return 'No resident to remove from this apartment.';
			case 'common.multiSelectResidents': return 'Select multiple';
			case 'common.multiSelectTapHint': return 'Tap the card to select or clear';
			case 'common.removeSelectedResidents': return 'Remove selected';
			case 'common.removeSelectedResidentsTitle': return 'Remove selected residents';
			case 'common.removeSelectedResidentsMessage': return 'Residents in the apartments listed below will be unlinked from their apartments. Accounts are not deleted—only the connection to this building is removed. Past dues records are kept.';
			case 'common.removeSelectedResidentsAffectedListTitle': return 'Apartments affected';
			case 'common.removeSelectedResidentsListUnavailable': return 'The apartment list could not be loaded. The count is shown below. If you confirm, removals will still proceed.';
			case 'common.pickResidentsFirst': return 'Select at least one occupied apartment from the list first';
			case 'common.removeSelectedProgress': return 'Working…';
			case 'common.removeSelectedSuccess': return 'Selected residents were removed from their apartments';
			case 'common.removeSelectedFailed': return 'Could not finish removing the selected residents';
			case 'common.currentPassword': return 'Current Password';
			case 'common.newPassword': return 'New Password';
			case 'common.newPasswordConfirm': return 'New Password (Repeat)';
			case 'common.currentPasswordRequired': return 'Enter your current password';
			case 'common.passwordsMustDiffer': return 'New password cannot be the same as the old one';
			case 'common.changePasswordTitle': return 'Change Password';
			case 'common.changePasswordSubtitle': return 'Update your password regularly to keep your account secure.';
			case 'common.changePasswordSuccess': return 'Your password has been changed. Please sign in again with your new password.';
			case 'common.changePasswordFailed': return 'Could not change password. Please try again.';
			case 'common.changePasswordWrongCurrent': return 'Current password is incorrect.';
			case 'common.deleteAccount': return 'Close My Account';
			case 'common.deleteAccountTitle': return 'Do you want to close your account?';
			case 'common.deleteAccountWarning': return 'This action cannot be undone. Your personal data will be removed, but for legal reasons some records (such as dues history) are kept anonymously.';
			case 'common.deleteAccountTypeHint': return 'To confirm, type "CLOSE MY ACCOUNT" below:';
			case 'common.deleteAccountTypePhrase': return 'CLOSE MY ACCOUNT';
			case 'common.deleteAccountTypeMismatch': return 'What you typed does not match.';
			case 'common.deleteAccountConfirmButton': return 'Close My Account';
			case 'common.deleteAccountSuccess': return 'Your account has been closed. Thank you for using AidatPanel.';
			case 'common.deleteAccountFailed': return 'Could not close account. Please try again.';
			case 'common.deleteAccountFailedManager': return 'You first need to delete the buildings you manage or transfer them to another manager.';
			case 'common.dangerZone': return 'Danger Zone';
			case 'common.forgotPassword': return 'Forgot Password';
			case 'common.forgotPasswordTitle': return 'Forgot Password';
			case 'common.forgotPasswordSubtitle': return 'Enter your registered email and we\'ll send you a reset code.';
			case 'common.forgotPasswordSuccess': return 'If this email is registered, a reset code has been sent. Please check your inbox.';
			case 'common.sendResetCode': return 'Send Code';
			case 'common.iHaveACode': return 'I already have a code';
			case 'common.resetPasswordTitle': return 'Set New Password';
			case 'common.resetPasswordSubtitle': return 'Enter the 6-character code from your email and a new password.';
			case 'common.resetCode': return 'Reset Code';
			case 'common.resetCodeHint': return 'ABC123';
			case 'common.resetCodeRequired': return 'Reset code required';
			case 'common.resetCodeInvalid': return 'Code must be 6 characters';
			case 'common.resetPasswordSuccess': return 'Your password has been reset. You can sign in with your new password.';
			case 'common.resetPasswordFailed': return 'Could not reset password. The code may be invalid or expired.';
			case 'common.resetPasswordSubmit': return 'Reset Password';
			case 'common.backToLogin': return 'Back to login';
			case 'validation.emailRequired': return 'Email address cannot be empty';
			case 'validation.emailInvalid': return 'Please enter a valid email address';
			case 'validation.emailTooLong': return 'Email address is too long';
			case 'validation.phoneRequired': return 'Phone number cannot be empty';
			case 'validation.phoneInvalid': return 'Phone number must be 10 digits';
			case 'validation.passwordRequired': return 'Password cannot be empty';
			case 'validation.passwordTooShort': return 'Password must be at least 6 characters';
			case 'validation.passwordTooLong': return 'Password is too long';
			case 'validation.passwordUppercaseRequired': return 'Password must contain at least 1 uppercase letter';
			case 'validation.passwordLowercaseRequired': return 'Password must contain at least 1 lowercase letter';
			case 'validation.passwordNumberRequired': return 'Password must contain at least 1 number';
			case 'validation.passwordSpecialCharRequired': return 'Password must contain at least 1 special character';
			case 'features.buildings.managerPanel': return 'Manager Panel';
			case 'features.buildings.buildingDetail': return 'Building Detail';
			case 'features.buildings.addBuilding': return 'Add Building';
			case 'features.buildings.newBuilding': return 'Add New Building';
			case 'features.buildings.inviteCode': return 'Invite Code';
			case 'features.buildings.createInviteCode': return 'Create Invite Code';
			case 'features.buildings.cancelCode': return 'Cancel Code';
			case 'features.buildings.apartmentOccupied': return 'Apartment Occupied';
			case 'features.buildings.copy': return 'Copy';
			case 'features.buildings.share': return 'Share';
			case 'features.buildings.anotherApartment': return 'Another Apartment';
			case 'features.buildings.codeRevoked': return 'Code revoked';
			case 'features.buildings.occupiedDialog': return 'If you generate a new code, the old user will be removed. Are you sure?';
			case 'features.buildings.revokeDialog': return 'The current code will become invalid. Are you sure?';
			case 'features.buildings.produceAnyway': return 'Produce Anyway';
			case 'features.buildings.newCodePrefix': return 'If you generate a new code, ';
			case 'features.buildings.oldUserRemoved': return 'the old user will be removed';
			case 'features.buildings.currentCodePrefix': return 'The current code ';
			case 'features.buildings.codeInvalid': return 'will become invalid';
			case 'features.buildings.codeReady': return 'Invite Code Ready';
			case 'features.buildings.code': return 'CODE';
			case 'features.buildings.validFor7Days': return 'Valid for 7 days';
			case 'features.buildings.expiresAt': return 'Expires at:';
			case 'features.buildings.remaining': return 'Remaining:';
			case 'features.buildings.activeCodeNote': return 'While this code is active, you cannot generate a new code for the same apartment. You must revoke the current code first.';
			case 'features.buildings.backToMainMenu': return 'Back to Main Menu';
			case 'features.buildings.tekrarDene': return 'Try Again';
			case 'features.auth.register': return 'Register';
			case 'features.auth.login': return 'Login';
			case 'features.auth.join': return 'Join';
			case 'features.auth.passwordRequired': return 'Password required';
			case 'features.auth.errorOccurred': return 'An error occurred';
			case 'features.auth.registrationSuccess': return 'Account created. You can now log in.';
			case 'features.auth.loginSuccess': return 'Signed in successfully. Welcome.';
			case 'features.auth.appTitle': return 'AidatPanel';
			case 'features.auth.appSubtitle': return 'Apartment Management System';
			case 'features.auth.splashConnectionError': return 'Could not connect to server';
			case 'features.auth.splashConnectionHint': return 'Check your connection and try again.';
			case 'features.auth.skipToLogin': return 'Go to login';
			case 'features.auth.phone': return 'Phone';
			case 'features.auth.email': return 'Email';
			case 'features.auth.phoneHint': return '5XX XXX XX XX';
			case 'features.auth.emailHint': return 'example@email.com';
			case 'features.auth.password': return 'Password';
			case 'features.auth.passwordHint': return '••••••••';
			case 'features.auth.emailLogin': return 'Login with Email';
			case 'features.auth.phoneLogin': return 'Login with Phone';
			case 'features.auth.or': return 'or';
			case 'features.auth.noAccount': return 'Don\'t have an account? Register';
			case 'features.auth.joinWithCode': return 'Join with Invite Code';
			case 'features.auth.copyright': return '© Vefa Yazılım';
			case 'features.auth.createAccount': return 'Create New Account';
			case 'features.auth.name': return 'Full Name';
			case 'features.auth.nameHint': return 'Ex: Furkan Kaya';
			case 'features.auth.phoneOptional': return 'Phone (Optional)';
			case 'features.auth.phoneHintOptional': return '5XX XXX XXXX';
			case 'features.auth.minLength': return 'At least 6 characters';
			case 'features.auth.hasUpperCase': return 'At least 1 uppercase letter';
			case 'features.auth.hasLowerCase': return 'At least 1 lowercase letter';
			case 'features.auth.hasNumber': return 'At least 1 number';
			case 'features.auth.hasSpecialChar': return 'At least 1 special character';
			case 'features.auth.confirmPassword': return 'Confirm Password';
			case 'features.auth.passwordsDoNotMatch': return 'Passwords do not match';
			case 'features.auth.emailAndPasswordRequired': return 'Email and password cannot be empty';
			case 'features.auth.hasAccount': return 'Already have an account? Login';
			case 'features.auth.joinApartment': return 'Join Apartment';
			case 'features.auth.inviteCode': return 'Invite Code';
			case 'features.auth.inviteCodeHint': return 'AP3-B12-A9F0';
			case 'features.auth.invalidInviteCodeFormat': return 'Invalid invite code format (Ex: AP3-B12-A9F0)';
			case 'features.auth.invalidPhoneFormat': return 'Enter a valid phone number (5XX XXX XX XX)';
			case 'features.auth.inviteCodeAndPasswordRequired': return 'Invite code, name and password cannot be empty';
			case 'features.auth.invalidPhoneNumber': return 'Enter a valid phone number';
			case 'features.auth.areYouManager': return 'Are you a manager? Register';
			case 'features.apartments.residentPanel': return 'Resident Panel';
			case 'db_context.user_entry': return 'Record: {value}';
			case 'db_context.building_name': return 'Building: {value}';
			case 'db_context.apartment_label': return 'Apartment: {value}';
			case 'db_context.code_value': return 'Code: {value}';
			case 'db_context.expiry_date': return 'Expires at: {value}';
			default: return null;
		}
	}
}

extension on _StringsTr {
	dynamic _flatMapFunction(String path) {
		switch (path) {
			case 'common.logout': return 'Çıkış Yap';
			case 'common.cancel': return 'İptal';
			case 'common.confirm': return 'Onayla';
			case 'common.save': return 'Kaydet';
			case 'common.delete': return 'Sil';
			case 'common.edit': return 'Düzenle';
			case 'common.close': return 'Kapat';
			case 'common.yes': return 'Evet';
			case 'common.no': return 'Hayır';
			case 'common.register': return 'Kaydol';
			case 'common.login': return 'Giriş Yap';
			case 'common.join': return 'Katıl';
			case 'common.confirmMessage': return 'Emin misiniz?';
			case 'common.logoutConfirm': return 'Çıkış yapmak istediğinize emin misiniz?';
			case 'common.logoutSuccess': return 'Başarıyla çıkış yaptınız.';
			case 'common.account': return 'Hesap';
			case 'common.changePassword': return 'Şifre Değiştir';
			case 'common.language': return 'Dil';
			case 'common.turkish': return 'Türkçe';
			case 'common.notifications': return 'Bildirimler';
			case 'common.info': return 'Bilgi';
			case 'common.privacyPolicy': return 'Gizlilik Politikası';
			case 'common.kvkk': return 'KVKK';
			case 'common.helpSupport': return 'Yardım ve Destek';
			case 'common.about': return 'Hakkında';
			case 'common.comingSoon': return 'Bu özellik yakında eklenecek';
			case 'common.multiLanguageComingSoon': return 'Çoklu dil desteği yakında eklenecek';
			case 'common.copyright': return ' 2026 AidatPanel\nTüm hakları saklıdır.';
			case 'common.aboutDescription': return 'Türk apartman ve site yöneticileri için aidat yönetim platformu.';
			case 'common.manager': return 'Yönetici';
			case 'common.resident': return 'Sakin';
			case 'common.tokenExpiryTest': return 'Token Süresi Kontrol (Test)';
			case 'common.tokenExpired': return 'Token süresi DOLMUŞ! Login ekranına atılıyorsunuz.';
			case 'common.tokenActive': return 'Token aktif! Kalan süre';
			case 'common.pressBackAgainToExit': return 'Çıkmak için geri tuşuna tekrar basın';
			case 'common.loading': return 'Yükleniyor…';
			case 'common.loadingBuildings': return 'Binalar yükleniyor…';
			case 'common.loadFailed': return 'Yüklenemedi';
			case 'common.tryAgain': return 'Tekrar Dene';
			case 'common.home': return 'Ana Sayfa';
			case 'common.buildings': return 'Binalar';
			case 'common.dues': return 'Aidatlar';
			case 'common.settings': return 'Ayarlar';
			case 'common.user': return 'Kullanıcı';
			case 'common.welcome': return 'Hoş Geldiniz';
			case 'common.managedBuildings': return 'Yönetilen Binalar';
			case 'common.issues': return 'Arızalar';
			case 'common.issuesTab': return 'Arızalar Sekmesi';
			case 'common.apartment': return 'Daire';
			case 'common.addBuilding': return 'Bina Ekle';
			case 'common.inviteCode': return 'Davet Kodu';
			case 'common.myBuildings': return 'Binalarım';
			case 'common.apartments': return 'Daireler';
			case 'common.collection': return 'Tahsilat';
			case 'common.duesTab': return 'Aidatlar Sekmesi';
			case 'common.totalApartments': return 'Toplam Daire';
			case 'common.occupiedApartments': return 'Dolu Daire';
			case 'common.duesCollection': return 'Aidat Tahsilatı';
			case 'common.totalDues': return 'Toplam Aidat';
			case 'common.recentTransactions': return 'Son İşlemler';
			case 'common.paid': return 'Ödendi';
			case 'common.pending': return 'Beklemede';
			case 'common.overdue': return 'Gecikmiş';
			case 'common.balance': return 'Bakiye';
			case 'common.amountDue': return 'Ödenmesi Gereken';
			case 'common.lastPayment': return 'Son Ödeme';
			case 'common.makePayment': return 'Ödeme Yap';
			case 'common.bills': return 'Faturalar';
			case 'common.support': return 'Destek';
			case 'common.residentName': return 'Sakin Adı';
			case 'common.addBuildingNew': return 'Yeni Bina Ekle';
			case 'common.basicInfo': return 'Temel Bilgiler';
			case 'common.buildingName': return 'Bina Adı';
			case 'common.buildingNameHint': return 'Örn: Güneş Apartmanı';
			case 'common.location': return 'Konum';
			case 'common.streetAddress': return 'Sokak / Cadde Adresi';
			case 'common.streetAddressHint': return 'Örn: Bağdat Cad. No: 123';
			case 'common.details': return 'Detaylar';
			case 'common.floorCount': return 'Kat Sayısı';
			case 'common.floorCountHint': return '1 ile 200 arası';
			case 'common.apartmentsPerFloor': return 'Kattaki Daire';
			case 'common.apartmentsPerFloorHint': return '1 ile 50 arası';
			case 'common.floorRangeError': return 'Kat sayısı 1 ile 200 arasında olmalı';
			case 'common.apartmentsPerFloorRangeError': return 'Kat başına daire 1 ile 50 arasında olmalı';
			case 'common.buildingAddFailed': return 'Bina eklenemedi. Lütfen tekrar deneyin.';
			case 'common.monthlyDues': return 'Aylık Aidat';
			case 'common.monthlyDuesLabel': return 'Aylık Aidat (₺)';
			case 'common.monthlyDuesHint': return 'Örn: 1000';
			case 'common.createBuilding': return 'Bina Oluştur';
			case 'common.cancelBtn': return 'Vazgeç';
			case 'common.cityRequired': return 'Şehir *';
			case 'common.selectCity': return 'Şehir seçin';
			case 'common.districtRequired': return 'İlçe *';
			case 'common.selectDistrict': return 'İlçe seçin';
			case 'common.selectCityFirst': return 'Önce şehir seçin';
			case 'common.selectCityTitle': return 'Şehir Seçin';
			case 'common.selectDistrictTitle': return 'İlçe Seçin';
			case 'common.search': return 'Ara...';
			case 'common.noResults': return 'Sonuç bulunamadı';
			case 'common.fieldRequired': return 'boş bırakılamaz';
			case 'common.fillRequiredFields': return 'Lütfen zorunlu alanları doldurun';
			case 'common.selectCityAndDistrict': return 'Şehir ve ilçe seçmelisiniz';
			case 'common.floorApartmentMustBePositive': return 'Kat sayısı ve daire sayısı 0\'dan büyük olmalı';
			case 'common.buildingAddedSuccess': return 'Bina başarıyla eklendi';
			case 'common.createInviteCode': return 'Davet Kodu Oluştur';
			case 'common.whichBuildingForCode': return 'Hangi binadan kod üretilecek?';
			case 'common.whichApartmentForCode': return 'Hangi daire için kod üretilecek?';
			case 'common.noApartmentsInBuilding': return 'Bu binaya henüz daire eklenmemiş';
			case 'common.activeCodeBadge': return 'Aktif Kod';
			case 'common.occupiedBadge': return 'Dolu';
			case 'common.emptyBadge': return 'Boş';
			case 'common.activeCodePrefix': return 'Aktif kod';
			case 'common.residentPrefix': return 'Sakin';
			case 'common.emptyApartment': return 'Boş daire';
			case 'common.codeRevoked': return 'Kod iptal edildi';
			case 'common.codeCopied': return 'Kod kopyalandı';
			case 'common.clipboardCopied': return 'Mesaj panoya kopyalandı';
			case 'common.expiresAtPrefix': return 'Son kullanma';
			case 'common.remainingPrefix': return 'Kalan';
			case 'common.buildingDetail': return 'Bina Detayı';
			case 'common.residents': return 'Sakinler';
			case 'common.apartmentsBadge': return 'Daire';
			case 'common.emptyApartmentText': return 'Boş Daire';
			case 'common.vacantBadge': return 'Boş';
			case 'common.phoneNotShared': return 'Telefon paylaşılmadı';
			case 'common.residentDetailsLink': return 'Detaylar..';
			case 'common.residentDetailsSheetTitle': return 'Sakin bilgileri';
			case 'common.apartmentDetailsSheetTitle': return 'Daire bilgileri';
			case 'common.noResidentAssigned': return 'Sakin atanmamış';
			case 'common.noApartmentsYet': return 'Henüz daire eklenmemiş';
			case 'common.paidStatus': return 'Ödendi';
			case 'common.pendingStatus': return 'Bekliyor';
			case 'common.overdueStatus': return 'Gecikmiş';
			case 'common.waivedStatus': return 'Muaf';
			case 'common.all': return 'Tümü';
			case 'common.status': return 'Durum';
			case 'common.month': return 'Ay';
			case 'common.monthJanuary': return 'Ocak';
			case 'common.monthFebruary': return 'Şubat';
			case 'common.monthMarch': return 'Mart';
			case 'common.monthApril': return 'Nisan';
			case 'common.monthMay': return 'Mayıs';
			case 'common.monthJune': return 'Haziran';
			case 'common.monthJuly': return 'Temmuz';
			case 'common.monthAugust': return 'Ağustos';
			case 'common.monthSeptember': return 'Eylül';
			case 'common.monthOctober': return 'Ekim';
			case 'common.monthNovember': return 'Kasım';
			case 'common.monthDecember': return 'Aralık';
			case 'common.allMonths': return 'Tüm aylar';
			case 'common.year': return 'Yıl';
			case 'common.allYears': return 'Tüm yıllar';
			case 'common.note': return 'Not';
			case 'common.myDuesHistory': return 'Aidat Geçmişim';
			case 'common.buildingDues': return 'Bina Aidatları';
			case 'common.noDuesYet': return 'Henüz aidat kaydı yok';
			case 'common.duesUpdated': return 'Aidat durumu güncellendi';
			case 'common.amount': return 'Tutar';
			case 'common.updateDueAmount': return 'Aidat Tutarını Güncelle';
			case 'common.dueAmountUpdated': return 'Aidat tutarı güncellendi';
			case 'common.dueAmountUpdateFailed': return 'Aidat tutarı güncellenemedi';
			case 'common.dueDay': return 'Aidat Günü (1-28)';
			case 'common.affectCurrentDues': return 'Bekleyen aidatlara da uygula';
			case 'common.affectCurrentDuesHint': return 'Açık olduğunda mevcut bekleyen (PENDING) aidat tutarları da yeni tutara güncellenir.';
			case 'common.dueUpdateNeedAmountOrDay': return 'Güncellemek için tutar veya aidat gününden en az birini yazın.';
			case 'common.dueUpdateNeedStoredAmount': return 'Bu bina için kayıtlı tutar yok. Aidat gününü güncellemek için önce tutar yazın.';
			case 'common.dueAmountInvalidPositive': return 'Geçerli bir tutar yazın.';
			case 'common.dueDayOutOfRange': return 'Aidat günü 1 ile 28 arasında olmalıdır.';
			case 'common.update': return 'Güncelle';
			case 'common.overdueDays': return 'gün gecikmiş';
			case 'common.dueDateLabel': return 'Son ödeme';
			case 'common.perMonth': return '/ ay';
			case 'common.floorLabel': return 'KAT';
			case 'common.apartmentLabel': return 'DAİRE';
			case 'common.turkishLanguage': return 'Türkçe';
			case 'common.englishLanguage': return 'English';
			case 'common.stepBuilding': return 'Bina';
			case 'common.stepApartment': return 'Daire';
			case 'common.stepCode': return 'Kod';
			case 'common.editBuilding': return 'Binayı Düzenle';
			case 'common.deleteBuilding': return 'Binayı Sil';
			case 'common.buildingUpdated': return 'Bina güncellendi';
			case 'common.buildingDeleted': return 'Bina silindi';
			case 'common.buildingUpdateFailed': return 'Bina güncellenemedi';
			case 'common.buildingDeleteFailed': return 'Bina silinemedi';
			case 'common.buildingDeleteFailedFK': return 'Bu binayı silemezsiniz: hâlâ daire, sakin veya aidat kayıtları var. Önce daireleri/aidatları temizleyip tekrar deneyin.';
			case 'common.deleteBuildingHeader': return 'Bu işlem geri alınamaz.';
			case 'common.deleteBuildingTypeHint': return 'Onaylamak için aşağıya bina adını aynen yazın:';
			case 'common.deleteBuildingTypeFieldLabel': return 'Bina adı';
			case 'common.buildingNameMismatch': return 'Yazdığınız metin bina adıyla aynı değil.';
			case 'common.editApartment': return 'Daireyi Düzenle';
			case 'common.deleteApartment': return 'Daireyi Sil';
			case 'common.apartmentUpdated': return 'Daire güncellendi';
			case 'common.apartmentDeleted': return 'Daire silindi';
			case 'common.apartmentUpdateFailed': return 'Daire güncellenemedi';
			case 'common.apartmentDeleteFailed': return 'Daire silinemedi';
			case 'common.apartmentDeleteFailedFK': return 'Bu daireyi silemezsiniz: sakin veya aidat kayıtları var. Önce sakinin hesap kapatmasını bekleyip aidatları temizleyin.';
			case 'common.deleteApartmentConfirm': return 'Daireyi silmek istediğinize emin misiniz?';
			case 'common.apartmentNumberLabel': return 'Daire No (örn. 5A)';
			case 'common.floorLabel2': return 'Kat (opsiyonel)';
			case 'common.floorOptional': return 'Kat (-5 ile 200 arası)';
			case 'common.buildingNameField': return 'Bina adı';
			case 'common.buildingAddressField': return 'Adres';
			case 'common.buildingCityField': return 'Şehir';
			case 'common.monthlyDuesPerApartment': return 'Aylık aidat / daire';
			case 'common.remove': return 'Çıkar';
			case 'common.removeResident': return 'Sakini Çıkar';
			case 'common.removeResidentConfirm': return 'Bu sakini daireden çıkarmak istediğinize emin misiniz?';
			case 'common.removeResidentNote': return 'Sakinin hesabı silinmez, sadece bu daireden bağlantısı kopar. Geçmiş aidat kayıtları korunur. Sakin başka bir daireye davet kodu ile tekrar katılabilir.';
			case 'common.residentRemoved': return 'Sakin daireden çıkarıldı';
			case 'common.residentRemoveFailed': return 'Sakin çıkarılamadı';
			case 'common.residentRemoveForbidden': return 'Bu işlem için yetkiniz yok. Yalnızca binanın yöneticisi sakin çıkarabilir.';
			case 'common.residentRemoveNotFound': return 'Bu dairede çıkarılacak sakin bulunamadı.';
			case 'common.multiSelectResidents': return 'Çoklu seç';
			case 'common.multiSelectTapHint': return 'Seçmek için karta dokunun';
			case 'common.removeSelectedResidents': return 'Seçilenleri çıkar';
			case 'common.removeSelectedResidentsTitle': return 'Seçilen sakinleri çıkar';
			case 'common.removeSelectedResidentsMessage': return 'Aşağıda listelenen dairelerde oturan sakinler daireden çıkarılır. Hesapları silinmez; yalnızca bu binadaki bağlantıları kalkar. Geçmiş aidat kayıtları korunur.';
			case 'common.removeSelectedResidentsAffectedListTitle': return 'Etkilenecek daireler';
			case 'common.removeSelectedResidentsListUnavailable': return 'Daire listesi şu an gösterilemiyor. Seçilen daire sayısı aşağıda; onaylarsanız işlem yine de uygulanır.';
			case 'common.pickResidentsFirst': return 'Önce listeden en az bir dolu daire seçin';
			case 'common.removeSelectedProgress': return 'İşlem yapılıyor…';
			case 'common.removeSelectedSuccess': return 'Seçilen sakinler dairelerden çıkarıldı';
			case 'common.removeSelectedFailed': return 'Seçilenleri çıkarma tamamlanamadı';
			case 'common.currentPassword': return 'Mevcut Şifre';
			case 'common.newPassword': return 'Yeni Şifre';
			case 'common.newPasswordConfirm': return 'Yeni Şifre (Tekrar)';
			case 'common.currentPasswordRequired': return 'Mevcut şifrenizi girin';
			case 'common.passwordsMustDiffer': return 'Yeni şifre eski şifre ile aynı olamaz';
			case 'common.changePasswordTitle': return 'Şifre Değiştir';
			case 'common.changePasswordSubtitle': return 'Güvenliğiniz için şifrenizi düzenli olarak değiştirin.';
			case 'common.changePasswordSuccess': return 'Şifreniz değiştirildi. Lütfen yeni şifrenizle tekrar giriş yapın.';
			case 'common.changePasswordFailed': return 'Şifre değiştirilemedi. Lütfen tekrar deneyin.';
			case 'common.changePasswordWrongCurrent': return 'Mevcut şifre hatalı.';
			case 'common.deleteAccount': return 'Hesabımı Kapat';
			case 'common.deleteAccountTitle': return 'Hesabınızı kapatmak istiyor musunuz?';
			case 'common.deleteAccountWarning': return 'Bu işlem geri alınamaz. Kişisel bilgileriniz silinir, ancak yasal nedenlerle bazı kayıtlar (aidat geçmişi gibi) anonim olarak saklanır.';
			case 'common.deleteAccountTypeHint': return 'Onaylamak için aşağıya "HESABIMI KAPAT" yazın:';
			case 'common.deleteAccountTypePhrase': return 'HESABIMI KAPAT';
			case 'common.deleteAccountTypeMismatch': return 'Yazdığınız metin eşleşmiyor.';
			case 'common.deleteAccountConfirmButton': return 'Hesabımı Kapat';
			case 'common.deleteAccountSuccess': return 'Hesabınız kapatıldı. Bizi tercih ettiğiniz için teşekkürler.';
			case 'common.deleteAccountFailed': return 'Hesap kapatılamadı. Lütfen tekrar deneyin.';
			case 'common.deleteAccountFailedManager': return 'Önce yönettiğiniz binaları silmeniz veya başka bir yöneticiye devretmeniz gerekiyor.';
			case 'common.dangerZone': return 'Tehlikeli Bölge';
			case 'common.forgotPassword': return 'Şifremi Unuttum';
			case 'common.forgotPasswordTitle': return 'Şifremi Unuttum';
			case 'common.forgotPasswordSubtitle': return 'Kayıtlı e-posta adresinizi girin, size bir sıfırlama kodu gönderelim.';
			case 'common.forgotPasswordSuccess': return 'Eğer bu e-posta sistemimizde kayıtlıysa, sıfırlama kodu gönderildi. Lütfen e-postanızı kontrol edin.';
			case 'common.sendResetCode': return 'Kodu Gönder';
			case 'common.iHaveACode': return 'Zaten kodum var';
			case 'common.resetPasswordTitle': return 'Yeni Şifre Belirle';
			case 'common.resetPasswordSubtitle': return 'E-postanıza gelen 6 haneli kodu ve yeni şifrenizi girin.';
			case 'common.resetCode': return 'Sıfırlama Kodu';
			case 'common.resetCodeHint': return 'ABC123';
			case 'common.resetCodeRequired': return 'Sıfırlama kodu gerekli';
			case 'common.resetCodeInvalid': return 'Kod 6 karakter olmalı';
			case 'common.resetPasswordSuccess': return 'Şifreniz sıfırlandı. Yeni şifrenizle giriş yapabilirsiniz.';
			case 'common.resetPasswordFailed': return 'Şifre sıfırlanamadı. Kod hatalı veya süresi dolmuş olabilir.';
			case 'common.resetPasswordSubmit': return 'Şifreyi Sıfırla';
			case 'common.backToLogin': return 'Giriş ekranına dön';
			case 'validation.emailRequired': return 'Email adresi boş bırakılamaz';
			case 'validation.emailInvalid': return 'Geçerli bir email adresi giriniz';
			case 'validation.emailTooLong': return 'Email adresi çok uzun';
			case 'validation.phoneRequired': return 'Telefon numarası boş bırakılamaz';
			case 'validation.phoneInvalid': return 'Telefon numarası 10 haneli olmalıdır';
			case 'validation.passwordRequired': return 'Şifre boş bırakılamaz';
			case 'validation.passwordTooShort': return 'Şifre en az 6 karakter olmalıdır';
			case 'validation.passwordTooLong': return 'Şifre çok uzun';
			case 'validation.passwordUppercaseRequired': return 'Şifrede en az 1 büyük harf olmalıdır';
			case 'validation.passwordLowercaseRequired': return 'Şifrede en az 1 küçük harf olmalıdır';
			case 'validation.passwordNumberRequired': return 'Şifrede en az 1 rakam olmalıdır';
			case 'validation.passwordSpecialCharRequired': return 'Şifrede en az 1 özel karakter olmalıdır';
			case 'features.buildings.managerPanel': return 'Yönetici Paneli';
			case 'features.buildings.buildingDetail': return 'Bina Detayı';
			case 'features.buildings.addBuilding': return 'Bina Ekle';
			case 'features.buildings.newBuilding': return 'Yeni Bina Ekle';
			case 'features.buildings.inviteCode': return 'Davet Kodu';
			case 'features.buildings.createInviteCode': return 'Davet Kodu Oluştur';
			case 'features.buildings.cancelCode': return 'Kodu İptal Et';
			case 'features.buildings.apartmentOccupied': return 'Daire Dolu';
			case 'features.buildings.copy': return 'Kopyala';
			case 'features.buildings.share': return 'Paylaş';
			case 'features.buildings.anotherApartment': return 'Başka Daire';
			case 'features.buildings.codeRevoked': return 'Kod iptal edildi';
			case 'features.buildings.occupiedDialog': return 'Yeni kod üretirsen eski kullanıcı çıkarılır. Emin misiniz?';
			case 'features.buildings.revokeDialog': return 'Mevcut kod geçersiz hale gelir. Emin misiniz?';
			case 'features.buildings.produceAnyway': return 'Yine de Üret';
			case 'features.buildings.newCodePrefix': return 'Yeni kod üretirsen ';
			case 'features.buildings.oldUserRemoved': return 'eski kullanıcı çıkarılır';
			case 'features.buildings.currentCodePrefix': return 'Mevcut kod ';
			case 'features.buildings.codeInvalid': return 'geçersiz hale gelir';
			case 'features.buildings.codeReady': return 'Davet Kodu Hazır';
			case 'features.buildings.code': return 'KOD';
			case 'features.buildings.validFor7Days': return '7 gün geçerli';
			case 'features.buildings.expiresAt': return 'Son kullanma:';
			case 'features.buildings.remaining': return 'Kalan:';
			case 'features.buildings.activeCodeNote': return 'Bu kod aktifken aynı daireye yeni kod üretilemez. Yeni kod için önce mevcut kodu iptal etmelisin.';
			case 'features.buildings.backToMainMenu': return 'Ana Menüye Dön';
			case 'features.buildings.tekrarDene': return 'Tekrar Dene';
			case 'features.auth.register': return 'Kaydol';
			case 'features.auth.login': return 'Giriş Yap';
			case 'features.auth.join': return 'Katıl';
			case 'features.auth.passwordRequired': return 'Şifre gerekli';
			case 'features.auth.errorOccurred': return 'Bir hata oluştu';
			case 'features.auth.registrationSuccess': return 'Hesabınız oluşturuldu. Giriş yapabilirsiniz.';
			case 'features.auth.loginSuccess': return 'Giriş başarılı. Hoş geldiniz.';
			case 'features.auth.appTitle': return 'AidatPanel';
			case 'features.auth.appSubtitle': return 'Apartman Yönetim Sistemi';
			case 'features.auth.splashConnectionError': return 'Sunucuya bağlanılamadı';
			case 'features.auth.splashConnectionHint': return 'İnternet bağlantını kontrol edip tekrar dene.';
			case 'features.auth.skipToLogin': return 'Giriş ekranına git';
			case 'features.auth.phone': return 'Telefon';
			case 'features.auth.email': return 'Email';
			case 'features.auth.phoneHint': return '5XX XXX XX XX';
			case 'features.auth.emailHint': return 'ornek@email.com';
			case 'features.auth.password': return 'Şifre';
			case 'features.auth.passwordHint': return '••••••••';
			case 'features.auth.emailLogin': return 'Email ile Giriş Yap';
			case 'features.auth.phoneLogin': return 'Telefon ile Giriş Yap';
			case 'features.auth.or': return 'veya';
			case 'features.auth.noAccount': return 'Hesabınız yok mu? Kaydolun';
			case 'features.auth.joinWithCode': return 'Davet kodu ile katılın';
			case 'features.auth.copyright': return '© Vefa Yazılım';
			case 'features.auth.createAccount': return 'Yeni Hesap Oluştur';
			case 'features.auth.name': return 'Ad Soyad';
			case 'features.auth.nameHint': return 'Örn: Furkan Kaya';
			case 'features.auth.phoneOptional': return 'Telefon (Opsiyonel)';
			case 'features.auth.phoneHintOptional': return '5XX XXX XXXX';
			case 'features.auth.minLength': return 'En az 6 karakter';
			case 'features.auth.hasUpperCase': return 'En az 1 büyük harf';
			case 'features.auth.hasLowerCase': return 'En az 1 küçük harf';
			case 'features.auth.hasNumber': return 'En az 1 rakam';
			case 'features.auth.hasSpecialChar': return 'En az 1 özel karakter';
			case 'features.auth.confirmPassword': return 'Şifre Tekrar';
			case 'features.auth.passwordsDoNotMatch': return 'Şifreler eşleşmiyor';
			case 'features.auth.emailAndPasswordRequired': return 'Email ve şifre boş bırakılamaz';
			case 'features.auth.hasAccount': return 'Zaten hesabınız var mı? Giriş yapın';
			case 'features.auth.joinApartment': return 'Apartmana Katıl';
			case 'features.auth.inviteCode': return 'Davet Kodu';
			case 'features.auth.inviteCodeHint': return 'AP3-B12-A9F0';
			case 'features.auth.invalidInviteCodeFormat': return 'Geçersiz davet kodu formatı (Örn: AP3-B12-A9F0)';
			case 'features.auth.invalidPhoneFormat': return 'Geçerli bir telefon numarası giriniz (5XX XXX XX XX)';
			case 'features.auth.inviteCodeAndPasswordRequired': return 'Davet kodu, ad ve şifre boş bırakılamaz';
			case 'features.auth.invalidPhoneNumber': return 'Geçerli bir telefon numarası giriniz';
			case 'features.auth.areYouManager': return 'Yönetici misiniz? Kaydolun';
			case 'features.apartments.residentPanel': return 'Sakin Paneli';
			case 'db_context.user_entry': return 'Kayıt: {value}';
			case 'db_context.building_name': return 'Bina: {value}';
			case 'db_context.apartment_label': return 'Daire: {value}';
			case 'db_context.code_value': return 'Kod: {value}';
			case 'db_context.expiry_date': return 'Son kullanma: {value}';
			default: return null;
		}
	}
}
