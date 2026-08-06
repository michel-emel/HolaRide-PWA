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
  /// **'Suggested by HolaRide based on your route and vehicle category — you can adjust it in steps of 500 XAF, between 1 500 and 10 000.'**
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

  /// No description provided for @createTripPriceInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount.'**
  String get createTripPriceInvalid;

  /// No description provided for @createTripPriceOutOfRange.
  ///
  /// In en, this message translates to:
  /// **'Price must be between 1 500 and 10 000 XAF.'**
  String get createTripPriceOutOfRange;

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

  /// No description provided for @liveTripConsentTitle.
  ///
  /// In en, this message translates to:
  /// **'Share your position'**
  String get liveTripConsentTitle;

  /// No description provided for @liveTripConsentBody.
  ///
  /// In en, this message translates to:
  /// **'During this trip, the driver will be able to see your live position. You can turn sharing off anytime from the tracking screen.'**
  String get liveTripConsentBody;

  /// No description provided for @liveTripConsentDecline.
  ///
  /// In en, this message translates to:
  /// **'Follow without sharing'**
  String get liveTripConsentDecline;

  /// No description provided for @liveTripConsentAccept.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get liveTripConsentAccept;

  /// No description provided for @liveTripEndedTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip completed'**
  String get liveTripEndedTitle;

  /// No description provided for @liveTripEndedBody.
  ///
  /// In en, this message translates to:
  /// **'Location sharing was stopped automatically.'**
  String get liveTripEndedBody;

  /// No description provided for @liveTripBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get liveTripBack;

  /// No description provided for @liveTripSharingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sharing your live position'**
  String get liveTripSharingSubtitle;

  /// No description provided for @liveTripFollowingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Following your driver'**
  String get liveTripFollowingSubtitle;

  /// No description provided for @liveTripMeMarker.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get liveTripMeMarker;

  /// No description provided for @liveTripLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get liveTripLive;

  /// No description provided for @liveTripUpdatedAgo.
  ///
  /// In en, this message translates to:
  /// **'Updated {secs}s ago'**
  String liveTripUpdatedAgo(int secs);

  /// No description provided for @liveTripLastSeenAgo.
  ///
  /// In en, this message translates to:
  /// **'Last seen {mins}m ago'**
  String liveTripLastSeenAgo(int mins);

  /// No description provided for @liveTripWaitingSignal.
  ///
  /// In en, this message translates to:
  /// **'Waiting for signal...'**
  String get liveTripWaitingSignal;

  /// No description provided for @liveTripDriverSeesPosition.
  ///
  /// In en, this message translates to:
  /// **'The driver can see your position'**
  String get liveTripDriverSeesPosition;

  /// No description provided for @liveTripSharingOff.
  ///
  /// In en, this message translates to:
  /// **'Sharing off'**
  String get liveTripSharingOff;

  /// No description provided for @liveTripSharingYourPosition.
  ///
  /// In en, this message translates to:
  /// **'You\'re sharing your position'**
  String get liveTripSharingYourPosition;

  /// No description provided for @liveTripNoPassengerYet.
  ///
  /// In en, this message translates to:
  /// **'No passenger position received yet.'**
  String get liveTripNoPassengerYet;

  /// No description provided for @liveTripPassengerVisible.
  ///
  /// In en, this message translates to:
  /// **'{count} passenger visible on the map.'**
  String liveTripPassengerVisible(int count);

  /// No description provided for @liveTripPassengersVisible.
  ///
  /// In en, this message translates to:
  /// **'{count} passengers visible on the map.'**
  String liveTripPassengersVisible(int count);

  /// No description provided for @liveTripRouteLabel.
  ///
  /// In en, this message translates to:
  /// **'{km} km · {mins} min'**
  String liveTripRouteLabel(String km, String mins);

  /// No description provided for @liveTripPermServiceDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled on this device.'**
  String get liveTripPermServiceDisabled;

  /// No description provided for @liveTripPermDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission was denied.'**
  String get liveTripPermDenied;

  /// No description provided for @liveTripPermDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Location permission is permanently denied — enable it in your phone settings.'**
  String get liveTripPermDeniedForever;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingLetsGo.
  ///
  /// In en, this message translates to:
  /// **'Let\'s Go!'**
  String get onboardingLetsGo;

  /// No description provided for @onboardingBrandName.
  ///
  /// In en, this message translates to:
  /// **'HolaRide'**
  String get onboardingBrandName;

  /// No description provided for @onboardingTagline.
  ///
  /// In en, this message translates to:
  /// **'Share the ride. Go further.'**
  String get onboardingTagline;

  /// No description provided for @onboardingPage1TitleLine1.
  ///
  /// In en, this message translates to:
  /// **'Intercity travel,\n'**
  String get onboardingPage1TitleLine1;

  /// No description provided for @onboardingPage1TitleAccent.
  ///
  /// In en, this message translates to:
  /// **'smarter '**
  String get onboardingPage1TitleAccent;

  /// No description provided for @onboardingPage1TitleSuffix.
  ///
  /// In en, this message translates to:
  /// **'together'**
  String get onboardingPage1TitleSuffix;

  /// No description provided for @onboardingPage1Body.
  ///
  /// In en, this message translates to:
  /// **'Book a seat or offer a ride to your\nfavorite cities in Cameroon.\nSafe, affordable and reliable.'**
  String get onboardingPage1Body;

  /// No description provided for @onboardingPage2TitlePrefix.
  ///
  /// In en, this message translates to:
  /// **'Find the right ride\nfor '**
  String get onboardingPage2TitlePrefix;

  /// No description provided for @onboardingPage2TitleAccent.
  ///
  /// In en, this message translates to:
  /// **'your journey'**
  String get onboardingPage2TitleAccent;

  /// No description provided for @onboardingPage2Body.
  ///
  /// In en, this message translates to:
  /// **'Search trips between cities, compare options,\ncheck driver profiles and book your seat\nin just a few taps.'**
  String get onboardingPage2Body;

  /// No description provided for @onboardingPage3TitlePrefix.
  ///
  /// In en, this message translates to:
  /// **'Travel with '**
  String get onboardingPage3TitlePrefix;

  /// No description provided for @onboardingPage3TitleAccent.
  ///
  /// In en, this message translates to:
  /// **'peace\n'**
  String get onboardingPage3TitleAccent;

  /// No description provided for @onboardingPage3TitleSuffix.
  ///
  /// In en, this message translates to:
  /// **'of mind'**
  String get onboardingPage3TitleSuffix;

  /// No description provided for @onboardingPage3Body.
  ///
  /// In en, this message translates to:
  /// **'Live trip tracking, secure payments and\n24/7 support — we\'ve got you covered\nevery step of the way.'**
  String get onboardingPage3Body;

  /// No description provided for @onboardingFeatSafeTitle.
  ///
  /// In en, this message translates to:
  /// **'Safe & Trusted'**
  String get onboardingFeatSafeTitle;

  /// No description provided for @onboardingFeatSafeSub.
  ///
  /// In en, this message translates to:
  /// **'Verified drivers\n& secure payments'**
  String get onboardingFeatSafeSub;

  /// No description provided for @onboardingFeatShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Find or Share'**
  String get onboardingFeatShareTitle;

  /// No description provided for @onboardingFeatShareSub.
  ///
  /// In en, this message translates to:
  /// **'Choose your trip\nor offer seats'**
  String get onboardingFeatShareSub;

  /// No description provided for @onboardingFeatAffordableTitle.
  ///
  /// In en, this message translates to:
  /// **'Affordable'**
  String get onboardingFeatAffordableTitle;

  /// No description provided for @onboardingFeatAffordableSub.
  ///
  /// In en, this message translates to:
  /// **'Better prices\nfor every journey'**
  String get onboardingFeatAffordableSub;

  /// No description provided for @onboardingFeatRoutesTitle.
  ///
  /// In en, this message translates to:
  /// **'Many routes'**
  String get onboardingFeatRoutesTitle;

  /// No description provided for @onboardingFeatRoutesSub.
  ///
  /// In en, this message translates to:
  /// **'Across Cameroon'**
  String get onboardingFeatRoutesSub;

  /// No description provided for @onboardingFeatPricesTitle.
  ///
  /// In en, this message translates to:
  /// **'Great prices'**
  String get onboardingFeatPricesTitle;

  /// No description provided for @onboardingFeatPricesSub.
  ///
  /// In en, this message translates to:
  /// **'No hidden fees'**
  String get onboardingFeatPricesSub;

  /// No description provided for @onboardingFeatBookingTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick booking'**
  String get onboardingFeatBookingTitle;

  /// No description provided for @onboardingFeatBookingSub.
  ///
  /// In en, this message translates to:
  /// **'In a few taps'**
  String get onboardingFeatBookingSub;

  /// No description provided for @onboardingFeatPaymentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Secure Payments'**
  String get onboardingFeatPaymentsTitle;

  /// No description provided for @onboardingFeatPaymentsSub.
  ///
  /// In en, this message translates to:
  /// **'Your money is protected'**
  String get onboardingFeatPaymentsSub;

  /// No description provided for @onboardingFeatTrackingTitle.
  ///
  /// In en, this message translates to:
  /// **'Live Trip Tracking'**
  String get onboardingFeatTrackingTitle;

  /// No description provided for @onboardingFeatTrackingSub.
  ///
  /// In en, this message translates to:
  /// **'Follow your trip in real time'**
  String get onboardingFeatTrackingSub;

  /// No description provided for @onboardingFeatSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'24/7 Support'**
  String get onboardingFeatSupportTitle;

  /// No description provided for @onboardingFeatSupportSub.
  ///
  /// In en, this message translates to:
  /// **'We\'re here to help anytime'**
  String get onboardingFeatSupportSub;

  /// No description provided for @onboardingFooterTagline.
  ///
  /// In en, this message translates to:
  /// **'Building a connected Cameroon, one ride at a time.'**
  String get onboardingFooterTagline;

  /// No description provided for @searchHeroTitlePrefix.
  ///
  /// In en, this message translates to:
  /// **'Find '**
  String get searchHeroTitlePrefix;

  /// No description provided for @searchHeroTitleAccent.
  ///
  /// In en, this message translates to:
  /// **'your ride'**
  String get searchHeroTitleAccent;

  /// No description provided for @searchHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find comfortable rides\nbetween cities.'**
  String get searchHeroSubtitle;

  /// No description provided for @searchQuickRoutesTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Routes'**
  String get searchQuickRoutesTitle;

  /// No description provided for @searchQuickRoutesHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a route to fill your search instantly.'**
  String get searchQuickRoutesHint;

  /// No description provided for @searchTrustPaymentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Secure payments'**
  String get searchTrustPaymentsTitle;

  /// No description provided for @searchTrustPaymentsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your data is protected'**
  String get searchTrustPaymentsSubtitle;

  /// No description provided for @searchTrustCommunityTitle.
  ///
  /// In en, this message translates to:
  /// **'Trusted community'**
  String get searchTrustCommunityTitle;

  /// No description provided for @searchTrustCommunitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Verified drivers'**
  String get searchTrustCommunitySubtitle;

  /// No description provided for @searchTrustSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'24/7 Support'**
  String get searchTrustSupportTitle;

  /// No description provided for @searchTrustSupportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'re here for you'**
  String get searchTrustSupportSubtitle;

  /// No description provided for @searchResultsPassengerSingular.
  ///
  /// In en, this message translates to:
  /// **'passenger'**
  String get searchResultsPassengerSingular;

  /// No description provided for @searchResultsPassengerPlural.
  ///
  /// In en, this message translates to:
  /// **'passengers'**
  String get searchResultsPassengerPlural;

  /// No description provided for @homeJoinPopupBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in to book trips and connect with verified drivers.'**
  String get homeJoinPopupBody;

  /// No description provided for @homeHeroTravelSmarterTitle.
  ///
  /// In en, this message translates to:
  /// **'Travel Smarter,\nSave More'**
  String get homeHeroTravelSmarterTitle;

  /// No description provided for @homeHeroTravelSmarterBody.
  ///
  /// In en, this message translates to:
  /// **'Share the cost with fellow travelers going your way.'**
  String get homeHeroTravelSmarterBody;

  /// No description provided for @homeHeroSafeTitle.
  ///
  /// In en, this message translates to:
  /// **'Safe &\nReliable'**
  String get homeHeroSafeTitle;

  /// No description provided for @homeHeroSafeBody.
  ///
  /// In en, this message translates to:
  /// **'All drivers are verified. Your safety is our priority.'**
  String get homeHeroSafeBody;

  /// No description provided for @homeHeroCameroonTitle.
  ///
  /// In en, this message translates to:
  /// **'Across\nCameroon'**
  String get homeHeroCameroonTitle;

  /// No description provided for @homeHeroCameroonBody.
  ///
  /// In en, this message translates to:
  /// **'Yaoundé, Douala, Bafoussam and more destinations.'**
  String get homeHeroCameroonBody;

  /// No description provided for @homeFindRideSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Search for rides to your destination'**
  String get homeFindRideSubtitle;

  /// No description provided for @homeOfferRide.
  ///
  /// In en, this message translates to:
  /// **'Offer a Ride'**
  String get homeOfferRide;

  /// No description provided for @homeOfferRideSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Post your trip and fill your empty seats'**
  String get homeOfferRideSubtitle;

  /// No description provided for @homeRideTogetherTitle.
  ///
  /// In en, this message translates to:
  /// **'Ride together, save more'**
  String get homeRideTogetherTitle;

  /// No description provided for @homeRideTogetherBody.
  ///
  /// In en, this message translates to:
  /// **'Share your ride, split\nthe fare and reduce cost.'**
  String get homeRideTogetherBody;

  /// No description provided for @homeLearnMore.
  ///
  /// In en, this message translates to:
  /// **'Learn More'**
  String get homeLearnMore;

  /// No description provided for @homeHappyRiders.
  ///
  /// In en, this message translates to:
  /// **'Happy riders\nusing HolaRide'**
  String get homeHappyRiders;

  /// No description provided for @homeTripsAvailableSingular.
  ///
  /// In en, this message translates to:
  /// **'{count} trip available'**
  String homeTripsAvailableSingular(int count);

  /// No description provided for @homeTripsAvailablePlural.
  ///
  /// In en, this message translates to:
  /// **'{count} trips available'**
  String homeTripsAvailablePlural(int count);

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Travel together.\nSave more.'**
  String get splashTagline;

  /// No description provided for @splashTagSafe.
  ///
  /// In en, this message translates to:
  /// **'Safe'**
  String get splashTagSafe;

  /// No description provided for @splashTagAffordable.
  ///
  /// In en, this message translates to:
  /// **'Affordable'**
  String get splashTagAffordable;

  /// No description provided for @splashTagReliable.
  ///
  /// In en, this message translates to:
  /// **'Reliable'**
  String get splashTagReliable;

  /// No description provided for @splashFooter.
  ///
  /// In en, this message translates to:
  /// **'Connecting cities across Cameroon 🇨🇲'**
  String get splashFooter;

  /// No description provided for @paymentChangeNumberTitle.
  ///
  /// In en, this message translates to:
  /// **'Pay with a different number'**
  String get paymentChangeNumberTitle;

  /// No description provided for @paymentChangeNumberBody.
  ///
  /// In en, this message translates to:
  /// **'The Mobile Money prompt will be sent to this number.'**
  String get paymentChangeNumberBody;

  /// No description provided for @paymentChangeNumberHint.
  ///
  /// In en, this message translates to:
  /// **'675 123 456'**
  String get paymentChangeNumberHint;

  /// No description provided for @paymentChangeNumberError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 9-digit number starting with 6.'**
  String get paymentChangeNumberError;

  /// No description provided for @paymentUseThisNumber.
  ///
  /// In en, this message translates to:
  /// **'Use this number'**
  String get paymentUseThisNumber;

  /// No description provided for @paymentUserCancelled.
  ///
  /// In en, this message translates to:
  /// **'You cancelled the payment on your phone.'**
  String get paymentUserCancelled;

  /// No description provided for @paymentFailedGeneric.
  ///
  /// In en, this message translates to:
  /// **'Payment failed. Please try again.'**
  String get paymentFailedGeneric;

  /// No description provided for @paymentProviderUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the payment provider. Try again.'**
  String get paymentProviderUnreachable;

  /// No description provided for @paymentCloseBtn.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get paymentCloseBtn;

  /// No description provided for @payRemainingTitle.
  ///
  /// In en, this message translates to:
  /// **'Pay remaining balance'**
  String get payRemainingTitle;

  /// No description provided for @payRemainingDepositPaid.
  ///
  /// In en, this message translates to:
  /// **'20% deposit paid'**
  String get payRemainingDepositPaid;

  /// No description provided for @payRemainingBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Remaining balance'**
  String get payRemainingBalanceLabel;

  /// No description provided for @payRemainingMomoNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile Money number'**
  String get payRemainingMomoNumber;

  /// No description provided for @payRemainingAutoDetectNote.
  ///
  /// In en, this message translates to:
  /// **'MTN or Orange Money is detected automatically — you\'ll get a USSD prompt on this number.'**
  String get payRemainingAutoDetectNote;

  /// No description provided for @payRemainingCheckPhoneNote.
  ///
  /// In en, this message translates to:
  /// **'Check your phone — confirm the Mobile Money prompt to finish.'**
  String get payRemainingCheckPhoneNote;

  /// No description provided for @payRemainingWaitingLabel.
  ///
  /// In en, this message translates to:
  /// **'Waiting for confirmation...'**
  String get payRemainingWaitingLabel;

  /// No description provided for @payRemainingDevNote.
  ///
  /// In en, this message translates to:
  /// **'Only visible in debug builds. Bypasses real Mobile Money — works only while PAYMENT_DEV_MODE is on in the backend.'**
  String get payRemainingDevNote;

  /// No description provided for @payRemainingSimulateError.
  ///
  /// In en, this message translates to:
  /// **'Could not simulate payment.'**
  String get payRemainingSimulateError;

  /// No description provided for @payRemainingFailedMsg.
  ///
  /// In en, this message translates to:
  /// **'The payment failed. Check your Mobile Money balance and try again.'**
  String get payRemainingFailedMsg;

  /// No description provided for @payRemainingExpiredMsg.
  ///
  /// In en, this message translates to:
  /// **'The payment request expired before you confirmed it. Try again.'**
  String get payRemainingExpiredMsg;

  /// No description provided for @payRemainingStillWaitingMsg.
  ///
  /// In en, this message translates to:
  /// **'Still waiting on confirmation — check your phone, then try again if nothing came through.'**
  String get payRemainingStillWaitingMsg;

  /// No description provided for @payRemainingGenericError.
  ///
  /// In en, this message translates to:
  /// **'Payment could not be completed. Try again.'**
  String get payRemainingGenericError;

  /// No description provided for @tripDetailAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip Details'**
  String get tripDetailAppBarTitle;

  /// No description provided for @tripDetailLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this trip.'**
  String get tripDetailLoadError;

  /// No description provided for @tripDetailTotalPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Total price (1 seat)'**
  String get tripDetailTotalPriceLabel;

  /// No description provided for @tripDetailNoHiddenFees.
  ///
  /// In en, this message translates to:
  /// **'No hidden fees'**
  String get tripDetailNoHiddenFees;

  /// No description provided for @tripDetailSecureBooking.
  ///
  /// In en, this message translates to:
  /// **'Secure booking'**
  String get tripDetailSecureBooking;

  /// No description provided for @tripDetailVerifiedTrip.
  ///
  /// In en, this message translates to:
  /// **'Verified Trip'**
  String get tripDetailVerifiedTrip;

  /// No description provided for @tripDetailSafeReliableTrusted.
  ///
  /// In en, this message translates to:
  /// **'Safe • Reliable • Trusted'**
  String get tripDetailSafeReliableTrusted;

  /// No description provided for @tripDetailDepartureTag.
  ///
  /// In en, this message translates to:
  /// **'Departure'**
  String get tripDetailDepartureTag;

  /// No description provided for @tripDetailArrivalTag.
  ///
  /// In en, this message translates to:
  /// **'Arrival'**
  String get tripDetailArrivalTag;

  /// No description provided for @tripDetailPromoTitle.
  ///
  /// In en, this message translates to:
  /// **'Affordable, safe and reliable travel'**
  String get tripDetailPromoTitle;

  /// No description provided for @tripDetailPromoBody.
  ///
  /// In en, this message translates to:
  /// **'Book with confidence and enjoy your journey.'**
  String get tripDetailPromoBody;

  /// No description provided for @tripDetailSeatsLeftSingular.
  ///
  /// In en, this message translates to:
  /// **'{count} seat left'**
  String tripDetailSeatsLeftSingular(int count);

  /// No description provided for @tripDetailSeatsLeftPlural.
  ///
  /// In en, this message translates to:
  /// **'{count} seats left'**
  String tripDetailSeatsLeftPlural(int count);

  /// No description provided for @tripDetailLuggageLabel.
  ///
  /// In en, this message translates to:
  /// **'Luggage'**
  String get tripDetailLuggageLabel;

  /// No description provided for @tripDetailLuggageValue.
  ///
  /// In en, this message translates to:
  /// **'1 bag per passenger'**
  String get tripDetailLuggageValue;

  /// No description provided for @tripDetailVerifiedDriverBadge.
  ///
  /// In en, this message translates to:
  /// **'Verified driver'**
  String get tripDetailVerifiedDriverBadge;

  /// No description provided for @tripDetailIdVerified.
  ///
  /// In en, this message translates to:
  /// **'ID Verified'**
  String get tripDetailIdVerified;

  /// No description provided for @tripDetailPhoneVerified.
  ///
  /// In en, this message translates to:
  /// **'Phone Verified'**
  String get tripDetailPhoneVerified;

  /// No description provided for @tripDetailBackgroundChecked.
  ///
  /// In en, this message translates to:
  /// **'Background Checked'**
  String get tripDetailBackgroundChecked;

  /// No description provided for @tripDetailTripsCompleted.
  ///
  /// In en, this message translates to:
  /// **'{count} Trips completed'**
  String tripDetailTripsCompleted(int count);

  /// No description provided for @tripDetailReviewCountBare.
  ///
  /// In en, this message translates to:
  /// **'{count} review'**
  String tripDetailReviewCountBare(int count);

  /// No description provided for @tripDetailReviewCountBarePlural.
  ///
  /// In en, this message translates to:
  /// **'{count} reviews'**
  String tripDetailReviewCountBarePlural(int count);

  /// No description provided for @tripDetailDriverProfileSoon.
  ///
  /// In en, this message translates to:
  /// **'Driver profile coming soon'**
  String get tripDetailDriverProfileSoon;

  /// No description provided for @tripDetailKnowMoreDriver.
  ///
  /// In en, this message translates to:
  /// **'Know more about the driver'**
  String get tripDetailKnowMoreDriver;

  /// No description provided for @safetyPriorityTitle.
  ///
  /// In en, this message translates to:
  /// **'Your safety is our priority'**
  String get safetyPriorityTitle;

  /// No description provided for @safetyPriorityBody.
  ///
  /// In en, this message translates to:
  /// **'SOS, live location sharing and in-app chat available.'**
  String get safetyPriorityBody;

  /// No description provided for @learnMore.
  ///
  /// In en, this message translates to:
  /// **'Learn more'**
  String get learnMore;

  /// No description provided for @bookingRequestSafeSecureTrusted.
  ///
  /// In en, this message translates to:
  /// **'Safe · Secure · Trusted'**
  String get bookingRequestSafeSecureTrusted;

  /// No description provided for @bookingRequestSeatsQuestion.
  ///
  /// In en, this message translates to:
  /// **'How many seats do you need?'**
  String get bookingRequestSeatsQuestion;

  /// No description provided for @bookingRequestSentHeading.
  ///
  /// In en, this message translates to:
  /// **'Your request will be sent to the driver'**
  String get bookingRequestSentHeading;

  /// No description provided for @bookingRequestNotPayingYet.
  ///
  /// In en, this message translates to:
  /// **'You\'re not paying yet'**
  String get bookingRequestNotPayingYet;

  /// No description provided for @bookingRequestSentBody.
  ///
  /// In en, this message translates to:
  /// **'Your request will be sent to the driver. You\'ll only pay after the driver accepts your request.'**
  String get bookingRequestSentBody;

  /// No description provided for @bookingRequestPayFullSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pay {amount} now.'**
  String bookingRequestPayFullSubtitle(String amount);

  /// No description provided for @bookingRequestPayBalanceTag.
  ///
  /// In en, this message translates to:
  /// **'Pay balance before trip'**
  String get bookingRequestPayBalanceTag;

  /// No description provided for @bookingRequestTotalToPay.
  ///
  /// In en, this message translates to:
  /// **'Total to pay'**
  String get bookingRequestTotalToPay;

  /// No description provided for @bookingRequestPaidAfterAccept.
  ///
  /// In en, this message translates to:
  /// **'(paid after driver accepts)'**
  String get bookingRequestPaidAfterAccept;

  /// No description provided for @cancellationWindowNote.
  ///
  /// In en, this message translates to:
  /// **'You can cancel for free up to 2 hours before departure.'**
  String get cancellationWindowNote;

  /// No description provided for @bookingRequestSendButton.
  ///
  /// In en, this message translates to:
  /// **'Send Request to Driver'**
  String get bookingRequestSendButton;

  /// No description provided for @bookingRequestSendSubtext.
  ///
  /// In en, this message translates to:
  /// **'Driver must accept before booking is confirmed'**
  String get bookingRequestSendSubtext;

  /// No description provided for @bookingRequestSendError.
  ///
  /// In en, this message translates to:
  /// **'Could not send your request. Try again.'**
  String get bookingRequestSendError;

  /// No description provided for @waitingWhatsNext.
  ///
  /// In en, this message translates to:
  /// **'What happens next?'**
  String get waitingWhatsNext;

  /// No description provided for @waitingStepRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get waitingStepRequestSent;

  /// No description provided for @waitingStepDriverNotified.
  ///
  /// In en, this message translates to:
  /// **'Driver notified'**
  String get waitingStepDriverNotified;

  /// No description provided for @waitingStepDriverResponds.
  ///
  /// In en, this message translates to:
  /// **'Driver responds'**
  String get waitingStepDriverResponds;

  /// No description provided for @waitingNotifyHeading.
  ///
  /// In en, this message translates to:
  /// **'We\'ll notify you immediately'**
  String get waitingNotifyHeading;

  /// No description provided for @waitingNotifyBody.
  ///
  /// In en, this message translates to:
  /// **'You can continue using the app.\nWe\'ll let you know as soon as the driver accepts.'**
  String get waitingNotifyBody;

  /// No description provided for @waitingGoHomeButton.
  ///
  /// In en, this message translates to:
  /// **'Go Home'**
  String get waitingGoHomeButton;

  /// No description provided for @orDivider.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orDivider;

  /// No description provided for @waitingResponseTimeBanner.
  ///
  /// In en, this message translates to:
  /// **'Most drivers respond within 5–10 minutes.'**
  String get waitingResponseTimeBanner;

  /// No description provided for @chatHideChatBody.
  ///
  /// In en, this message translates to:
  /// **'This removes it from your own list only — the other side keeps their conversation as normal. If a new message comes in later, it\'ll reappear in your list.'**
  String get chatHideChatBody;

  /// No description provided for @chatHideChatError.
  ///
  /// In en, this message translates to:
  /// **'Could not delete this chat. Try again.'**
  String get chatHideChatError;

  /// No description provided for @driverFlowLoginReason.
  ///
  /// In en, this message translates to:
  /// **'Log in to publish a trip as a driver.'**
  String get driverFlowLoginReason;

  /// No description provided for @payoutRowLabel.
  ///
  /// In en, this message translates to:
  /// **'Payout'**
  String get payoutRowLabel;

  /// No description provided for @tripMgmtStartTitle.
  ///
  /// In en, this message translates to:
  /// **'Start this trip?'**
  String get tripMgmtStartTitle;

  /// No description provided for @tripMgmtStartBody.
  ///
  /// In en, this message translates to:
  /// **'The trip will be marked as ongoing. Your paid passengers will be able to follow your live position until you mark it completed.'**
  String get tripMgmtStartBody;

  /// No description provided for @tripMgmtNotYet.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get tripMgmtNotYet;

  /// No description provided for @tripMgmtStartBtn.
  ///
  /// In en, this message translates to:
  /// **'Start Trip'**
  String get tripMgmtStartBtn;

  /// No description provided for @tripMgmtStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting...'**
  String get tripMgmtStarting;

  /// No description provided for @tripMgmtStartedMsg.
  ///
  /// In en, this message translates to:
  /// **'Trip started — passengers can now follow you.'**
  String get tripMgmtStartedMsg;

  /// No description provided for @tripMgmtStartError.
  ///
  /// In en, this message translates to:
  /// **'Could not start the trip. Try again.'**
  String get tripMgmtStartError;

  /// No description provided for @tripMgmtInProgressBanner.
  ///
  /// In en, this message translates to:
  /// **'Trip in progress — tap to open the live map.'**
  String get tripMgmtInProgressBanner;

  /// No description provided for @tripMgmtAcceptTooltip.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get tripMgmtAcceptTooltip;

  /// No description provided for @tripMgmtRejectTooltip.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get tripMgmtRejectTooltip;

  /// No description provided for @tripMgmtNoShowFallbackName.
  ///
  /// In en, this message translates to:
  /// **'this passenger'**
  String get tripMgmtNoShowFallbackName;

  /// No description provided for @tripMgmtDoneFallback.
  ///
  /// In en, this message translates to:
  /// **'Done.'**
  String get tripMgmtDoneFallback;
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
