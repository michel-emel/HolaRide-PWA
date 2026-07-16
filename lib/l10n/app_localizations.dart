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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'(optional)'**
  String get optional;

  /// No description provided for @yourDataSafe.
  ///
  /// In en, this message translates to:
  /// **'Your data is safe with us'**
  String get yourDataSafe;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabRoute.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get tabRoute;

  /// No description provided for @tabLogin.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get tabLogin;

  /// No description provided for @tabMyTrips.
  ///
  /// In en, this message translates to:
  /// **'My Trips'**
  String get tabMyTrips;

  /// No description provided for @tabChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get tabChat;

  /// No description provided for @tabProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get tabProfile;

  /// No description provided for @welcomeTagline.
  ///
  /// In en, this message translates to:
  /// **'Travel between cities,\ntogether.'**
  String get welcomeTagline;

  /// No description provided for @welcomeCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get welcomeCreateAccount;

  /// No description provided for @welcomeSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get welcomeSignIn;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your name and phone number to get started.'**
  String get registerSubtitle;

  /// No description provided for @registerFirstName.
  ///
  /// In en, this message translates to:
  /// **'First name *'**
  String get registerFirstName;

  /// No description provided for @registerFirstNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Michel'**
  String get registerFirstNameHint;

  /// No description provided for @registerLastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get registerLastName;

  /// No description provided for @registerLastNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Dupont'**
  String get registerLastNameHint;

  /// No description provided for @registerPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number *'**
  String get registerPhoneNumber;

  /// No description provided for @registerContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get registerContinue;

  /// No description provided for @registerTermsPrefix.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our '**
  String get registerTermsPrefix;

  /// No description provided for @registerTermsLink.
  ///
  /// In en, this message translates to:
  /// **'Terms and Privacy Policy.'**
  String get registerTermsLink;

  /// No description provided for @registerAlreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get registerAlreadyHaveAccount;

  /// No description provided for @registerErrorFirstName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your first name.'**
  String get registerErrorFirstName;

  /// No description provided for @registerErrorPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 9-digit Cameroon mobile number.'**
  String get registerErrorPhone;

  /// No description provided for @registerErrorServer.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server. Check your connection and try again.'**
  String get registerErrorServer;

  /// No description provided for @registerAccountExistsTitle.
  ///
  /// In en, this message translates to:
  /// **'Account exists'**
  String get registerAccountExistsTitle;

  /// No description provided for @registerAccountExistsBody.
  ///
  /// In en, this message translates to:
  /// **'An account already exists for this number.\n\nPlease sign in instead.'**
  String get registerAccountExistsBody;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number to sign in.'**
  String get loginSubtitle;

  /// No description provided for @loginPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'6 75 12 34 56'**
  String get loginPhoneHint;

  /// No description provided for @loginSendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get loginSendCode;

  /// No description provided for @loginNoAccountLink.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Create one'**
  String get loginNoAccountLink;

  /// No description provided for @loginNoAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'No account found'**
  String get loginNoAccountTitle;

  /// No description provided for @loginNoAccountBody.
  ///
  /// In en, this message translates to:
  /// **'No account exists for this number.\n\nPlease create an account first.'**
  String get loginNoAccountBody;

  /// No description provided for @loginErrorPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 9-digit Cameroon number.'**
  String get loginErrorPhone;

  /// No description provided for @loginErrorServer.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server. Try again.'**
  String get loginErrorServer;

  /// No description provided for @otpSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to HolaRide'**
  String get otpSignInTitle;

  /// No description provided for @otpVerifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your number'**
  String get otpVerifyTitle;

  /// No description provided for @otpSentTo.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to '**
  String get otpSentTo;

  /// No description provided for @otpWrongNumber.
  ///
  /// In en, this message translates to:
  /// **'Wrong number? Go back'**
  String get otpWrongNumber;

  /// No description provided for @otpDevMode.
  ///
  /// In en, this message translates to:
  /// **'DEV MODE — your code is {code}'**
  String otpDevMode(String code);

  /// No description provided for @otpVerifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying…'**
  String get otpVerifying;

  /// No description provided for @otpResendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {countdown}'**
  String otpResendIn(String countdown);

  /// No description provided for @otpResend.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get otpResend;

  /// No description provided for @otpResending.
  ///
  /// In en, this message translates to:
  /// **'Resending…'**
  String get otpResending;

  /// No description provided for @otpErrorVerify.
  ///
  /// In en, this message translates to:
  /// **'Verification failed. Check the code and try again.'**
  String get otpErrorVerify;

  /// No description provided for @otpErrorResend.
  ///
  /// In en, this message translates to:
  /// **'Could not resend the code. Try again.'**
  String get otpErrorResend;

  /// No description provided for @otpAccountExistsTitle.
  ///
  /// In en, this message translates to:
  /// **'Account exists'**
  String get otpAccountExistsTitle;

  /// No description provided for @otpAccountExistsBody.
  ///
  /// In en, this message translates to:
  /// **'An account already exists for this number.\n\nPlease sign in instead.'**
  String get otpAccountExistsBody;

  /// No description provided for @otpNoAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'No account found'**
  String get otpNoAccountTitle;

  /// No description provided for @otpNoAccountBody.
  ///
  /// In en, this message translates to:
  /// **'No account found for this number.\n\nPlease create an account first.'**
  String get otpNoAccountBody;

  /// No description provided for @otpCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get otpCreateAccount;

  /// No description provided for @nameEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'What should\nwe call you?'**
  String get nameEntryTitle;

  /// No description provided for @nameEntrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'This will be visible on your profile'**
  String get nameEntrySubtitle;

  /// No description provided for @nameEntryHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Michel Kamga'**
  String get nameEntryHint;

  /// No description provided for @nameEntryError.
  ///
  /// In en, this message translates to:
  /// **'Tell us what to call you.'**
  String get nameEntryError;

  /// No description provided for @nameEntrySaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save your name. Try again.'**
  String get nameEntrySaveError;

  /// No description provided for @homeGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get homeGetStarted;

  /// No description provided for @homeMaybeLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe later'**
  String get homeMaybeLater;

  /// No description provided for @homeJoinTitle.
  ///
  /// In en, this message translates to:
  /// **'Join HolaRide'**
  String get homeJoinTitle;

  /// No description provided for @homeJoinBody.
  ///
  /// In en, this message translates to:
  /// **'Create an account to book trips, chat with drivers, and travel safely across cities.'**
  String get homeJoinBody;

  /// No description provided for @homeHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Rides Going Your Way'**
  String get homeHeroTitle;

  /// No description provided for @homeHeroBody.
  ///
  /// In en, this message translates to:
  /// **'HolaRide connects you with verified drivers making the same intercity trip.'**
  String get homeHeroBody;

  /// No description provided for @homeFindRide.
  ///
  /// In en, this message translates to:
  /// **'Find a Ride'**
  String get homeFindRide;

  /// No description provided for @homeRideShare.
  ///
  /// In en, this message translates to:
  /// **'Ride Share'**
  String get homeRideShare;

  /// No description provided for @homeAvailableTrips.
  ///
  /// In en, this message translates to:
  /// **'Available trips'**
  String get homeAvailableTrips;

  /// No description provided for @homeSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get homeSeeAll;

  /// No description provided for @homeNoTrips.
  ///
  /// In en, this message translates to:
  /// **'No trips available right now'**
  String get homeNoTrips;

  /// No description provided for @homeNoTripsHint.
  ///
  /// In en, this message translates to:
  /// **'Try a different route or check again later.'**
  String get homeNoTripsHint;

  /// No description provided for @homeExploreRoutes.
  ///
  /// In en, this message translates to:
  /// **'Explore popular routes'**
  String get homeExploreRoutes;

  /// No description provided for @homeShareRideTitle.
  ///
  /// In en, this message translates to:
  /// **'Share your ride, reduce cost'**
  String get homeShareRideTitle;

  /// No description provided for @homeShareRideBody.
  ///
  /// In en, this message translates to:
  /// **'Split your fare and travel together.'**
  String get homeShareRideBody;

  /// No description provided for @homeRiderCount.
  ///
  /// In en, this message translates to:
  /// **'Riders using the app'**
  String get homeRiderCount;

  /// No description provided for @homeTripHours.
  ///
  /// In en, this message translates to:
  /// **'Trip hours completed'**
  String get homeTripHours;

  /// No description provided for @homeHelloName.
  ///
  /// In en, this message translates to:
  /// **'Hello {name} 👋'**
  String homeHelloName(String name);

  /// No description provided for @homeHello.
  ///
  /// In en, this message translates to:
  /// **'Hello 👋'**
  String get homeHello;

  /// No description provided for @homePerSeat.
  ///
  /// In en, this message translates to:
  /// **'per seat'**
  String get homePerSeat;

  /// No description provided for @homeSeatsLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} left'**
  String homeSeatsLeft(int count);

  /// No description provided for @homeLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load nearby trips.'**
  String get homeLoadError;

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Find a trip'**
  String get searchTitle;

  /// No description provided for @searchFrom.
  ///
  /// In en, this message translates to:
  /// **'Leaving from'**
  String get searchFrom;

  /// No description provided for @searchTo.
  ///
  /// In en, this message translates to:
  /// **'Going to'**
  String get searchTo;

  /// No description provided for @searchDate.
  ///
  /// In en, this message translates to:
  /// **'Departure date'**
  String get searchDate;

  /// No description provided for @searchChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get searchChange;

  /// No description provided for @searchToday.
  ///
  /// In en, this message translates to:
  /// **'Today, {day} {month}'**
  String searchToday(int day, String month);

  /// No description provided for @searchTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow, {day} {month}'**
  String searchTomorrow(int day, String month);

  /// No description provided for @searchButton.
  ///
  /// In en, this message translates to:
  /// **'Search trips'**
  String get searchButton;

  /// No description provided for @searchErrorRoute.
  ///
  /// In en, this message translates to:
  /// **'Please select both departure and destination.'**
  String get searchErrorRoute;

  /// No description provided for @searchErrorSameCity.
  ///
  /// In en, this message translates to:
  /// **'Departure and destination must be different cities.'**
  String get searchErrorSameCity;

  /// No description provided for @searchCityFrom.
  ///
  /// In en, this message translates to:
  /// **'City or pickup point'**
  String get searchCityFrom;

  /// No description provided for @searchCityTo.
  ///
  /// In en, this message translates to:
  /// **'City or drop-off point'**
  String get searchCityTo;

  /// No description provided for @searchPickerHint.
  ///
  /// In en, this message translates to:
  /// **'Search city or pickup point'**
  String get searchPickerHint;

  /// No description provided for @searchPopularCities.
  ///
  /// In en, this message translates to:
  /// **'Popular cities'**
  String get searchPopularCities;

  /// No description provided for @searchNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No matching locations.'**
  String get searchNoMatch;

  /// No description provided for @searchSortTime.
  ///
  /// In en, this message translates to:
  /// **'Sort by time'**
  String get searchSortTime;

  /// No description provided for @searchSortPrice.
  ///
  /// In en, this message translates to:
  /// **'Sort by price'**
  String get searchSortPrice;

  /// No description provided for @searchTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get searchTimeLabel;

  /// No description provided for @searchPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get searchPriceLabel;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No trips on this route and date yet. Try another date, or be among our first riders to request it.'**
  String get searchNoResults;

  /// No description provided for @searchLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load trips. Pull down to try again.'**
  String get searchLoadError;

  /// No description provided for @bookingsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Trips'**
  String get bookingsTitle;

  /// No description provided for @bookingsAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get bookingsAll;

  /// No description provided for @bookingsUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get bookingsUpcoming;

  /// No description provided for @bookingsPast.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get bookingsPast;

  /// No description provided for @bookingsLoginPrompt.
  ///
  /// In en, this message translates to:
  /// **'Log in to see your bookings'**
  String get bookingsLoginPrompt;

  /// No description provided for @bookingsLoginHint.
  ///
  /// In en, this message translates to:
  /// **'Your trip requests and booking history will show up here once you log in.'**
  String get bookingsLoginHint;

  /// No description provided for @bookingsLoginSignup.
  ///
  /// In en, this message translates to:
  /// **'Log in / Sign up'**
  String get bookingsLoginSignup;

  /// No description provided for @bookingsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No bookings here yet.'**
  String get bookingsEmpty;

  /// No description provided for @bookingsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your bookings.'**
  String get bookingsLoadError;

  /// No description provided for @bookingsTripFallback.
  ///
  /// In en, this message translates to:
  /// **'Trip'**
  String get bookingsTripFallback;

  /// No description provided for @bookingsChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get bookingsChat;

  /// No description provided for @bookingsTrack.
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get bookingsTrack;

  /// No description provided for @bookingsRatePassenger.
  ///
  /// In en, this message translates to:
  /// **'Rate {name}'**
  String bookingsRatePassenger(String name);

  /// No description provided for @bookingsSeatSingular.
  ///
  /// In en, this message translates to:
  /// **'{count} seat'**
  String bookingsSeatSingular(int count);

  /// No description provided for @bookingsSeatPlural.
  ///
  /// In en, this message translates to:
  /// **'{count} seats'**
  String bookingsSeatPlural(int count);

  /// No description provided for @bookingStatusWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get bookingStatusWaiting;

  /// No description provided for @bookingStatusAwaitingPayment.
  ///
  /// In en, this message translates to:
  /// **'Awaiting payment'**
  String get bookingStatusAwaitingPayment;

  /// No description provided for @bookingStatusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get bookingStatusPaid;

  /// No description provided for @bookingStatusDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get bookingStatusDeclined;

  /// No description provided for @bookingStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get bookingStatusCancelled;

  /// No description provided for @bookingStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get bookingStatusCompleted;

  /// No description provided for @bookingStatusNoShow.
  ///
  /// In en, this message translates to:
  /// **'No-show'**
  String get bookingStatusNoShow;

  /// No description provided for @bookingStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get bookingStatusUnknown;

  /// No description provided for @chatInboxTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chatInboxTitle;

  /// No description provided for @chatInboxEmpty.
  ///
  /// In en, this message translates to:
  /// **'No chats yet'**
  String get chatInboxEmpty;

  /// No description provided for @chatInboxEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Chats open automatically once a booking is paid, or for any trip you publish.'**
  String get chatInboxEmptyHint;

  /// No description provided for @chatInboxDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete chat?'**
  String get chatInboxDeleteTitle;

  /// No description provided for @chatInboxDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This removes the chat from your list. The trip and your booking are not affected.'**
  String get chatInboxDeleteBody;

  /// No description provided for @chatInboxDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get chatInboxDelete;

  /// No description provided for @chatInboxDriver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get chatInboxDriver;

  /// No description provided for @chatInboxPassenger.
  ///
  /// In en, this message translates to:
  /// **'Passenger'**
  String get chatInboxPassenger;

  /// No description provided for @chatTripTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip chat'**
  String get chatTripTitle;

  /// No description provided for @chatDeleteChat.
  ///
  /// In en, this message translates to:
  /// **'Delete chat'**
  String get chatDeleteChat;

  /// No description provided for @chatNoMessages.
  ///
  /// In en, this message translates to:
  /// **'No messages yet — say hello!'**
  String get chatNoMessages;

  /// No description provided for @chatDeletedByYou.
  ///
  /// In en, this message translates to:
  /// **'You deleted this message'**
  String get chatDeletedByYou;

  /// No description provided for @chatDeleted.
  ///
  /// In en, this message translates to:
  /// **'This message was deleted'**
  String get chatDeleted;

  /// No description provided for @chatSharedLocation.
  ///
  /// In en, this message translates to:
  /// **'Shared location · Tap to open'**
  String get chatSharedLocation;

  /// No description provided for @chatTypePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get chatTypePlaceholder;

  /// No description provided for @chatShareLocation.
  ///
  /// In en, this message translates to:
  /// **'Share location'**
  String get chatShareLocation;

  /// No description provided for @chatReadOnlyCancelled.
  ///
  /// In en, this message translates to:
  /// **'Trip cancelled — chat is now read-only.'**
  String get chatReadOnlyCancelled;

  /// No description provided for @chatReadOnlyCompleted.
  ///
  /// In en, this message translates to:
  /// **'Trip completed — chat is now read-only.'**
  String get chatReadOnlyCompleted;

  /// No description provided for @chatSendError.
  ///
  /// In en, this message translates to:
  /// **'Message didn\'t send. Try again.'**
  String get chatSendError;

  /// No description provided for @chatLocationError.
  ///
  /// In en, this message translates to:
  /// **'Could not get your location. Check permissions and try again.'**
  String get chatLocationError;

  /// No description provided for @chatMapsError.
  ///
  /// In en, this message translates to:
  /// **'Could not open maps. Make sure Google Maps (or a browser) is installed.'**
  String get chatMapsError;

  /// No description provided for @chatDeleteMsgTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this message?'**
  String get chatDeleteMsgTitle;

  /// No description provided for @chatDeleteMsgBody.
  ///
  /// In en, this message translates to:
  /// **'This only deletes it for everyone in this chat — it can\'t be undone.'**
  String get chatDeleteMsgBody;

  /// No description provided for @chatDeleteMsgError.
  ///
  /// In en, this message translates to:
  /// **'Could not delete this message. Try again.'**
  String get chatDeleteMsgError;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsMarkRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get notificationsMarkRead;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get notificationsEmpty;

  /// No description provided for @notificationsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'You\'ll see updates here when something happens.'**
  String get notificationsEmptyHint;

  /// No description provided for @notificationsJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get notificationsJustNow;

  /// No description provided for @notificationsMinsAgo.
  ///
  /// In en, this message translates to:
  /// **'{n}m ago'**
  String notificationsMinsAgo(int n);

  /// No description provided for @notificationsHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{n}h ago'**
  String notificationsHoursAgo(int n);

  /// No description provided for @notificationsYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get notificationsYesterday;

  /// No description provided for @notificationsDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{n}d ago'**
  String notificationsDaysAgo(int n);

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileGuestTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re browsing as a guest'**
  String get profileGuestTitle;

  /// No description provided for @profileGuestBody.
  ///
  /// In en, this message translates to:
  /// **'Log in or sign up to book trips, publish rides, and manage your account.'**
  String get profileGuestBody;

  /// No description provided for @profileLoginSignup.
  ///
  /// In en, this message translates to:
  /// **'Log in / Sign up'**
  String get profileLoginSignup;

  /// No description provided for @profileAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get profileAccount;

  /// No description provided for @profileBecomeDriver.
  ///
  /// In en, this message translates to:
  /// **'Become a Driver'**
  String get profileBecomeDriver;

  /// No description provided for @profileMyVehicle.
  ///
  /// In en, this message translates to:
  /// **'My Vehicle'**
  String get profileMyVehicle;

  /// No description provided for @profileSwitchToDriver.
  ///
  /// In en, this message translates to:
  /// **'Switch to Driver'**
  String get profileSwitchToDriver;

  /// No description provided for @profileSwitchToPassenger.
  ///
  /// In en, this message translates to:
  /// **'Switch to Passenger'**
  String get profileSwitchToPassenger;

  /// No description provided for @profilePayoutHistory.
  ///
  /// In en, this message translates to:
  /// **'Payout History'**
  String get profilePayoutHistory;

  /// No description provided for @profileSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get profileSupport;

  /// No description provided for @profileHelpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get profileHelpSupport;

  /// No description provided for @profileTermsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Terms & Privacy Policy'**
  String get profileTermsPrivacy;

  /// No description provided for @profileLogout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get profileLogout;

  /// No description provided for @profileLogoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get profileLogoutTitle;

  /// No description provided for @profileLogoutBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ll need to verify your phone number again to log back in.'**
  String get profileLogoutBody;

  /// No description provided for @profileVersion.
  ///
  /// In en, this message translates to:
  /// **'HolaRide v1.0.0'**
  String get profileVersion;

  /// No description provided for @profileLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileLanguage;

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfileTitle;

  /// No description provided for @editProfileName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get editProfileName;

  /// No description provided for @editProfileNameHint.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get editProfileNameHint;

  /// No description provided for @editProfilePhone.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get editProfilePhone;

  /// No description provided for @editProfileSave.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get editProfileSave;

  /// No description provided for @editProfileErrorName.
  ///
  /// In en, this message translates to:
  /// **'Enter a name.'**
  String get editProfileErrorName;

  /// No description provided for @editProfileSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save your changes. Try again.'**
  String get editProfileSaveError;

  /// No description provided for @driverMyTripsUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get driverMyTripsUpcoming;

  /// No description provided for @driverMyTripsPast.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get driverMyTripsPast;

  /// No description provided for @driverMyTripsCreate.
  ///
  /// In en, this message translates to:
  /// **'Create a New Trip'**
  String get driverMyTripsCreate;

  /// No description provided for @driverMyTripsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No trips here yet.'**
  String get driverMyTripsEmpty;

  /// No description provided for @driverRatePassengers.
  ///
  /// In en, this message translates to:
  /// **'Rate {count} passengers'**
  String driverRatePassengers(int count);

  /// No description provided for @driverRateOne.
  ///
  /// In en, this message translates to:
  /// **'Rate {name}'**
  String driverRateOne(String name);

  /// No description provided for @tripMgmtCancelTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this trip?'**
  String get tripMgmtCancelTitle;

  /// No description provided for @tripMgmtCancelBody.
  ///
  /// In en, this message translates to:
  /// **'Every passenger who already paid will be notified and refunded per your cancellation policy.'**
  String get tripMgmtCancelBody;

  /// No description provided for @tripMgmtCancelled.
  ///
  /// In en, this message translates to:
  /// **'Trip cancelled.'**
  String get tripMgmtCancelled;

  /// No description provided for @tripMgmtCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Mark trip as completed?'**
  String get tripMgmtCompleteTitle;

  /// No description provided for @tripMgmtCompleteBody.
  ///
  /// In en, this message translates to:
  /// **'This closes the trip out once everyone has arrived.'**
  String get tripMgmtCompleteBody;

  /// No description provided for @tripMgmtCompleted.
  ///
  /// In en, this message translates to:
  /// **'Trip marked as completed!'**
  String get tripMgmtCompleted;

  /// No description provided for @tripMgmtNoShowTitle.
  ///
  /// In en, this message translates to:
  /// **'Who didn\'t show up?'**
  String get tripMgmtNoShowTitle;

  /// No description provided for @tripMgmtNoShowBody.
  ///
  /// In en, this message translates to:
  /// **'Mark {name} as no-show?'**
  String tripMgmtNoShowBody(String name);

  /// No description provided for @tripMgmtNoShowDetail.
  ///
  /// In en, this message translates to:
  /// **'This affects their record and may apply a fee per your policy.'**
  String get tripMgmtNoShowDetail;

  /// No description provided for @tripMgmtRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests ({count})'**
  String tripMgmtRequests(int count);

  /// No description provided for @tripMgmtBookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings ({count})'**
  String tripMgmtBookings(int count);

  /// No description provided for @tripMgmtActions.
  ///
  /// In en, this message translates to:
  /// **'Trip actions'**
  String get tripMgmtActions;

  /// No description provided for @tripMgmtNoRequests.
  ///
  /// In en, this message translates to:
  /// **'No new requests.'**
  String get tripMgmtNoRequests;

  /// No description provided for @tripMgmtNoPassengers.
  ///
  /// In en, this message translates to:
  /// **'No confirmed passengers yet.'**
  String get tripMgmtNoPassengers;

  /// No description provided for @tripMgmtActingOn.
  ///
  /// In en, this message translates to:
  /// **'Acting on this trip'**
  String get tripMgmtActingOn;

  /// No description provided for @tripMgmtMarkComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark Completed'**
  String get tripMgmtMarkComplete;

  /// No description provided for @tripMgmtMarkNoShow.
  ///
  /// In en, this message translates to:
  /// **'Mark No-show'**
  String get tripMgmtMarkNoShow;

  /// No description provided for @tripMgmtCancelBtn.
  ///
  /// In en, this message translates to:
  /// **'Cancel Trip'**
  String get tripMgmtCancelBtn;

  /// No description provided for @tripMgmtLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load requests for this trip.'**
  String get tripMgmtLoadError;

  /// No description provided for @tripMgmtAcceptError.
  ///
  /// In en, this message translates to:
  /// **'Could not accept this request.'**
  String get tripMgmtAcceptError;

  /// No description provided for @tripMgmtRejectError.
  ///
  /// In en, this message translates to:
  /// **'Could not reject this request.'**
  String get tripMgmtRejectError;

  /// No description provided for @tripMgmtGenericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get tripMgmtGenericError;

  /// No description provided for @createTripTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a trip'**
  String get createTripTitle;

  /// No description provided for @createTripFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get createTripFrom;

  /// No description provided for @createTripTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get createTripTo;

  /// No description provided for @createTripDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get createTripDate;

  /// No description provided for @createTripDeparture.
  ///
  /// In en, this message translates to:
  /// **'Departure time'**
  String get createTripDeparture;

  /// No description provided for @createTripSeats.
  ///
  /// In en, this message translates to:
  /// **'Available seats'**
  String get createTripSeats;

  /// No description provided for @createTripSeatsHint.
  ///
  /// In en, this message translates to:
  /// **'Up to {max} — your vehicle\'s registered capacity'**
  String createTripSeatsHint(int max);

  /// No description provided for @createTripPrice.
  ///
  /// In en, this message translates to:
  /// **'Price per seat'**
  String get createTripPrice;

  /// No description provided for @createTripPriceHint.
  ///
  /// In en, this message translates to:
  /// **'Pick \"From\" and \"To\" to see the price'**
  String get createTripPriceHint;

  /// No description provided for @createTripPriceNote.
  ///
  /// In en, this message translates to:
  /// **'Set by HolaRide based on your route and vehicle category — drivers don\'t set prices.'**
  String get createTripPriceNote;

  /// No description provided for @createTripPublish.
  ///
  /// In en, this message translates to:
  /// **'Publish Trip'**
  String get createTripPublish;

  /// No description provided for @createTripSelectLocation.
  ///
  /// In en, this message translates to:
  /// **'Select location'**
  String get createTripSelectLocation;

  /// No description provided for @createTripLocationHint.
  ///
  /// In en, this message translates to:
  /// **'Choose where you\'re leaving from and going to.'**
  String get createTripLocationHint;

  /// No description provided for @createTripNoVehicle.
  ///
  /// In en, this message translates to:
  /// **'No approved vehicle found on your account — check My Vehicle in Profile.'**
  String get createTripNoVehicle;

  /// No description provided for @createTripNoPriceError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load a price for this route.'**
  String get createTripNoPriceError;

  /// No description provided for @createTripPublishError.
  ///
  /// In en, this message translates to:
  /// **'Could not publish this trip. Try again.'**
  String get createTripPublishError;

  /// No description provided for @createTripLeavingFrom.
  ///
  /// In en, this message translates to:
  /// **'Leaving from'**
  String get createTripLeavingFrom;

  /// No description provided for @createTripGoingTo.
  ///
  /// In en, this message translates to:
  /// **'Going to'**
  String get createTripGoingTo;

  /// No description provided for @vehicleRegTitle.
  ///
  /// In en, this message translates to:
  /// **'Add your vehicle'**
  String get vehicleRegTitle;

  /// No description provided for @vehicleRegSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us about your car — this is what gets reviewed before you can publish trips.'**
  String get vehicleRegSubtitle;

  /// No description provided for @vehicleRegDetails.
  ///
  /// In en, this message translates to:
  /// **'Vehicle details'**
  String get vehicleRegDetails;

  /// No description provided for @vehicleRegBrand.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get vehicleRegBrand;

  /// No description provided for @vehicleRegModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get vehicleRegModel;

  /// No description provided for @vehicleRegYear.
  ///
  /// In en, this message translates to:
  /// **'Year (optional)'**
  String get vehicleRegYear;

  /// No description provided for @vehicleRegColor.
  ///
  /// In en, this message translates to:
  /// **'Color (optional)'**
  String get vehicleRegColor;

  /// No description provided for @vehicleRegPlate.
  ///
  /// In en, this message translates to:
  /// **'License plate'**
  String get vehicleRegPlate;

  /// No description provided for @vehicleRegSeats.
  ///
  /// In en, this message translates to:
  /// **'Total seats'**
  String get vehicleRegSeats;

  /// No description provided for @vehicleRegSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit for Review'**
  String get vehicleRegSubmit;

  /// No description provided for @vehicleRegValidationError.
  ///
  /// In en, this message translates to:
  /// **'Fill in brand, model, plate number, and seats.'**
  String get vehicleRegValidationError;

  /// No description provided for @vehicleRegSubmitError.
  ///
  /// In en, this message translates to:
  /// **'Could not submit your vehicle. Try again.'**
  String get vehicleRegSubmitError;

  /// No description provided for @vehicleRegBrandHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Toyota'**
  String get vehicleRegBrandHint;

  /// No description provided for @vehicleRegModelHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Corolla'**
  String get vehicleRegModelHint;

  /// No description provided for @vehicleRegYearHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 2018'**
  String get vehicleRegYearHint;

  /// No description provided for @vehicleRegColorHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Silver'**
  String get vehicleRegColorHint;

  /// No description provided for @vehicleRegPlateHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. CMR-123-AA'**
  String get vehicleRegPlateHint;

  /// No description provided for @vehicleStatusNoVehicle.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t added a vehicle yet.'**
  String get vehicleStatusNoVehicle;

  /// No description provided for @vehicleStatusAdd.
  ///
  /// In en, this message translates to:
  /// **'Add your vehicle'**
  String get vehicleStatusAdd;

  /// No description provided for @vehicleStatusPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get vehicleStatusPhotos;

  /// No description provided for @vehicleStatusAddPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add Photos'**
  String get vehicleStatusAddPhotos;

  /// No description provided for @vehicleStatusUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get vehicleStatusUploading;

  /// No description provided for @vehicleStatusNoPhotos.
  ///
  /// In en, this message translates to:
  /// **'No photos yet — add a few so passengers recognize your car.'**
  String get vehicleStatusNoPhotos;

  /// No description provided for @vehicleStatusPhotoError.
  ///
  /// In en, this message translates to:
  /// **'Some photos didn\'t upload. Try again.'**
  String get vehicleStatusPhotoError;

  /// No description provided for @vehicleStatusFirstTrip.
  ///
  /// In en, this message translates to:
  /// **'Create your first trip'**
  String get vehicleStatusFirstTrip;

  /// No description provided for @vehicleStatusStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get vehicleStatusStatusLabel;

  /// No description provided for @vehicleStatusPending.
  ///
  /// In en, this message translates to:
  /// **'We are verifying your documents and vehicle. You\'ll be notified once it\'s approved.'**
  String get vehicleStatusPending;

  /// No description provided for @vehicleStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Your vehicle is approved — you can publish trips now.'**
  String get vehicleStatusApproved;

  /// No description provided for @vehicleStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Your submission was rejected. Contact support for details, or submit a new vehicle.'**
  String get vehicleStatusRejected;

  /// No description provided for @vehicleStatusUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Status unavailable right now.'**
  String get vehicleStatusUnavailable;

  /// No description provided for @vehicleStatusLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your vehicle status.'**
  String get vehicleStatusLoadError;

  /// No description provided for @payoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Payout history'**
  String get payoutTitle;

  /// No description provided for @payoutTotal.
  ///
  /// In en, this message translates to:
  /// **'Total paid out'**
  String get payoutTotal;

  /// No description provided for @payoutNote.
  ///
  /// In en, this message translates to:
  /// **'Sent automatically to your Mobile Money after each completed trip.'**
  String get payoutNote;

  /// No description provided for @payoutHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get payoutHistory;

  /// No description provided for @payoutEmpty.
  ///
  /// In en, this message translates to:
  /// **'No payouts yet.'**
  String get payoutEmpty;

  /// No description provided for @payoutPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get payoutPaid;

  /// No description provided for @payoutPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get payoutPending;

  /// No description provided for @payoutLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your payouts.'**
  String get payoutLoadError;

  /// No description provided for @tripDetailBook.
  ///
  /// In en, this message translates to:
  /// **'Book a Seat'**
  String get tripDetailBook;

  /// No description provided for @tripDetailNoSeats.
  ///
  /// In en, this message translates to:
  /// **'No seats left'**
  String get tripDetailNoSeats;

  /// No description provided for @tripDetailNoReviews.
  ///
  /// In en, this message translates to:
  /// **'No driver reviews yet'**
  String get tripDetailNoReviews;

  /// No description provided for @tripDetailReview.
  ///
  /// In en, this message translates to:
  /// **'review'**
  String get tripDetailReview;

  /// No description provided for @tripDetailReviews.
  ///
  /// In en, this message translates to:
  /// **'reviews for this driver'**
  String get tripDetailReviews;

  /// No description provided for @tripDetailVehicleCategory.
  ///
  /// In en, this message translates to:
  /// **'Vehicle category'**
  String get tripDetailVehicleCategory;

  /// No description provided for @tripDetailSeat.
  ///
  /// In en, this message translates to:
  /// **'seat'**
  String get tripDetailSeat;

  /// No description provided for @tripDetailSeatsAvailable.
  ///
  /// In en, this message translates to:
  /// **'seats available'**
  String get tripDetailSeatsAvailable;

  /// No description provided for @bookingRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Request a Seat'**
  String get bookingRequestTitle;

  /// No description provided for @bookingRequestStep.
  ///
  /// In en, this message translates to:
  /// **'Step 1 of 2'**
  String get bookingRequestStep;

  /// No description provided for @bookingRequestSeats.
  ///
  /// In en, this message translates to:
  /// **'Seats'**
  String get bookingRequestSeats;

  /// No description provided for @bookingRequestPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment option'**
  String get bookingRequestPayment;

  /// No description provided for @bookingRequestPayFull.
  ///
  /// In en, this message translates to:
  /// **'Pay Full'**
  String get bookingRequestPayFull;

  /// No description provided for @bookingRequestPayDeposit.
  ///
  /// In en, this message translates to:
  /// **'Pay 80% Deposit'**
  String get bookingRequestPayDeposit;

  /// No description provided for @bookingRequestDepositHint.
  ///
  /// In en, this message translates to:
  /// **'Pay {deposit} now, {remaining} before trip'**
  String bookingRequestDepositHint(String deposit, String remaining);

  /// No description provided for @bookingRequestDueNow.
  ///
  /// In en, this message translates to:
  /// **'Due now'**
  String get bookingRequestDueNow;

  /// No description provided for @bookingRequestTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get bookingRequestTotal;

  /// No description provided for @bookingRequestRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining before trip'**
  String get bookingRequestRemaining;

  /// No description provided for @bookingRequestContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get bookingRequestContinue;

  /// No description provided for @bookingRequestDeparture.
  ///
  /// In en, this message translates to:
  /// **'Departure point'**
  String get bookingRequestDeparture;

  /// No description provided for @bookingRequestDropoff.
  ///
  /// In en, this message translates to:
  /// **'Drop-off point'**
  String get bookingRequestDropoff;

  /// No description provided for @bookingRequestSeatsAvailable.
  ///
  /// In en, this message translates to:
  /// **'{count} seats available'**
  String bookingRequestSeatsAvailable(int count);

  /// No description provided for @waitingTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the driver'**
  String get waitingTitle;

  /// No description provided for @waitingBody.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent your request to the driver.\nYou\'ll be notified here as soon as they respond.'**
  String get waitingBody;

  /// No description provided for @waitingDeclinedTitle.
  ///
  /// In en, this message translates to:
  /// **'Request declined'**
  String get waitingDeclinedTitle;

  /// No description provided for @waitingDeclinedBody.
  ///
  /// In en, this message translates to:
  /// **'The driver wasn\'t able to accept your request this time. You can search for another trip.'**
  String get waitingDeclinedBody;

  /// No description provided for @waitingBackHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get waitingBackHome;

  /// No description provided for @waitingNote.
  ///
  /// In en, this message translates to:
  /// **'This request can take time. We\'ll notify you immediately.'**
  String get waitingNote;

  /// No description provided for @waitingWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw request'**
  String get waitingWithdraw;

  /// No description provided for @waitingSeatsRequested.
  ///
  /// In en, this message translates to:
  /// **'Seats requested'**
  String get waitingSeatsRequested;

  /// No description provided for @waitingPricePerSeat.
  ///
  /// In en, this message translates to:
  /// **'Price per seat'**
  String get waitingPricePerSeat;

  /// No description provided for @rateTripTitle.
  ///
  /// In en, this message translates to:
  /// **'Rate this trip'**
  String get rateTripTitle;

  /// No description provided for @rateTripDriverQuestion.
  ///
  /// In en, this message translates to:
  /// **'How was your trip?'**
  String get rateTripDriverQuestion;

  /// No description provided for @rateTripPassengerQuestion.
  ///
  /// In en, this message translates to:
  /// **'How was each passenger on this trip?'**
  String get rateTripPassengerQuestion;

  /// No description provided for @rateTripNote.
  ///
  /// In en, this message translates to:
  /// **'Your rating helps keep HolaRide trustworthy for everyone.'**
  String get rateTripNote;

  /// No description provided for @rateTripThanksDriver.
  ///
  /// In en, this message translates to:
  /// **'Thanks — you\'ve rated your driver.'**
  String get rateTripThanksDriver;

  /// No description provided for @rateTripThanksPassenger.
  ///
  /// In en, this message translates to:
  /// **'Thanks — you\'ve rated {name}.'**
  String rateTripThanksPassenger(String name);

  /// No description provided for @rateTripYourDriver.
  ///
  /// In en, this message translates to:
  /// **'Your driver'**
  String get rateTripYourDriver;

  /// No description provided for @rateTripStarError.
  ///
  /// In en, this message translates to:
  /// **'Tap a star rating first.'**
  String get rateTripStarError;

  /// No description provided for @rateTripSubmitError.
  ///
  /// In en, this message translates to:
  /// **'Could not submit this rating. Try again.'**
  String get rateTripSubmitError;

  /// No description provided for @rateTripDriverComment.
  ///
  /// In en, this message translates to:
  /// **'Anything about the ride? (optional)'**
  String get rateTripDriverComment;

  /// No description provided for @rateTripPassengerComment.
  ///
  /// In en, this message translates to:
  /// **'Anything about this passenger? (optional)'**
  String get rateTripPassengerComment;

  /// No description provided for @rateTripSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit rating'**
  String get rateTripSubmit;

  /// No description provided for @paymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get paymentTitle;

  /// No description provided for @paymentAutoDetected.
  ///
  /// In en, this message translates to:
  /// **'Auto-detected from your number'**
  String get paymentAutoDetected;

  /// No description provided for @paymentAmountDue.
  ///
  /// In en, this message translates to:
  /// **'Amount due'**
  String get paymentAmountDue;

  /// No description provided for @paymentFees.
  ///
  /// In en, this message translates to:
  /// **'Fees: 2% included'**
  String get paymentFees;

  /// No description provided for @paymentPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get paymentPhone;

  /// No description provided for @paymentPrompt.
  ///
  /// In en, this message translates to:
  /// **'You\'ll receive a {operator} prompt on {phone}. Confirm to complete the payment.'**
  String paymentPrompt(String operator, String phone);

  /// No description provided for @paymentPay.
  ///
  /// In en, this message translates to:
  /// **'Pay {amount}'**
  String paymentPay(String amount);

  /// No description provided for @paymentSimulate.
  ///
  /// In en, this message translates to:
  /// **'Simulate (dev only)'**
  String get paymentSimulate;

  /// No description provided for @paymentConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting to Mobile Money...'**
  String get paymentConnecting;

  /// No description provided for @paymentPleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait'**
  String get paymentPleaseWait;

  /// No description provided for @paymentCheckPhone.
  ///
  /// In en, this message translates to:
  /// **'Check your phone'**
  String get paymentCheckPhone;

  /// No description provided for @paymentSentTo.
  ///
  /// In en, this message translates to:
  /// **'A {operator} payment request was sent to\n{phone}'**
  String paymentSentTo(String operator, String phone);

  /// No description provided for @paymentToConfirm.
  ///
  /// In en, this message translates to:
  /// **'to confirm'**
  String get paymentToConfirm;

  /// No description provided for @paymentOpenApp.
  ///
  /// In en, this message translates to:
  /// **'Open {operator} on your phone'**
  String paymentOpenApp(String operator);

  /// No description provided for @paymentOrDial.
  ///
  /// In en, this message translates to:
  /// **'or dial {ussd} to approve the request'**
  String paymentOrDial(String ussd);

  /// No description provided for @paymentCancelBtn.
  ///
  /// In en, this message translates to:
  /// **'Cancel payment'**
  String get paymentCancelBtn;

  /// No description provided for @paymentConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Payment confirmed!'**
  String get paymentConfirmed;

  /// No description provided for @paymentSeatsSecured.
  ///
  /// In en, this message translates to:
  /// **'Your seat is secured.\nThe driver has been notified.'**
  String get paymentSeatsSecured;

  /// No description provided for @paymentBackHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get paymentBackHome;

  /// No description provided for @paymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment failed'**
  String get paymentFailed;

  /// No description provided for @paymentInsufficientBalance.
  ///
  /// In en, this message translates to:
  /// **'Insufficient Balance'**
  String get paymentInsufficientBalance;

  /// No description provided for @paymentInsufficientMsg.
  ///
  /// In en, this message translates to:
  /// **'Your {operator} balance is too low for {amount}.'**
  String paymentInsufficientMsg(String operator, String amount);

  /// No description provided for @paymentTopUp.
  ///
  /// In en, this message translates to:
  /// **'Top up {operator}'**
  String paymentTopUp(String operator);

  /// No description provided for @paymentDial.
  ///
  /// In en, this message translates to:
  /// **'Dial {ussd} on your phone, then retry.'**
  String paymentDial(String ussd);

  /// No description provided for @paymentTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get paymentTryAgain;

  /// No description provided for @paymentGoHome.
  ///
  /// In en, this message translates to:
  /// **'Go back to Home'**
  String get paymentGoHome;

  /// No description provided for @paymentTimeout.
  ///
  /// In en, this message translates to:
  /// **'Payment timed out. Please try again.'**
  String get paymentTimeout;

  /// No description provided for @rebookTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip cancelled'**
  String get rebookTitle;

  /// No description provided for @rebookBody.
  ///
  /// In en, this message translates to:
  /// **'The driver has cancelled this trip.\nWould you like to find another trip?'**
  String get rebookBody;

  /// No description provided for @rebookOriginal.
  ///
  /// In en, this message translates to:
  /// **'Original trip'**
  String get rebookOriginal;

  /// No description provided for @rebookFind.
  ///
  /// In en, this message translates to:
  /// **'Find Another Trip'**
  String get rebookFind;

  /// No description provided for @rebookGoBookings.
  ///
  /// In en, this message translates to:
  /// **'Go to My Bookings'**
  String get rebookGoBookings;

  /// No description provided for @cancelTripTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this trip?'**
  String get cancelTripTitle;

  /// No description provided for @cancelTripBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this trip? Depending on how close it is to departure, a cancellation fee may apply. This action cannot be undone.'**
  String get cancelTripBody;

  /// No description provided for @withdrawTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this request?'**
  String get withdrawTitle;

  /// No description provided for @withdrawBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to withdraw this request? This action cannot be undone.'**
  String get withdrawBody;

  /// No description provided for @cancelTripBtn.
  ///
  /// In en, this message translates to:
  /// **'Cancel Trip'**
  String get cancelTripBtn;

  /// No description provided for @withdrawBtn.
  ///
  /// In en, this message translates to:
  /// **'Withdraw Request'**
  String get withdrawBtn;

  /// No description provided for @keepTripBtn.
  ///
  /// In en, this message translates to:
  /// **'Keep Trip'**
  String get keepTripBtn;

  /// No description provided for @keepRequestBtn.
  ///
  /// In en, this message translates to:
  /// **'Keep Request'**
  String get keepRequestBtn;

  /// No description provided for @cancelError.
  ///
  /// In en, this message translates to:
  /// **'Could not complete this right now. Try again.'**
  String get cancelError;

  /// No description provided for @helpTitle.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpTitle;

  /// No description provided for @helpQ1.
  ///
  /// In en, this message translates to:
  /// **'How does payment work?'**
  String get helpQ1;

  /// No description provided for @helpA1.
  ///
  /// In en, this message translates to:
  /// **'You pay through Mobile Money once a driver accepts your seat request — either the full fare, or a 20% deposit with the rest due before the trip.'**
  String get helpA1;

  /// No description provided for @helpQ2.
  ///
  /// In en, this message translates to:
  /// **'What if my driver cancels?'**
  String get helpQ2;

  /// No description provided for @helpA2.
  ///
  /// In en, this message translates to:
  /// **'You\'ll be notified immediately and can search for another trip in one tap from your booking.'**
  String get helpA2;

  /// No description provided for @helpQ3.
  ///
  /// In en, this message translates to:
  /// **'How do I become a driver?'**
  String get helpQ3;

  /// No description provided for @helpA3.
  ///
  /// In en, this message translates to:
  /// **'Go to Profile → Become a Driver, add your vehicle details and photos, and HolaRide will review and approve it.'**
  String get helpA3;

  /// No description provided for @helpContactNote.
  ///
  /// In en, this message translates to:
  /// **'Direct support contact isn\'t set up yet in this build — add a real support email or phone number here before launch.'**
  String get helpContactNote;

  /// No description provided for @helpEmail.
  ///
  /// In en, this message translates to:
  /// **'Email support'**
  String get helpEmail;

  /// No description provided for @helpCall.
  ///
  /// In en, this message translates to:
  /// **'Call support'**
  String get helpCall;

  /// No description provided for @termsTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms & Privacy Policy'**
  String get termsTitle;

  /// No description provided for @termsBody.
  ///
  /// In en, this message translates to:
  /// **'This screen is a placeholder. Real Terms of Service and a Privacy Policy — ideally reviewed by a lawyer familiar with Cameroonian consumer and data protection law, given this app handles real payments and personal data — need to replace this text before launch.'**
  String get termsBody;

  /// No description provided for @termsNote.
  ///
  /// In en, this message translates to:
  /// **'At minimum, your real policy should cover things like: what data HolaRide collects (phone number, location, payment details), how Mobile Money transactions are handled, the cancellation fee structure, driver vetting and liability, and how a person can request their data be deleted.'**
  String get termsNote;

  /// No description provided for @widgetSeatsLeft.
  ///
  /// In en, this message translates to:
  /// **'seats left'**
  String get widgetSeatsLeft;

  /// No description provided for @welcomeTaglinePrefix.
  ///
  /// In en, this message translates to:
  /// **'Travel between cities,\n'**
  String get welcomeTaglinePrefix;

  /// No description provided for @welcomeTaglineAccent.
  ///
  /// In en, this message translates to:
  /// **'together.'**
  String get welcomeTaglineAccent;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Comfortable, affordable and safe\nrides across Cameroon.'**
  String get welcomeSubtitle;
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
