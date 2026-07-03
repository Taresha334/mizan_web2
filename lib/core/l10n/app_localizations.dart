import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_am.dart';
import 'app_localizations_en.dart';
import 'app_localizations_om.dart';
import 'app_localizations_so.dart';
import 'app_localizations_ti.dart';

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
    Locale('am'),
    Locale('en'),
    Locale('om'),
    Locale('so'),
    Locale('ti'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'MIZAN MARKET'**
  String get appTitle;

  /// No description provided for @portalTitle.
  ///
  /// In en, this message translates to:
  /// **'MIZAN PORTAL'**
  String get portalTitle;

  /// No description provided for @officialPlatform.
  ///
  /// In en, this message translates to:
  /// **'OFFICIAL PLATFORM'**
  String get officialPlatform;

  /// No description provided for @welcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Precision Nutrition for Peak Livestock Performance'**
  String get welcomeMessage;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search Mizan Market for products & services...'**
  String get searchHint;

  /// No description provided for @digitalBridgeStatement.
  ///
  /// In en, this message translates to:
  /// **'Connecting farmers and agents across Ethiopia.'**
  String get digitalBridgeStatement;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Mizan Support'**
  String get contactSupport;

  /// No description provided for @primarySupport.
  ///
  /// In en, this message translates to:
  /// **'Primary Support'**
  String get primarySupport;

  /// No description provided for @secondarySupport.
  ///
  /// In en, this message translates to:
  /// **'Secondary Support'**
  String get secondarySupport;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get navProducts;

  /// No description provided for @navNutrition.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get navNutrition;

  /// No description provided for @navEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get navEducation;

  /// No description provided for @navAbout.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get navAbout;

  /// No description provided for @navContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get navContact;

  /// No description provided for @navAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin Portal'**
  String get navAdmin;

  /// No description provided for @heroTitle.
  ///
  /// In en, this message translates to:
  /// **'Precision Nutrition for Livestock'**
  String get heroTitle;

  /// No description provided for @heroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'10 years of scientific excellence in Ethiopian agriculture.'**
  String get heroSubtitle;

  /// No description provided for @heroTitleFeed.
  ///
  /// In en, this message translates to:
  /// **'PREMIUM ANIMAL FEED'**
  String get heroTitleFeed;

  /// No description provided for @heroSubtitleFeed.
  ///
  /// In en, this message translates to:
  /// **'High-quality nutrition: The heart of Mizan\'s priority products.'**
  String get heroSubtitleFeed;

  /// No description provided for @heroSubtitleMarket.
  ///
  /// In en, this message translates to:
  /// **'The Digital Bridge connecting Farmers and End Users.'**
  String get heroSubtitleMarket;

  /// No description provided for @heroSubtitleAI.
  ///
  /// In en, this message translates to:
  /// **'Get instant expert solutions for all your livestock health and management needs from Mizan Experts.'**
  String get heroSubtitleAI;

  /// No description provided for @mizanAnimalFeedPicks.
  ///
  /// In en, this message translates to:
  /// **'Mizan Animal Feed'**
  String get mizanAnimalFeedPicks;

  /// No description provided for @mizanProduct.
  ///
  /// In en, this message translates to:
  /// **'Mizan Feed Product'**
  String get mizanProduct;

  /// No description provided for @shopFeed.
  ///
  /// In en, this message translates to:
  /// **'SHOP FEED'**
  String get shopFeed;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @askExpert.
  ///
  /// In en, this message translates to:
  /// **'Ask an Expert'**
  String get askExpert;

  /// No description provided for @legal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get legal;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get termsOfUse;

  /// No description provided for @followUs.
  ///
  /// In en, this message translates to:
  /// **'Follow Us'**
  String get followUs;

  /// No description provided for @backToWeb.
  ///
  /// In en, this message translates to:
  /// **'Back to Mizan Website'**
  String get backToWeb;

  /// No description provided for @catAnimalFeed.
  ///
  /// In en, this message translates to:
  /// **'Animal Feed'**
  String get catAnimalFeed;

  /// No description provided for @catPoultry.
  ///
  /// In en, this message translates to:
  /// **'Poultry'**
  String get catPoultry;

  /// No description provided for @catBroiler.
  ///
  /// In en, this message translates to:
  /// **'Broiler'**
  String get catBroiler;

  /// No description provided for @catSaso.
  ///
  /// In en, this message translates to:
  /// **'Saso'**
  String get catSaso;

  /// No description provided for @catDairy.
  ///
  /// In en, this message translates to:
  /// **'Dairy'**
  String get catDairy;

  /// No description provided for @catFattening.
  ///
  /// In en, this message translates to:
  /// **'Fattening'**
  String get catFattening;

  /// No description provided for @catSpecialty.
  ///
  /// In en, this message translates to:
  /// **'Specialty'**
  String get catSpecialty;

  /// No description provided for @catCattle.
  ///
  /// In en, this message translates to:
  /// **'Cattle'**
  String get catCattle;

  /// No description provided for @catSheep.
  ///
  /// In en, this message translates to:
  /// **'Sheep'**
  String get catSheep;

  /// No description provided for @catGoat.
  ///
  /// In en, this message translates to:
  /// **'Goat'**
  String get catGoat;

  /// No description provided for @catLivestock.
  ///
  /// In en, this message translates to:
  /// **'Livestock'**
  String get catLivestock;

  /// No description provided for @catFarmTools.
  ///
  /// In en, this message translates to:
  /// **'Farm Tools'**
  String get catFarmTools;

  /// No description provided for @catAgriProducts.
  ///
  /// In en, this message translates to:
  /// **'Agri-products'**
  String get catAgriProducts;

  /// No description provided for @catVeterinary.
  ///
  /// In en, this message translates to:
  /// **'Veterinary'**
  String get catVeterinary;

  /// No description provided for @catAgriLabor.
  ///
  /// In en, this message translates to:
  /// **'Agri-Labor'**
  String get catAgriLabor;

  /// No description provided for @catSeedsCrops.
  ///
  /// In en, this message translates to:
  /// **'Seeds/Crops'**
  String get catSeedsCrops;

  /// No description provided for @catOthers.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get catOthers;

  /// No description provided for @exploreMarket.
  ///
  /// In en, this message translates to:
  /// **'Explore Mizan Market'**
  String get exploreMarket;

  /// No description provided for @exploreMizanMarket.
  ///
  /// In en, this message translates to:
  /// **'Explore Mizan Market'**
  String get exploreMizanMarket;

  /// No description provided for @marketplace.
  ///
  /// In en, this message translates to:
  /// **'Marketplace'**
  String get marketplace;

  /// No description provided for @agentPortal.
  ///
  /// In en, this message translates to:
  /// **'Agent Portal'**
  String get agentPortal;

  /// No description provided for @education.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get education;

  /// No description provided for @aiExpert.
  ///
  /// In en, this message translates to:
  /// **'AI Expert'**
  String get aiExpert;

  /// No description provided for @aiExpertAdvisor.
  ///
  /// In en, this message translates to:
  /// **'AI Expert Advisor'**
  String get aiExpertAdvisor;

  /// No description provided for @aiBroadStatement.
  ///
  /// In en, this message translates to:
  /// **'Instant Smart Solutions for All Your Farming Needs'**
  String get aiBroadStatement;

  /// No description provided for @askMizanExperts.
  ///
  /// In en, this message translates to:
  /// **'Ask Mizan Experts'**
  String get askMizanExperts;

  /// No description provided for @marketOpen.
  ///
  /// In en, this message translates to:
  /// **'Market Open'**
  String get marketOpen;

  /// No description provided for @findAgents.
  ///
  /// In en, this message translates to:
  /// **'Find Agents'**
  String get findAgents;

  /// No description provided for @findVetNearby.
  ///
  /// In en, this message translates to:
  /// **'Find Veterinary Doctors nearby'**
  String get findVetNearby;

  /// No description provided for @sellPost.
  ///
  /// In en, this message translates to:
  /// **'Sell/Post'**
  String get sellPost;

  /// No description provided for @sellYourProducts.
  ///
  /// In en, this message translates to:
  /// **'Sell your products here'**
  String get sellYourProducts;

  /// No description provided for @sellOnMizan.
  ///
  /// In en, this message translates to:
  /// **'Sell on Mizan'**
  String get sellOnMizan;

  /// No description provided for @oneTimeSale.
  ///
  /// In en, this message translates to:
  /// **'One-Time Sale'**
  String get oneTimeSale;

  /// No description provided for @oneTimeSaleSub.
  ///
  /// In en, this message translates to:
  /// **'No account needed. Direct post for a fee.'**
  String get oneTimeSaleSub;

  /// No description provided for @beAgent.
  ///
  /// In en, this message translates to:
  /// **'I want to be an Agent'**
  String get beAgent;

  /// No description provided for @beAgentSub.
  ///
  /// In en, this message translates to:
  /// **'Monthly subscription (500 ETB). Get lower rates.'**
  String get beAgentSub;

  /// No description provided for @agentApplication.
  ///
  /// In en, this message translates to:
  /// **'Agent Registration'**
  String get agentApplication;

  /// No description provided for @expertise.
  ///
  /// In en, this message translates to:
  /// **'Your Expertise'**
  String get expertise;

  /// No description provided for @expertiseSelection.
  ///
  /// In en, this message translates to:
  /// **'Select Your Expertise:'**
  String get expertiseSelection;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @submitForApproval.
  ///
  /// In en, this message translates to:
  /// **'Submit for Approval'**
  String get submitForApproval;

  /// No description provided for @applicationSent.
  ///
  /// In en, this message translates to:
  /// **'Request Sent! Mizan Admin will review your payment. Once approved, you will receive your login credentials via SMS.'**
  String get applicationSent;

  /// No description provided for @flockSize.
  ///
  /// In en, this message translates to:
  /// **'Flock Size'**
  String get flockSize;

  /// No description provided for @calculate.
  ///
  /// In en, this message translates to:
  /// **'Calculate'**
  String get calculate;

  /// No description provided for @productTitle.
  ///
  /// In en, this message translates to:
  /// **'Product Title'**
  String get productTitle;

  /// No description provided for @fullDescription.
  ///
  /// In en, this message translates to:
  /// **'Full Description'**
  String get fullDescription;

  /// No description provided for @productCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get productCategory;

  /// No description provided for @productContent.
  ///
  /// In en, this message translates to:
  /// **'Product Content'**
  String get productContent;

  /// No description provided for @productPrice.
  ///
  /// In en, this message translates to:
  /// **'Current Price'**
  String get productPrice;

  /// No description provided for @priceOnRequest.
  ///
  /// In en, this message translates to:
  /// **'Price on Request'**
  String get priceOnRequest;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @outOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of Stock'**
  String get outOfStock;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity (Quintals)'**
  String get quantity;

  /// No description provided for @totalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get totalAmount;

  /// No description provided for @orderTitle.
  ///
  /// In en, this message translates to:
  /// **'Place an Order'**
  String get orderTitle;

  /// No description provided for @submitOrder.
  ///
  /// In en, this message translates to:
  /// **'Submit Order'**
  String get submitOrder;

  /// No description provided for @customerName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get customerName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @paymentHeader.
  ///
  /// In en, this message translates to:
  /// **'Payment Instructions'**
  String get paymentHeader;

  /// No description provided for @paymentInstruction.
  ///
  /// In en, this message translates to:
  /// **'Please deposit the total amount to one of the accounts below and upload the transaction screenshot.'**
  String get paymentInstruction;

  /// No description provided for @uploadReceipt.
  ///
  /// In en, this message translates to:
  /// **'Upload Payment Receipt'**
  String get uploadReceipt;

  /// No description provided for @transactionId.
  ///
  /// In en, this message translates to:
  /// **'Transaction ID / Reference Number'**
  String get transactionId;

  /// No description provided for @paymentRefLabel.
  ///
  /// In en, this message translates to:
  /// **'Transaction ID (500 ETB)'**
  String get paymentRefLabel;

  /// No description provided for @confirmPayment.
  ///
  /// In en, this message translates to:
  /// **'I have made the payment'**
  String get confirmPayment;

  /// No description provided for @verifyPayment.
  ///
  /// In en, this message translates to:
  /// **'Verify Payment'**
  String get verifyPayment;

  /// No description provided for @commentHeader.
  ///
  /// In en, this message translates to:
  /// **'Customer Feedback'**
  String get commentHeader;

  /// No description provided for @writeComment.
  ///
  /// In en, this message translates to:
  /// **'Write a comment...'**
  String get writeComment;

  /// No description provided for @submitComment.
  ///
  /// In en, this message translates to:
  /// **'Post Comment'**
  String get submitComment;

  /// No description provided for @commentPending.
  ///
  /// In en, this message translates to:
  /// **'Your comment is awaiting admin approval.'**
  String get commentPending;

  /// No description provided for @loginToggle.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginToggle;

  /// No description provided for @registerToggle.
  ///
  /// In en, this message translates to:
  /// **'Apply to Join'**
  String get registerToggle;

  /// No description provided for @adminLogin.
  ///
  /// In en, this message translates to:
  /// **'Admin Login'**
  String get adminLogin;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'BACK TO LOGIN'**
  String get backToLogin;

  /// No description provided for @updatePrice.
  ///
  /// In en, this message translates to:
  /// **'Update Price'**
  String get updatePrice;

  /// No description provided for @approveComment.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approveComment;

  /// No description provided for @rejectComment.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get rejectComment;

  /// No description provided for @orderStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get orderStatus;

  /// No description provided for @editPost.
  ///
  /// In en, this message translates to:
  /// **'Edit Post Details'**
  String get editPost;

  /// No description provided for @approveAndPost.
  ///
  /// In en, this message translates to:
  /// **'Approve and Post'**
  String get approveAndPost;

  /// No description provided for @selectPromoTier.
  ///
  /// In en, this message translates to:
  /// **'Select Promotion Tier'**
  String get selectPromoTier;

  /// No description provided for @promoOneWeek.
  ///
  /// In en, this message translates to:
  /// **'1 Week - 500 ETB'**
  String get promoOneWeek;

  /// No description provided for @promoTwoWeeks.
  ///
  /// In en, this message translates to:
  /// **'2 Weeks - 800 ETB'**
  String get promoTwoWeeks;

  /// No description provided for @promoOneMonth.
  ///
  /// In en, this message translates to:
  /// **'1 Month - 1200 ETB'**
  String get promoOneMonth;

  /// No description provided for @uploadPhotos.
  ///
  /// In en, this message translates to:
  /// **'Upload Photos (min 1)'**
  String get uploadPhotos;

  /// No description provided for @whatDoYouWantToBuy.
  ///
  /// In en, this message translates to:
  /// **'What do you want to buy?'**
  String get whatDoYouWantToBuy;

  /// No description provided for @mizanFactoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Mizan Factory Products'**
  String get mizanFactoryTitle;

  /// No description provided for @allFarmerListings.
  ///
  /// In en, this message translates to:
  /// **'All Farmer Listings'**
  String get allFarmerListings;
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
      <String>['am', 'en', 'om', 'so', 'ti'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'am':
      return AppLocalizationsAm();
    case 'en':
      return AppLocalizationsEn();
    case 'om':
      return AppLocalizationsOm();
    case 'so':
      return AppLocalizationsSo();
    case 'ti':
      return AppLocalizationsTi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
