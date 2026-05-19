import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr')
  ];

  /// The application title
  ///
  /// In en, this message translates to:
  /// **'YuzToo'**
  String get appTitle;

  /// No description provided for @welcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcomeMessage;

  /// No description provided for @forThemForYou.
  ///
  /// In en, this message translates to:
  /// **'FOR THEM, FOR YOU'**
  String get forThemForYou;

  /// No description provided for @allTheShops.
  ///
  /// In en, this message translates to:
  /// **'All the shops'**
  String get allTheShops;

  /// No description provided for @youreUsedTo.
  ///
  /// In en, this message translates to:
  /// **'\"You\'re used\" to'**
  String get youreUsedTo;

  /// No description provided for @welcomeQuestion.
  ///
  /// In en, this message translates to:
  /// **'Welcome, Who are you?'**
  String get welcomeQuestion;

  /// No description provided for @client.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get client;

  /// No description provided for @merchant.
  ///
  /// In en, this message translates to:
  /// **'Merchant'**
  String get merchant;

  /// No description provided for @discoverShops.
  ///
  /// In en, this message translates to:
  /// **'Discover shops'**
  String get discoverShops;

  /// No description provided for @manageBusiness.
  ///
  /// In en, this message translates to:
  /// **'Manage your business'**
  String get manageBusiness;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @signup.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signup;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Have an account?'**
  String get haveAccount;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @selectCity.
  ///
  /// In en, this message translates to:
  /// **'Select your city'**
  String get selectCity;

  /// No description provided for @searchCity.
  ///
  /// In en, this message translates to:
  /// **'Search for a city...'**
  String get searchCity;

  /// No description provided for @verification.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get verification;

  /// No description provided for @enterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the code sent to'**
  String get enterCode;

  /// No description provided for @incorrectNumber.
  ///
  /// In en, this message translates to:
  /// **'Incorrect number?'**
  String get incorrectNumber;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @discovery.
  ///
  /// In en, this message translates to:
  /// **'Discovery'**
  String get discovery;

  /// No description provided for @loyalty.
  ///
  /// In en, this message translates to:
  /// **'Loyalty'**
  String get loyalty;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @clients.
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get clients;

  /// No description provided for @stats.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get stats;

  /// No description provided for @promotions.
  ///
  /// In en, this message translates to:
  /// **'Promotions'**
  String get promotions;

  /// QR code navigation label
  ///
  /// In en, this message translates to:
  /// **'QR Code'**
  String get qrCode;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// No description provided for @continueWith.
  ///
  /// In en, this message translates to:
  /// **'Continue with'**
  String get continueWith;

  /// No description provided for @google.
  ///
  /// In en, this message translates to:
  /// **'Google'**
  String get google;

  /// No description provided for @facebook.
  ///
  /// In en, this message translates to:
  /// **'Facebook'**
  String get facebook;

  /// No description provided for @apple.
  ///
  /// In en, this message translates to:
  /// **'Apple'**
  String get apple;

  /// No description provided for @termsAcceptance.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you accept our terms of use'**
  String get termsAcceptance;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid credentials. Check your email and password.'**
  String get invalidCredentials;

  /// No description provided for @accountDisabled.
  ///
  /// In en, this message translates to:
  /// **'Account disabled.'**
  String get accountDisabled;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network connection error. Check your internet connection.'**
  String get networkError;

  /// No description provided for @operationCancelled.
  ///
  /// In en, this message translates to:
  /// **'Operation cancelled by user.'**
  String get operationCancelled;

  /// No description provided for @incompleteProfile.
  ///
  /// In en, this message translates to:
  /// **'Incomplete profile'**
  String get incompleteProfile;

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred'**
  String get unexpectedError;

  /// No description provided for @loginToDiscover.
  ///
  /// In en, this message translates to:
  /// **'Login to discover shops'**
  String get loginToDiscover;

  /// No description provided for @accessProfessionalSpace.
  ///
  /// In en, this message translates to:
  /// **'Access your professional space'**
  String get accessProfessionalSpace;

  /// No description provided for @connection.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get connection;

  /// No description provided for @chooseRole.
  ///
  /// In en, this message translates to:
  /// **'Choose your role'**
  String get chooseRole;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @subcategory.
  ///
  /// In en, this message translates to:
  /// **'Subcategory'**
  String get subcategory;

  /// No description provided for @benefits.
  ///
  /// In en, this message translates to:
  /// **'Benefits'**
  String get benefits;

  /// No description provided for @startFree.
  ///
  /// In en, this message translates to:
  /// **'Start for free'**
  String get startFree;

  /// No description provided for @restaurant.
  ///
  /// In en, this message translates to:
  /// **'Restaurant'**
  String get restaurant;

  /// No description provided for @retail.
  ///
  /// In en, this message translates to:
  /// **'Retail'**
  String get retail;

  /// No description provided for @beauty.
  ///
  /// In en, this message translates to:
  /// **'Beauty & Wellness'**
  String get beauty;

  /// No description provided for @fitness.
  ///
  /// In en, this message translates to:
  /// **'Sport & Fitness'**
  String get fitness;

  /// No description provided for @services.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get services;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @reserve.
  ///
  /// In en, this message translates to:
  /// **'Reserve'**
  String get reserve;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'reviews'**
  String get reviews;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @restaurants.
  ///
  /// In en, this message translates to:
  /// **'Restaurants'**
  String get restaurants;

  /// No description provided for @cafes.
  ///
  /// In en, this message translates to:
  /// **'Cafes'**
  String get cafes;

  /// No description provided for @health.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get health;

  /// No description provided for @beautyCategory.
  ///
  /// In en, this message translates to:
  /// **'Beauty'**
  String get beautyCategory;

  /// No description provided for @shopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get shopping;

  /// No description provided for @currentPoints.
  ///
  /// In en, this message translates to:
  /// **'Current points'**
  String get currentPoints;

  /// No description provided for @nextReward.
  ///
  /// In en, this message translates to:
  /// **'Next reward'**
  String get nextReward;

  /// No description provided for @totalVisits.
  ///
  /// In en, this message translates to:
  /// **'Total visits'**
  String get totalVisits;

  /// No description provided for @freeCoffee.
  ///
  /// In en, this message translates to:
  /// **'Free coffee'**
  String get freeCoffee;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @freePastry.
  ///
  /// In en, this message translates to:
  /// **'Free pastry'**
  String get freePastry;

  /// No description provided for @scanQRCode.
  ///
  /// In en, this message translates to:
  /// **'Scan the'**
  String get scanQRCode;

  /// No description provided for @addToYuzToo.
  ///
  /// In en, this message translates to:
  /// **'Add it to your YuzToo notebook\nand receive useful information'**
  String get addToYuzToo;

  /// No description provided for @scanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning...'**
  String get scanning;

  /// No description provided for @startScan.
  ///
  /// In en, this message translates to:
  /// **'Start scan'**
  String get startScan;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email address is required.'**
  String get emailRequired;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address.'**
  String get invalidEmail;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get emailAddress;

  /// No description provided for @forgotPasswordQuestion.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPasswordQuestion;

  /// No description provided for @connectToShops.
  ///
  /// In en, this message translates to:
  /// **'Connect to your shops'**
  String get connectToShops;

  /// No description provided for @yuztooForYou.
  ///
  /// In en, this message translates to:
  /// **'YuzToo, concretely for you'**
  String get yuztooForYou;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'8+ characters, uppercase, lowercase and numbers'**
  String get passwordHint;

  /// No description provided for @socialLoginSoon.
  ///
  /// In en, this message translates to:
  /// **'{provider} login coming soon'**
  String socialLoginSoon(String provider);

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select a category'**
  String get selectCategory;

  /// No description provided for @categorySelected.
  ///
  /// In en, this message translates to:
  /// **'Category selected: {category}'**
  String categorySelected(String category);

  /// No description provided for @foodBusiness.
  ///
  /// In en, this message translates to:
  /// **'Food business and more...'**
  String get foodBusiness;

  /// No description provided for @activeClients.
  ///
  /// In en, this message translates to:
  /// **'Active clients'**
  String get activeClients;

  /// No description provided for @visits.
  ///
  /// In en, this message translates to:
  /// **'Visits'**
  String get visits;

  /// No description provided for @revenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get revenue;

  /// No description provided for @newClients.
  ///
  /// In en, this message translates to:
  /// **'New clients'**
  String get newClients;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @week.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get week;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @dontHaveAccountText.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get dontHaveAccountText;

  /// No description provided for @createAccountText.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccountText;

  /// No description provided for @emailPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'your@email.com'**
  String get emailPlaceholder;

  /// No description provided for @passwordPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'••••••••'**
  String get passwordPlaceholder;

  /// No description provided for @phoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required.'**
  String get phoneRequired;

  /// No description provided for @invalidPhoneFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number. Check the format.'**
  String get invalidPhoneFormat;

  /// No description provided for @cityRequired.
  ///
  /// In en, this message translates to:
  /// **'City is required.'**
  String get cityRequired;

  /// No description provided for @verificationCodeSent.
  ///
  /// In en, this message translates to:
  /// **'Verification code sent!'**
  String get verificationCodeSent;

  /// No description provided for @smsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'SMS unavailable at the moment. Please contact support.'**
  String get smsUnavailable;

  /// No description provided for @verificationIdMissing.
  ///
  /// In en, this message translates to:
  /// **'Error: Verification ID missing'**
  String get verificationIdMissing;

  /// No description provided for @signupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Signup successful!'**
  String get signupSuccess;

  /// No description provided for @verificationCodeResent.
  ///
  /// In en, this message translates to:
  /// **'Verification code resent!'**
  String get verificationCodeResent;

  /// No description provided for @enterCodeSentTo.
  ///
  /// In en, this message translates to:
  /// **'Enter the code sent to\n'**
  String get enterCodeSentTo;

  /// No description provided for @wrongNumber.
  ///
  /// In en, this message translates to:
  /// **'Wrong number?'**
  String get wrongNumber;

  /// No description provided for @resendCodeWithTimer.
  ///
  /// In en, this message translates to:
  /// **'Resend code ({seconds}s)'**
  String resendCodeWithTimer(int seconds);

  /// No description provided for @forThemForYouLowercase.
  ///
  /// In en, this message translates to:
  /// **'for them, for you'**
  String get forThemForYouLowercase;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello,'**
  String get hello;

  /// No description provided for @searchStore.
  ///
  /// In en, this message translates to:
  /// **'Search for a store...'**
  String get searchStore;

  /// No description provided for @scan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scan;

  /// No description provided for @loyaltyLabel.
  ///
  /// In en, this message translates to:
  /// **'Loyalty'**
  String get loyaltyLabel;

  /// No description provided for @offers.
  ///
  /// In en, this message translates to:
  /// **'Offers'**
  String get offers;

  /// No description provided for @activePromotions.
  ///
  /// In en, this message translates to:
  /// **'Active promotions'**
  String get activePromotions;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @myBusiness.
  ///
  /// In en, this message translates to:
  /// **'My business'**
  String get myBusiness;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get quickActions;

  /// No description provided for @myQRCode.
  ///
  /// In en, this message translates to:
  /// **'My QR Code'**
  String get myQRCode;

  /// No description provided for @showCode.
  ///
  /// In en, this message translates to:
  /// **'Show code'**
  String get showCode;

  /// No description provided for @manageOffers.
  ///
  /// In en, this message translates to:
  /// **'Manage offers'**
  String get manageOffers;

  /// No description provided for @reservations.
  ///
  /// In en, this message translates to:
  /// **'Reservations'**
  String get reservations;

  /// No description provided for @scanQR.
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get scanQR;

  /// No description provided for @rewardUsed.
  ///
  /// In en, this message translates to:
  /// **'Reward used'**
  String get rewardUsed;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min ago'**
  String minutesAgo(int minutes);

  /// No description provided for @visitsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Visits this month'**
  String get visitsThisMonth;

  /// No description provided for @pointsDistributed.
  ///
  /// In en, this message translates to:
  /// **'Points distributed'**
  String get pointsDistributed;

  /// No description provided for @myLoyaltyCards.
  ///
  /// In en, this message translates to:
  /// **'My loyalty cards'**
  String get myLoyaltyCards;

  /// No description provided for @totalPoints.
  ///
  /// In en, this message translates to:
  /// **'Total points'**
  String get totalPoints;

  /// No description provided for @stores.
  ///
  /// In en, this message translates to:
  /// **'Stores'**
  String get stores;

  /// No description provided for @rewards.
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get rewards;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get myProfile;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT'**
  String get account;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal information'**
  String get personalInfo;

  /// No description provided for @paymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Payment methods'**
  String get paymentMethods;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'PREFERENCES'**
  String get preferences;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get pushNotifications;

  /// No description provided for @emailNotifications.
  ///
  /// In en, this message translates to:
  /// **'Email notifications'**
  String get emailNotifications;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'SUPPORT'**
  String get support;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String version(String version);

  /// No description provided for @searchConversation.
  ///
  /// In en, this message translates to:
  /// **'Search for a conversation...'**
  String get searchConversation;

  /// No description provided for @newPromotion.
  ///
  /// In en, this message translates to:
  /// **'New promotion!'**
  String get newPromotion;

  /// No description provided for @pointsEarned.
  ///
  /// In en, this message translates to:
  /// **'Points earned'**
  String get pointsEarned;

  /// No description provided for @pointsEarnedMessage.
  ///
  /// In en, this message translates to:
  /// **'You earned {points} points at {store}'**
  String pointsEarnedMessage(int points, String store);

  /// No description provided for @newMessage.
  ///
  /// In en, this message translates to:
  /// **'New message'**
  String get newMessage;

  /// No description provided for @messageFrom.
  ///
  /// In en, this message translates to:
  /// **'{store} sent you a message'**
  String messageFrom(String store);

  /// No description provided for @reservationReminder.
  ///
  /// In en, this message translates to:
  /// **'Reservation reminder'**
  String get reservationReminder;

  /// No description provided for @reservationForTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Your reservation for tomorrow at {time}'**
  String reservationForTomorrow(String time);

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllRead;

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String hoursAgo(int hours);

  /// No description provided for @healthCategory.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get healthCategory;

  /// No description provided for @beautyCategoryLowercase.
  ///
  /// In en, this message translates to:
  /// **'Beauty'**
  String get beautyCategoryLowercase;

  /// No description provided for @bakery.
  ///
  /// In en, this message translates to:
  /// **'Bakery'**
  String get bakery;

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help center'**
  String get helpCenter;

  /// No description provided for @termsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get termsOfUse;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @browseWithoutAccount.
  ///
  /// In en, this message translates to:
  /// **'Browse businesses without an account →'**
  String get browseWithoutAccount;

  /// No description provided for @createProAccount.
  ///
  /// In en, this message translates to:
  /// **'Create a pro account'**
  String get createProAccount;

  /// No description provided for @newClientsTitle.
  ///
  /// In en, this message translates to:
  /// **'New clients'**
  String get newClientsTitle;

  /// No description provided for @acknowledgeClient.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get acknowledgeClient;

  /// No description provided for @noNewClients.
  ///
  /// In en, this message translates to:
  /// **'No new clients'**
  String get noNewClients;

  /// No description provided for @servicesYuzToo.
  ///
  /// In en, this message translates to:
  /// **'YUZTOO SERVICES'**
  String get servicesYuzToo;

  /// No description provided for @pendingClientsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} pending'**
  String pendingClientsCount(int count);

  /// No description provided for @navAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get navAlerts;

  /// No description provided for @navStorefront.
  ///
  /// In en, this message translates to:
  /// **'Storefront'**
  String get navStorefront;

  /// No description provided for @navYourClients.
  ///
  /// In en, this message translates to:
  /// **'Your clients'**
  String get navYourClients;

  /// No description provided for @navNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get navNotifications;

  /// No description provided for @navRappels.
  ///
  /// In en, this message translates to:
  /// **'Rappels'**
  String get navRappels;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
