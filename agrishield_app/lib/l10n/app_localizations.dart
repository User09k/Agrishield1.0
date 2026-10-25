import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

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
    Locale('hi'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'AgriShield AI'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Smart Farming & AI Protection'**
  String get appTagline;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'हिंदी (Hindi)'**
  String get hindi;

  /// No description provided for @currentLanguage.
  ///
  /// In en, this message translates to:
  /// **'Current Language'**
  String get currentLanguage;

  /// No description provided for @languageChanged.
  ///
  /// In en, this message translates to:
  /// **'Language changed successfully'**
  String get languageChanged;

  /// No description provided for @scan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scan;

  /// No description provided for @weather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get weather;

  /// No description provided for @claims.
  ///
  /// In en, this message translates to:
  /// **'Claims'**
  String get claims;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @cropScan.
  ///
  /// In en, this message translates to:
  /// **'Crop Scan'**
  String get cropScan;

  /// No description provided for @marketRates.
  ///
  /// In en, this message translates to:
  /// **'Market Rates'**
  String get marketRates;

  /// No description provided for @soilAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Soil Analysis'**
  String get soilAnalysis;

  /// No description provided for @govtSchemes.
  ///
  /// In en, this message translates to:
  /// **'Govt Schemes'**
  String get govtSchemes;

  /// No description provided for @buyInsurance.
  ///
  /// In en, this message translates to:
  /// **'Buy Insurance'**
  String get buyInsurance;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @sprayAdvisor.
  ///
  /// In en, this message translates to:
  /// **'Spray Advisor'**
  String get sprayAdvisor;

  /// No description provided for @fertilizerPrescription.
  ///
  /// In en, this message translates to:
  /// **'Fertilizer Prescription'**
  String get fertilizerPrescription;

  /// No description provided for @recoveryAdvisor.
  ///
  /// In en, this message translates to:
  /// **'Recovery Advisor'**
  String get recoveryAdvisor;

  /// No description provided for @roiCalculator.
  ///
  /// In en, this message translates to:
  /// **'ROI Calculator'**
  String get roiCalculator;

  /// No description provided for @marketPredictor.
  ///
  /// In en, this message translates to:
  /// **'Market Predictor'**
  String get marketPredictor;

  /// No description provided for @claimReinvestment.
  ///
  /// In en, this message translates to:
  /// **'Claim Reinvestment'**
  String get claimReinvestment;

  /// No description provided for @agriBot.
  ///
  /// In en, this message translates to:
  /// **'AgriBot AI'**
  String get agriBot;

  /// No description provided for @aiFeatures.
  ///
  /// In en, this message translates to:
  /// **'AI Features'**
  String get aiFeatures;

  /// No description provided for @serverSettings.
  ///
  /// In en, this message translates to:
  /// **'Server Settings'**
  String get serverSettings;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saveCopy.
  ///
  /// In en, this message translates to:
  /// **'Save Copy'**
  String get saveCopy;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network connection error'**
  String get networkError;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @confirmLogout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get confirmLogout;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @shareOnWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Share on WhatsApp'**
  String get shareOnWhatsApp;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @loginToYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Login to your AgriShield account'**
  String get loginToYourAccount;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address'**
  String get enterEmail;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign Up'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get alreadyHaveAccount;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @registerForAgriShield.
  ///
  /// In en, this message translates to:
  /// **'Register as a smart farmer'**
  String get registerForAgriShield;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @enterFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get enterFullName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @enterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter your 10-digit mobile number'**
  String get enterPhoneNumber;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// No description provided for @resetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset link sent to your email'**
  String get resetLinkSent;

  /// No description provided for @scanYourCrop.
  ///
  /// In en, this message translates to:
  /// **'Scan Your Crop'**
  String get scanYourCrop;

  /// No description provided for @scanCropDesc.
  ///
  /// In en, this message translates to:
  /// **'Take a photo or upload crop image for instant disease diagnosis & recovery plan'**
  String get scanCropDesc;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @uploadGallery.
  ///
  /// In en, this message translates to:
  /// **'Upload from Gallery'**
  String get uploadGallery;

  /// No description provided for @analyzingCrop.
  ///
  /// In en, this message translates to:
  /// **'Analyzing crop with Vision AI...'**
  String get analyzingCrop;

  /// No description provided for @detectedDisease.
  ///
  /// In en, this message translates to:
  /// **'Detected Disease'**
  String get detectedDisease;

  /// No description provided for @healthyCrop.
  ///
  /// In en, this message translates to:
  /// **'Healthy Crop'**
  String get healthyCrop;

  /// No description provided for @healthyCropDesc.
  ///
  /// In en, this message translates to:
  /// **'No active diseases detected. Crop is in good condition.'**
  String get healthyCropDesc;

  /// No description provided for @confidence.
  ///
  /// In en, this message translates to:
  /// **'AI Confidence'**
  String get confidence;

  /// No description provided for @severity.
  ///
  /// In en, this message translates to:
  /// **'Severity Level'**
  String get severity;

  /// No description provided for @treatmentAdvice.
  ///
  /// In en, this message translates to:
  /// **'Treatment Advice'**
  String get treatmentAdvice;

  /// No description provided for @chemicalTreatment.
  ///
  /// In en, this message translates to:
  /// **'Chemical Treatment'**
  String get chemicalTreatment;

  /// No description provided for @organicTreatment.
  ///
  /// In en, this message translates to:
  /// **'Organic Treatment'**
  String get organicTreatment;

  /// No description provided for @preventiveMeasures.
  ///
  /// In en, this message translates to:
  /// **'Preventive Measures'**
  String get preventiveMeasures;

  /// No description provided for @fileInsuranceClaim.
  ///
  /// In en, this message translates to:
  /// **'File Insurance Claim'**
  String get fileInsuranceClaim;

  /// No description provided for @viewRecoveryPlan.
  ///
  /// In en, this message translates to:
  /// **'View Recovery Plan'**
  String get viewRecoveryPlan;

  /// No description provided for @liveWeather.
  ///
  /// In en, this message translates to:
  /// **'Live Field Weather'**
  String get liveWeather;

  /// No description provided for @temperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperature;

  /// No description provided for @humidity.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get humidity;

  /// No description provided for @rainfall.
  ///
  /// In en, this message translates to:
  /// **'Rainfall'**
  String get rainfall;

  /// No description provided for @windSpeed.
  ///
  /// In en, this message translates to:
  /// **'Wind Speed'**
  String get windSpeed;

  /// No description provided for @forecast.
  ///
  /// In en, this message translates to:
  /// **'Forecast'**
  String get forecast;

  /// No description provided for @weatherAlerts.
  ///
  /// In en, this message translates to:
  /// **'Weather Alerts'**
  String get weatherAlerts;

  /// No description provided for @cropImpact.
  ///
  /// In en, this message translates to:
  /// **'Crop Impact'**
  String get cropImpact;

  /// No description provided for @smartSprayAdvisorBanner.
  ///
  /// In en, this message translates to:
  /// **'Smart Spray Advisor'**
  String get smartSprayAdvisorBanner;

  /// No description provided for @safeSprayTimes.
  ///
  /// In en, this message translates to:
  /// **'Safe spraying windows & wind forecast'**
  String get safeSprayTimes;

  /// No description provided for @smartSprayAdvisor.
  ///
  /// In en, this message translates to:
  /// **'Smart Spray Advisor'**
  String get smartSprayAdvisor;

  /// No description provided for @sprayAdvisorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Optimal Spray Window & 48-Hour Forecast'**
  String get sprayAdvisorSubtitle;

  /// No description provided for @currentCondition.
  ///
  /// In en, this message translates to:
  /// **'Current Condition'**
  String get currentCondition;

  /// No description provided for @optimalForSpraying.
  ///
  /// In en, this message translates to:
  /// **'Optimal for Spraying'**
  String get optimalForSpraying;

  /// No description provided for @highRainRisk.
  ///
  /// In en, this message translates to:
  /// **'High Rain Risk — Do Not Spray'**
  String get highRainRisk;

  /// No description provided for @highWindDrift.
  ///
  /// In en, this message translates to:
  /// **'High Wind Drift — Avoid Spray'**
  String get highWindDrift;

  /// No description provided for @extremeHeat.
  ///
  /// In en, this message translates to:
  /// **'Extreme Heat — Avoid Spray'**
  String get extremeHeat;

  /// No description provided for @cautionSpray.
  ///
  /// In en, this message translates to:
  /// **'Spray with Caution'**
  String get cautionSpray;

  /// No description provided for @nextSafeWindow.
  ///
  /// In en, this message translates to:
  /// **'Next Safe Window'**
  String get nextSafeWindow;

  /// No description provided for @hourlySprayTimeline.
  ///
  /// In en, this message translates to:
  /// **'Hourly Spray Timeline (24 Hours)'**
  String get hourlySprayTimeline;

  /// No description provided for @goldenRulesForSpraying.
  ///
  /// In en, this message translates to:
  /// **'Golden Rules for Spraying'**
  String get goldenRulesForSpraying;

  /// No description provided for @calmConditions.
  ///
  /// In en, this message translates to:
  /// **'Calm wind, zero rain probability. 100% spray efficiency expected.'**
  String get calmConditions;

  /// No description provided for @fertilizerPrescriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Fertilizer Prescription'**
  String get fertilizerPrescriptionTitle;

  /// No description provided for @fertilizerPrescriptionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'ICAR Scientific Dosage & Bag Calculator'**
  String get fertilizerPrescriptionSubtitle;

  /// No description provided for @cropAndFieldSpecs.
  ///
  /// In en, this message translates to:
  /// **'Crop & Field Specifications'**
  String get cropAndFieldSpecs;

  /// No description provided for @selectCrop.
  ///
  /// In en, this message translates to:
  /// **'Select Crop:'**
  String get selectCrop;

  /// No description provided for @landArea.
  ///
  /// In en, this message translates to:
  /// **'Land Area:'**
  String get landArea;

  /// No description provided for @unit.
  ///
  /// In en, this message translates to:
  /// **'Unit:'**
  String get unit;

  /// No description provided for @cropAge.
  ///
  /// In en, this message translates to:
  /// **'Crop Age:'**
  String get cropAge;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get days;

  /// No description provided for @calculatePrescription.
  ///
  /// In en, this message translates to:
  /// **'Calculate Prescription'**
  String get calculatePrescription;

  /// No description provided for @totalSeasonFertilizer.
  ///
  /// In en, this message translates to:
  /// **'Total Season Fertilizer Requirement'**
  String get totalSeasonFertilizer;

  /// No description provided for @estimatedCost.
  ///
  /// In en, this message translates to:
  /// **'Estimated Subsidized Cost:'**
  String get estimatedCost;

  /// No description provided for @applyThisDosageNow.
  ///
  /// In en, this message translates to:
  /// **'Apply This Dosage Now (Current Stage):'**
  String get applyThisDosageNow;

  /// No description provided for @stepByStepSchedule.
  ///
  /// In en, this message translates to:
  /// **'Step-by-Step Fertilizer Schedule'**
  String get stepByStepSchedule;

  /// No description provided for @organicBoosterTip.
  ///
  /// In en, this message translates to:
  /// **'Organic Booster & Soil Health Tip:'**
  String get organicBoosterTip;

  /// No description provided for @urea.
  ///
  /// In en, this message translates to:
  /// **'Urea'**
  String get urea;

  /// No description provided for @dap.
  ///
  /// In en, this message translates to:
  /// **'DAP'**
  String get dap;

  /// No description provided for @mop.
  ///
  /// In en, this message translates to:
  /// **'MOP (Potash)'**
  String get mop;

  /// No description provided for @bags.
  ///
  /// In en, this message translates to:
  /// **'Bags'**
  String get bags;

  /// No description provided for @activeCropPolicies.
  ///
  /// In en, this message translates to:
  /// **'Active Crop Policies'**
  String get activeCropPolicies;

  /// No description provided for @fileNewClaim.
  ///
  /// In en, this message translates to:
  /// **'File New Claim'**
  String get fileNewClaim;

  /// No description provided for @claimStatus.
  ///
  /// In en, this message translates to:
  /// **'Claim Status'**
  String get claimStatus;

  /// No description provided for @policyNumber.
  ///
  /// In en, this message translates to:
  /// **'Policy Number'**
  String get policyNumber;

  /// No description provided for @sumInsured.
  ///
  /// In en, this message translates to:
  /// **'Sum Insured'**
  String get sumInsured;

  /// No description provided for @premium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premium;

  /// No description provided for @blockchainVerified.
  ///
  /// In en, this message translates to:
  /// **'Blockchain Verified'**
  String get blockchainVerified;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @payoutReceived.
  ///
  /// In en, this message translates to:
  /// **'Payout Received'**
  String get payoutReceived;

  /// No description provided for @soilHealthCard.
  ///
  /// In en, this message translates to:
  /// **'Soil Health Card'**
  String get soilHealthCard;

  /// No description provided for @nitrogen.
  ///
  /// In en, this message translates to:
  /// **'Nitrogen (N)'**
  String get nitrogen;

  /// No description provided for @phosphorus.
  ///
  /// In en, this message translates to:
  /// **'Phosphorus (P)'**
  String get phosphorus;

  /// No description provided for @potassium.
  ///
  /// In en, this message translates to:
  /// **'Potassium (K)'**
  String get potassium;

  /// No description provided for @phLevel.
  ///
  /// In en, this message translates to:
  /// **'pH Level'**
  String get phLevel;

  /// No description provided for @soilRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Soil Recommendations'**
  String get soilRecommendations;

  /// No description provided for @liveMandiRates.
  ///
  /// In en, this message translates to:
  /// **'Live Mandi Rates'**
  String get liveMandiRates;

  /// No description provided for @marketPriceForecast.
  ///
  /// In en, this message translates to:
  /// **'AI Price Forecast'**
  String get marketPriceForecast;

  /// No description provided for @modalPrice.
  ///
  /// In en, this message translates to:
  /// **'Modal Price'**
  String get modalPrice;

  /// No description provided for @priceTrend.
  ///
  /// In en, this message translates to:
  /// **'Price Trend'**
  String get priceTrend;

  /// No description provided for @pmKisan.
  ///
  /// In en, this message translates to:
  /// **'PM-Kisan Samman Nidhi'**
  String get pmKisan;

  /// No description provided for @pmFasalBima.
  ///
  /// In en, this message translates to:
  /// **'PM Fasal Bima Yojana'**
  String get pmFasalBima;

  /// No description provided for @checkEligibility.
  ///
  /// In en, this message translates to:
  /// **'Check Eligibility'**
  String get checkEligibility;

  /// No description provided for @agriBotAssistant.
  ///
  /// In en, this message translates to:
  /// **'AgriBot Voice & Chat Assistant'**
  String get agriBotAssistant;

  /// No description provided for @askAgriBotHint.
  ///
  /// In en, this message translates to:
  /// **'Ask your farming question...'**
  String get askAgriBotHint;

  /// No description provided for @listening.
  ///
  /// In en, this message translates to:
  /// **'Listening...'**
  String get listening;

  /// No description provided for @voiceInputError.
  ///
  /// In en, this message translates to:
  /// **'Microphone error'**
  String get voiceInputError;

  /// No description provided for @farmerProfile.
  ///
  /// In en, this message translates to:
  /// **'Farmer Profile'**
  String get farmerProfile;

  /// No description provided for @myFarmDetails.
  ///
  /// In en, this message translates to:
  /// **'My Farm Details'**
  String get myFarmDetails;

  /// No description provided for @villageDistrict.
  ///
  /// In en, this message translates to:
  /// **'Village / District'**
  String get villageDistrict;

  /// No description provided for @totalLandArea.
  ///
  /// In en, this message translates to:
  /// **'Total Land Area'**
  String get totalLandArea;

  /// No description provided for @callKisanHelpline.
  ///
  /// In en, this message translates to:
  /// **'Call Kisan Helpline'**
  String get callKisanHelpline;

  /// No description provided for @smsAlerts.
  ///
  /// In en, this message translates to:
  /// **'SMS Alerts'**
  String get smsAlerts;

  /// No description provided for @recentAlerts.
  ///
  /// In en, this message translates to:
  /// **'Recent Alerts'**
  String get recentAlerts;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get appLanguage;

  /// No description provided for @aboutAgriShield.
  ///
  /// In en, this message translates to:
  /// **'About AgriShield AI'**
  String get aboutAgriShield;

  /// No description provided for @sarkariRahat.
  ///
  /// In en, this message translates to:
  /// **'Sarkari Rahat'**
  String get sarkariRahat;

  /// No description provided for @govtReliefClaim.
  ///
  /// In en, this message translates to:
  /// **'Government Relief Claim'**
  String get govtReliefClaim;

  /// No description provided for @privateInsurance.
  ///
  /// In en, this message translates to:
  /// **'Private Insurance'**
  String get privateInsurance;

  /// No description provided for @autoApproveHighDamage.
  ///
  /// In en, this message translates to:
  /// **'Auto-approve at 70%+ damage'**
  String get autoApproveHighDamage;

  /// No description provided for @howItWorks.
  ///
  /// In en, this message translates to:
  /// **'How It Works'**
  String get howItWorks;

  /// No description provided for @scanCropAiCamera.
  ///
  /// In en, this message translates to:
  /// **'Scan crop with AI camera'**
  String get scanCropAiCamera;

  /// No description provided for @gpsLocationCaptured.
  ///
  /// In en, this message translates to:
  /// **'GPS location auto-captured'**
  String get gpsLocationCaptured;

  /// No description provided for @aiDetectsDisease.
  ///
  /// In en, this message translates to:
  /// **'AI detects disease & damage %'**
  String get aiDetectsDisease;

  /// No description provided for @reportUploadedBlockchain.
  ///
  /// In en, this message translates to:
  /// **'Report uploaded to Blockchain (IPFS)'**
  String get reportUploadedBlockchain;

  /// No description provided for @digitalSaboot.
  ///
  /// In en, this message translates to:
  /// **'Tamper-proof hash = Digital Saboot'**
  String get digitalSaboot;

  /// No description provided for @autoSubmitGovt.
  ///
  /// In en, this message translates to:
  /// **'Auto-submit to Govt / Smart Contract'**
  String get autoSubmitGovt;

  /// No description provided for @blockchainNotarization.
  ///
  /// In en, this message translates to:
  /// **'Blockchain Notarization'**
  String get blockchainNotarization;

  /// No description provided for @searchSchemes.
  ///
  /// In en, this message translates to:
  /// **'Search schemes...'**
  String get searchSchemes;

  /// No description provided for @noSchemesFound.
  ///
  /// In en, this message translates to:
  /// **'No schemes found'**
  String get noSchemesFound;

  /// No description provided for @loadingSchemes.
  ///
  /// In en, this message translates to:
  /// **'Loading schemes...'**
  String get loadingSchemes;

  /// No description provided for @searchCropOrMarket.
  ///
  /// In en, this message translates to:
  /// **'Search Crop or Market...'**
  String get searchCropOrMarket;

  /// No description provided for @noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noDataAvailable;

  /// No description provided for @loadingMarketRates.
  ///
  /// In en, this message translates to:
  /// **'Loading market rates...'**
  String get loadingMarketRates;

  /// No description provided for @cropImpactAssessment.
  ///
  /// In en, this message translates to:
  /// **'Crop Impact Assessment'**
  String get cropImpactAssessment;

  /// No description provided for @growth.
  ///
  /// In en, this message translates to:
  /// **'Growth'**
  String get growth;

  /// No description provided for @diseaseRisk.
  ///
  /// In en, this message translates to:
  /// **'Disease Risk'**
  String get diseaseRisk;

  /// No description provided for @irrigation.
  ///
  /// In en, this message translates to:
  /// **'Irrigation'**
  String get irrigation;

  /// No description provided for @smartAdvisory.
  ///
  /// In en, this message translates to:
  /// **'Smart Advisory'**
  String get smartAdvisory;

  /// No description provided for @solar.
  ///
  /// In en, this message translates to:
  /// **'Solar'**
  String get solar;

  /// No description provided for @temp.
  ///
  /// In en, this message translates to:
  /// **'Temp'**
  String get temp;

  /// No description provided for @wind.
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get wind;

  /// No description provided for @rainRisk.
  ///
  /// In en, this message translates to:
  /// **'Rain Risk'**
  String get rainRisk;

  /// No description provided for @optimalWindow.
  ///
  /// In en, this message translates to:
  /// **'Optimal Window'**
  String get optimalWindow;

  /// No description provided for @cropDisease.
  ///
  /// In en, this message translates to:
  /// **'Crop Disease'**
  String get cropDisease;

  /// No description provided for @marketPrice.
  ///
  /// In en, this message translates to:
  /// **'Market Price'**
  String get marketPrice;

  /// No description provided for @weatherTips.
  ///
  /// In en, this message translates to:
  /// **'Weather Tips'**
  String get weatherTips;

  /// No description provided for @fertilizerGuide.
  ///
  /// In en, this message translates to:
  /// **'Fertilizer Guide'**
  String get fertilizerGuide;

  /// No description provided for @pestControl.
  ///
  /// In en, this message translates to:
  /// **'Pest Control'**
  String get pestControl;

  /// No description provided for @calculatingDosage.
  ///
  /// In en, this message translates to:
  /// **'Calculating Dosage...'**
  String get calculatingDosage;

  /// No description provided for @connectingSatellite.
  ///
  /// In en, this message translates to:
  /// **'Connecting to NASA Satellite...'**
  String get connectingSatellite;

  /// No description provided for @weatherUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Weather data unavailable'**
  String get weatherUnavailable;

  /// No description provided for @analyzingWeatherConditions.
  ///
  /// In en, this message translates to:
  /// **'Analyzing wind, rain & weather conditions...'**
  String get analyzingWeatherConditions;

  /// No description provided for @unableToFetchWeather.
  ///
  /// In en, this message translates to:
  /// **'Unable to fetch weather forecast. Please check your connection and try again.'**
  String get unableToFetchWeather;

  /// No description provided for @aiAnalyzingRecovery.
  ///
  /// In en, this message translates to:
  /// **'AI analyzing recovery options...'**
  String get aiAnalyzingRecovery;

  /// No description provided for @cropHealthGood.
  ///
  /// In en, this message translates to:
  /// **'Your crop health is good!'**
  String get cropHealthGood;

  /// No description provided for @overviewStats.
  ///
  /// In en, this message translates to:
  /// **'Overview Stats'**
  String get overviewStats;

  /// No description provided for @lastScanSummary.
  ///
  /// In en, this message translates to:
  /// **'Last Scan Summary'**
  String get lastScanSummary;

  /// No description provided for @alertTimeline.
  ///
  /// In en, this message translates to:
  /// **'Alert Timeline'**
  String get alertTimeline;

  /// No description provided for @cropScanHistory.
  ///
  /// In en, this message translates to:
  /// **'Crop Scan History'**
  String get cropScanHistory;

  /// No description provided for @soilHistory.
  ///
  /// In en, this message translates to:
  /// **'Soil History'**
  String get soilHistory;

  /// No description provided for @weatherDataCouldNotBeLoaded.
  ///
  /// In en, this message translates to:
  /// **'Weather data could not be loaded'**
  String get weatherDataCouldNotBeLoaded;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @profileUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdatedSuccess;

  /// No description provided for @farmerLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get farmerLocationLabel;

  /// No description provided for @farmSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Farm Size'**
  String get farmSizeLabel;

  /// No description provided for @enterFarmSize.
  ///
  /// In en, this message translates to:
  /// **'e.g. 5 Acre'**
  String get enterFarmSize;

  /// No description provided for @enterLocation.
  ///
  /// In en, this message translates to:
  /// **'e.g. Indore, Madhya Pradesh'**
  String get enterLocation;

  /// No description provided for @aiAssistantHeading.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get aiAssistantHeading;

  /// No description provided for @callAiAssistant.
  ///
  /// In en, this message translates to:
  /// **'Call AI Assistant'**
  String get callAiAssistant;

  /// No description provided for @callAiSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Call our AI for instant farming advice'**
  String get callAiSubtitle;

  /// No description provided for @chatWithAgriBot.
  ///
  /// In en, this message translates to:
  /// **'Chat with AgriBot'**
  String get chatWithAgriBot;

  /// No description provided for @totalAlerts.
  ///
  /// In en, this message translates to:
  /// **'Total Alerts'**
  String get totalAlerts;

  /// No description provided for @criticalAlerts.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get criticalAlerts;

  /// No description provided for @noAlertsAtMoment.
  ///
  /// In en, this message translates to:
  /// **'No alerts at the moment'**
  String get noAlertsAtMoment;

  /// No description provided for @sendTestAlert.
  ///
  /// In en, this message translates to:
  /// **'Send Test Alert'**
  String get sendTestAlert;

  /// No description provided for @viewReports.
  ///
  /// In en, this message translates to:
  /// **'View Reports'**
  String get viewReports;

  /// No description provided for @soilAnalysisTitle.
  ///
  /// In en, this message translates to:
  /// **'Soil Analysis'**
  String get soilAnalysisTitle;

  /// No description provided for @soilAnalysisSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scan soil & get plant/crop recommendations'**
  String get soilAnalysisSubtitle;

  /// No description provided for @appLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get appLanguageLabel;

  /// No description provided for @currentLangTapToChange.
  ///
  /// In en, this message translates to:
  /// **'Current: English 🇬🇧 (Tap to change)'**
  String get currentLangTapToChange;

  /// No description provided for @sendingAlert.
  ///
  /// In en, this message translates to:
  /// **'Sending test alert...'**
  String get sendingAlert;

  /// No description provided for @testAlertSent.
  ///
  /// In en, this message translates to:
  /// **'Test alert sent successfully!'**
  String get testAlertSent;

  /// No description provided for @logoutConfirmationMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out of your account?'**
  String get logoutConfirmationMessage;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @phoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get phoneRequired;

  /// No description provided for @farmSize.
  ///
  /// In en, this message translates to:
  /// **'Farm'**
  String get farmSize;

  /// No description provided for @pmKisanId.
  ///
  /// In en, this message translates to:
  /// **'PM-KISAN ID'**
  String get pmKisanId;
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
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
