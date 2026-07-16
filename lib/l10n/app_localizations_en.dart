// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get tryAgain => 'Try again';

  @override
  String get delete => 'Delete';

  @override
  String get optional => '(optional)';

  @override
  String get yourDataSafe => 'Your data is safe with us';

  @override
  String get tabHome => 'Home';

  @override
  String get tabRoute => 'Route';

  @override
  String get tabLogin => 'Login';

  @override
  String get tabMyTrips => 'My Trips';

  @override
  String get tabChat => 'Chat';

  @override
  String get tabProfile => 'Profile';

  @override
  String get welcomeTagline => 'Travel between cities,\ntogether.';

  @override
  String get welcomeCreateAccount => 'Create an account';

  @override
  String get welcomeSignIn => 'Sign in';

  @override
  String get registerTitle => 'Create your account';

  @override
  String get registerSubtitle =>
      'Enter your name and phone number to get started.';

  @override
  String get registerFirstName => 'First name *';

  @override
  String get registerFirstNameHint => 'e.g. Michel';

  @override
  String get registerLastName => 'Last name';

  @override
  String get registerLastNameHint => 'e.g. Dupont';

  @override
  String get registerPhoneNumber => 'Phone number *';

  @override
  String get registerContinue => 'Continue';

  @override
  String get registerTermsPrefix => 'By continuing, you agree to our ';

  @override
  String get registerTermsLink => 'Terms and Privacy Policy.';

  @override
  String get registerAlreadyHaveAccount => 'Already have an account? ';

  @override
  String get registerErrorFirstName => 'Please enter your first name.';

  @override
  String get registerErrorPhone =>
      'Enter a valid 9-digit Cameroon mobile number.';

  @override
  String get registerErrorServer =>
      'Could not reach the server. Check your connection and try again.';

  @override
  String get registerAccountExistsTitle => 'Account exists';

  @override
  String get registerAccountExistsBody =>
      'An account already exists for this number.\n\nPlease sign in instead.';

  @override
  String get loginTitle => 'Sign in';

  @override
  String get loginSubtitle => 'Enter your phone number to sign in.';

  @override
  String get loginPhoneHint => '6 75 12 34 56';

  @override
  String get loginSendCode => 'Send code';

  @override
  String get loginNoAccountLink => 'Don\'t have an account? Create one';

  @override
  String get loginNoAccountTitle => 'No account found';

  @override
  String get loginNoAccountBody =>
      'No account exists for this number.\n\nPlease create an account first.';

  @override
  String get loginErrorPhone => 'Enter a valid 9-digit Cameroon number.';

  @override
  String get loginErrorServer => 'Could not reach the server. Try again.';

  @override
  String get otpSignInTitle => 'Sign in to HolaRide';

  @override
  String get otpVerifyTitle => 'Verify your number';

  @override
  String get otpSentTo => 'We sent a 6-digit code to ';

  @override
  String get otpWrongNumber => 'Wrong number? Go back';

  @override
  String otpDevMode(String code) {
    return 'DEV MODE — your code is $code';
  }

  @override
  String get otpVerifying => 'Verifying…';

  @override
  String otpResendIn(String countdown) {
    return 'Resend code in $countdown';
  }

  @override
  String get otpResend => 'Resend code';

  @override
  String get otpResending => 'Resending…';

  @override
  String get otpErrorVerify =>
      'Verification failed. Check the code and try again.';

  @override
  String get otpErrorResend => 'Could not resend the code. Try again.';

  @override
  String get otpAccountExistsTitle => 'Account exists';

  @override
  String get otpAccountExistsBody =>
      'An account already exists for this number.\n\nPlease sign in instead.';

  @override
  String get otpNoAccountTitle => 'No account found';

  @override
  String get otpNoAccountBody =>
      'No account found for this number.\n\nPlease create an account first.';

  @override
  String get otpCreateAccount => 'Create an account';

  @override
  String get nameEntryTitle => 'What should\nwe call you?';

  @override
  String get nameEntrySubtitle => 'This will be visible on your profile';

  @override
  String get nameEntryHint => 'e.g. Michel Kamga';

  @override
  String get nameEntryError => 'Tell us what to call you.';

  @override
  String get nameEntrySaveError => 'Could not save your name. Try again.';

  @override
  String get homeGetStarted => 'Get Started';

  @override
  String get homeMaybeLater => 'Maybe later';

  @override
  String get homeJoinTitle => 'Join HolaRide';

  @override
  String get homeJoinBody =>
      'Create an account to book trips, chat with drivers, and travel safely across cities.';

  @override
  String get homeHeroTitle => 'Rides Going Your Way';

  @override
  String get homeHeroBody =>
      'HolaRide connects you with verified drivers making the same intercity trip.';

  @override
  String get homeFindRide => 'Find a Ride';

  @override
  String get homeRideShare => 'Ride Share';

  @override
  String get homeAvailableTrips => 'Available trips';

  @override
  String get homeSeeAll => 'See all';

  @override
  String get homeNoTrips => 'No trips available right now';

  @override
  String get homeNoTripsHint => 'Try a different route or check again later.';

  @override
  String get homeExploreRoutes => 'Explore popular routes';

  @override
  String get homeShareRideTitle => 'Share your ride, reduce cost';

  @override
  String get homeShareRideBody => 'Split your fare and travel together.';

  @override
  String get homeRiderCount => 'Riders using the app';

  @override
  String get homeTripHours => 'Trip hours completed';

  @override
  String homeHelloName(String name) {
    return 'Hello $name 👋';
  }

  @override
  String get homeHello => 'Hello 👋';

  @override
  String get homePerSeat => 'per seat';

  @override
  String homeSeatsLeft(int count) {
    return '$count left';
  }

  @override
  String get homeLoadError => 'Couldn\'t load nearby trips.';

  @override
  String get searchTitle => 'Find a trip';

  @override
  String get searchFrom => 'Leaving from';

  @override
  String get searchTo => 'Going to';

  @override
  String get searchDate => 'Departure date';

  @override
  String get searchChange => 'Change';

  @override
  String searchToday(int day, String month) {
    return 'Today, $day $month';
  }

  @override
  String searchTomorrow(int day, String month) {
    return 'Tomorrow, $day $month';
  }

  @override
  String get searchButton => 'Search trips';

  @override
  String get searchErrorRoute =>
      'Please select both departure and destination.';

  @override
  String get searchErrorSameCity =>
      'Departure and destination must be different cities.';

  @override
  String get searchCityFrom => 'City or pickup point';

  @override
  String get searchCityTo => 'City or drop-off point';

  @override
  String get searchPickerHint => 'Search city or pickup point';

  @override
  String get searchPopularCities => 'Popular cities';

  @override
  String get searchNoMatch => 'No matching locations.';

  @override
  String get searchSortTime => 'Sort by time';

  @override
  String get searchSortPrice => 'Sort by price';

  @override
  String get searchTimeLabel => 'Time';

  @override
  String get searchPriceLabel => 'Price';

  @override
  String get searchNoResults =>
      'No trips on this route and date yet. Try another date, or be among our first riders to request it.';

  @override
  String get searchLoadError => 'Couldn\'t load trips. Pull down to try again.';

  @override
  String get bookingsTitle => 'My Trips';

  @override
  String get bookingsAll => 'All';

  @override
  String get bookingsUpcoming => 'Upcoming';

  @override
  String get bookingsPast => 'Past';

  @override
  String get bookingsLoginPrompt => 'Log in to see your bookings';

  @override
  String get bookingsLoginHint =>
      'Your trip requests and booking history will show up here once you log in.';

  @override
  String get bookingsLoginSignup => 'Log in / Sign up';

  @override
  String get bookingsEmpty => 'No bookings here yet.';

  @override
  String get bookingsLoadError => 'Couldn\'t load your bookings.';

  @override
  String get bookingsTripFallback => 'Trip';

  @override
  String get bookingsChat => 'Chat';

  @override
  String get bookingsTrack => 'Track';

  @override
  String bookingsRatePassenger(String name) {
    return 'Rate $name';
  }

  @override
  String bookingsSeatSingular(int count) {
    return '$count seat';
  }

  @override
  String bookingsSeatPlural(int count) {
    return '$count seats';
  }

  @override
  String get bookingStatusWaiting => 'Waiting';

  @override
  String get bookingStatusAwaitingPayment => 'Awaiting payment';

  @override
  String get bookingStatusPaid => 'Paid';

  @override
  String get bookingStatusDeclined => 'Declined';

  @override
  String get bookingStatusCancelled => 'Cancelled';

  @override
  String get bookingStatusCompleted => 'Completed';

  @override
  String get bookingStatusNoShow => 'No-show';

  @override
  String get bookingStatusUnknown => 'Unknown';

  @override
  String get chatInboxTitle => 'Chat';

  @override
  String get chatInboxEmpty => 'No chats yet';

  @override
  String get chatInboxEmptyHint =>
      'Chats open automatically once a booking is paid, or for any trip you publish.';

  @override
  String get chatInboxDeleteTitle => 'Delete chat?';

  @override
  String get chatInboxDeleteBody =>
      'This removes the chat from your list. The trip and your booking are not affected.';

  @override
  String get chatInboxDelete => 'Delete';

  @override
  String get chatInboxDriver => 'Driver';

  @override
  String get chatInboxPassenger => 'Passenger';

  @override
  String get chatTripTitle => 'Trip chat';

  @override
  String get chatDeleteChat => 'Delete chat';

  @override
  String get chatNoMessages => 'No messages yet — say hello!';

  @override
  String get chatDeletedByYou => 'You deleted this message';

  @override
  String get chatDeleted => 'This message was deleted';

  @override
  String get chatSharedLocation => 'Shared location · Tap to open';

  @override
  String get chatTypePlaceholder => 'Type a message...';

  @override
  String get chatShareLocation => 'Share location';

  @override
  String get chatReadOnlyCancelled => 'Trip cancelled — chat is now read-only.';

  @override
  String get chatReadOnlyCompleted => 'Trip completed — chat is now read-only.';

  @override
  String get chatSendError => 'Message didn\'t send. Try again.';

  @override
  String get chatLocationError =>
      'Could not get your location. Check permissions and try again.';

  @override
  String get chatMapsError =>
      'Could not open maps. Make sure Google Maps (or a browser) is installed.';

  @override
  String get chatDeleteMsgTitle => 'Delete this message?';

  @override
  String get chatDeleteMsgBody =>
      'This only deletes it for everyone in this chat — it can\'t be undone.';

  @override
  String get chatDeleteMsgError => 'Could not delete this message. Try again.';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsMarkRead => 'Mark all read';

  @override
  String get notificationsEmpty => 'No notifications yet';

  @override
  String get notificationsEmptyHint =>
      'You\'ll see updates here when something happens.';

  @override
  String get notificationsJustNow => 'Just now';

  @override
  String notificationsMinsAgo(int n) {
    return '${n}m ago';
  }

  @override
  String notificationsHoursAgo(int n) {
    return '${n}h ago';
  }

  @override
  String get notificationsYesterday => 'Yesterday';

  @override
  String notificationsDaysAgo(int n) {
    return '${n}d ago';
  }

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileGuestTitle => 'You\'re browsing as a guest';

  @override
  String get profileGuestBody =>
      'Log in or sign up to book trips, publish rides, and manage your account.';

  @override
  String get profileLoginSignup => 'Log in / Sign up';

  @override
  String get profileAccount => 'Account';

  @override
  String get profileBecomeDriver => 'Become a Driver';

  @override
  String get profileMyVehicle => 'My Vehicle';

  @override
  String get profileSwitchToDriver => 'Switch to Driver';

  @override
  String get profileSwitchToPassenger => 'Switch to Passenger';

  @override
  String get profilePayoutHistory => 'Payout History';

  @override
  String get profileSupport => 'Support';

  @override
  String get profileHelpSupport => 'Help & Support';

  @override
  String get profileTermsPrivacy => 'Terms & Privacy Policy';

  @override
  String get profileLogout => 'Log out';

  @override
  String get profileLogoutTitle => 'Log out?';

  @override
  String get profileLogoutBody =>
      'You\'ll need to verify your phone number again to log back in.';

  @override
  String get profileVersion => 'HolaRide v1.0.0';

  @override
  String get profileLanguage => 'Language';

  @override
  String get editProfileTitle => 'Edit profile';

  @override
  String get editProfileName => 'Name';

  @override
  String get editProfileNameHint => 'Your name';

  @override
  String get editProfilePhone => 'Phone number';

  @override
  String get editProfileSave => 'Save changes';

  @override
  String get editProfileErrorName => 'Enter a name.';

  @override
  String get editProfileSaveError => 'Could not save your changes. Try again.';

  @override
  String get driverMyTripsUpcoming => 'Upcoming';

  @override
  String get driverMyTripsPast => 'Past';

  @override
  String get driverMyTripsCreate => 'Create a New Trip';

  @override
  String get driverMyTripsEmpty => 'No trips here yet.';

  @override
  String driverRatePassengers(int count) {
    return 'Rate $count passengers';
  }

  @override
  String driverRateOne(String name) {
    return 'Rate $name';
  }

  @override
  String get tripMgmtCancelTitle => 'Cancel this trip?';

  @override
  String get tripMgmtCancelBody =>
      'Every passenger who already paid will be notified and refunded per your cancellation policy.';

  @override
  String get tripMgmtCancelled => 'Trip cancelled.';

  @override
  String get tripMgmtCompleteTitle => 'Mark trip as completed?';

  @override
  String get tripMgmtCompleteBody =>
      'This closes the trip out once everyone has arrived.';

  @override
  String get tripMgmtCompleted => 'Trip marked as completed!';

  @override
  String get tripMgmtNoShowTitle => 'Who didn\'t show up?';

  @override
  String tripMgmtNoShowBody(String name) {
    return 'Mark $name as no-show?';
  }

  @override
  String get tripMgmtNoShowDetail =>
      'This affects their record and may apply a fee per your policy.';

  @override
  String tripMgmtRequests(int count) {
    return 'Requests ($count)';
  }

  @override
  String tripMgmtBookings(int count) {
    return 'Bookings ($count)';
  }

  @override
  String get tripMgmtActions => 'Trip actions';

  @override
  String get tripMgmtNoRequests => 'No new requests.';

  @override
  String get tripMgmtNoPassengers => 'No confirmed passengers yet.';

  @override
  String get tripMgmtActingOn => 'Acting on this trip';

  @override
  String get tripMgmtMarkComplete => 'Mark Completed';

  @override
  String get tripMgmtMarkNoShow => 'Mark No-show';

  @override
  String get tripMgmtCancelBtn => 'Cancel Trip';

  @override
  String get tripMgmtLoadError => 'Couldn\'t load requests for this trip.';

  @override
  String get tripMgmtAcceptError => 'Could not accept this request.';

  @override
  String get tripMgmtRejectError => 'Could not reject this request.';

  @override
  String get tripMgmtGenericError => 'Something went wrong. Try again.';

  @override
  String get createTripTitle => 'Create a trip';

  @override
  String get createTripFrom => 'From';

  @override
  String get createTripTo => 'To';

  @override
  String get createTripDate => 'Date';

  @override
  String get createTripDeparture => 'Departure time';

  @override
  String get createTripSeats => 'Available seats';

  @override
  String createTripSeatsHint(int max) {
    return 'Up to $max — your vehicle\'s registered capacity';
  }

  @override
  String get createTripPrice => 'Price per seat';

  @override
  String get createTripPriceHint => 'Pick \"From\" and \"To\" to see the price';

  @override
  String get createTripPriceNote =>
      'Set by HolaRide based on your route and vehicle category — drivers don\'t set prices.';

  @override
  String get createTripPublish => 'Publish Trip';

  @override
  String get createTripSelectLocation => 'Select location';

  @override
  String get createTripLocationHint =>
      'Choose where you\'re leaving from and going to.';

  @override
  String get createTripNoVehicle =>
      'No approved vehicle found on your account — check My Vehicle in Profile.';

  @override
  String get createTripNoPriceError => 'Couldn\'t load a price for this route.';

  @override
  String get createTripPublishError =>
      'Could not publish this trip. Try again.';

  @override
  String get createTripLeavingFrom => 'Leaving from';

  @override
  String get createTripGoingTo => 'Going to';

  @override
  String get vehicleRegTitle => 'Add your vehicle';

  @override
  String get vehicleRegSubtitle =>
      'Tell us about your car — this is what gets reviewed before you can publish trips.';

  @override
  String get vehicleRegDetails => 'Vehicle details';

  @override
  String get vehicleRegBrand => 'Brand';

  @override
  String get vehicleRegModel => 'Model';

  @override
  String get vehicleRegYear => 'Year (optional)';

  @override
  String get vehicleRegColor => 'Color (optional)';

  @override
  String get vehicleRegPlate => 'License plate';

  @override
  String get vehicleRegSeats => 'Total seats';

  @override
  String get vehicleRegSubmit => 'Submit for Review';

  @override
  String get vehicleRegValidationError =>
      'Fill in brand, model, plate number, and seats.';

  @override
  String get vehicleRegSubmitError =>
      'Could not submit your vehicle. Try again.';

  @override
  String get vehicleRegBrandHint => 'e.g. Toyota';

  @override
  String get vehicleRegModelHint => 'e.g. Corolla';

  @override
  String get vehicleRegYearHint => 'e.g. 2018';

  @override
  String get vehicleRegColorHint => 'e.g. Silver';

  @override
  String get vehicleRegPlateHint => 'e.g. CMR-123-AA';

  @override
  String get vehicleStatusNoVehicle => 'You haven\'t added a vehicle yet.';

  @override
  String get vehicleStatusAdd => 'Add your vehicle';

  @override
  String get vehicleStatusPhotos => 'Photos';

  @override
  String get vehicleStatusAddPhotos => 'Add Photos';

  @override
  String get vehicleStatusUploading => 'Uploading...';

  @override
  String get vehicleStatusNoPhotos =>
      'No photos yet — add a few so passengers recognize your car.';

  @override
  String get vehicleStatusPhotoError =>
      'Some photos didn\'t upload. Try again.';

  @override
  String get vehicleStatusFirstTrip => 'Create your first trip';

  @override
  String get vehicleStatusStatusLabel => 'Status';

  @override
  String get vehicleStatusPending =>
      'We are verifying your documents and vehicle. You\'ll be notified once it\'s approved.';

  @override
  String get vehicleStatusApproved =>
      'Your vehicle is approved — you can publish trips now.';

  @override
  String get vehicleStatusRejected =>
      'Your submission was rejected. Contact support for details, or submit a new vehicle.';

  @override
  String get vehicleStatusUnavailable => 'Status unavailable right now.';

  @override
  String get vehicleStatusLoadError => 'Couldn\'t load your vehicle status.';

  @override
  String get payoutTitle => 'Payout history';

  @override
  String get payoutTotal => 'Total paid out';

  @override
  String get payoutNote =>
      'Sent automatically to your Mobile Money after each completed trip.';

  @override
  String get payoutHistory => 'History';

  @override
  String get payoutEmpty => 'No payouts yet.';

  @override
  String get payoutPaid => 'Paid';

  @override
  String get payoutPending => 'Pending';

  @override
  String get payoutLoadError => 'Couldn\'t load your payouts.';

  @override
  String get tripDetailBook => 'Book a Seat';

  @override
  String get tripDetailNoSeats => 'No seats left';

  @override
  String get tripDetailNoReviews => 'No driver reviews yet';

  @override
  String get tripDetailReview => 'review';

  @override
  String get tripDetailReviews => 'reviews for this driver';

  @override
  String get tripDetailVehicleCategory => 'Vehicle category';

  @override
  String get tripDetailSeat => 'seat';

  @override
  String get tripDetailSeatsAvailable => 'seats available';

  @override
  String get bookingRequestTitle => 'Request a Seat';

  @override
  String get bookingRequestStep => 'Step 1 of 2';

  @override
  String get bookingRequestSeats => 'Seats';

  @override
  String get bookingRequestPayment => 'Payment option';

  @override
  String get bookingRequestPayFull => 'Pay Full';

  @override
  String get bookingRequestPayDeposit => 'Pay 80% Deposit';

  @override
  String bookingRequestDepositHint(String deposit, String remaining) {
    return 'Pay $deposit now, $remaining before trip';
  }

  @override
  String get bookingRequestDueNow => 'Due now';

  @override
  String get bookingRequestTotal => 'Total';

  @override
  String get bookingRequestRemaining => 'Remaining before trip';

  @override
  String get bookingRequestContinue => 'Continue';

  @override
  String get bookingRequestDeparture => 'Departure point';

  @override
  String get bookingRequestDropoff => 'Drop-off point';

  @override
  String bookingRequestSeatsAvailable(int count) {
    return '$count seats available';
  }

  @override
  String get waitingTitle => 'Waiting for the driver';

  @override
  String get waitingBody =>
      'We\'ve sent your request to the driver.\nYou\'ll be notified here as soon as they respond.';

  @override
  String get waitingDeclinedTitle => 'Request declined';

  @override
  String get waitingDeclinedBody =>
      'The driver wasn\'t able to accept your request this time. You can search for another trip.';

  @override
  String get waitingBackHome => 'Back to Home';

  @override
  String get waitingNote =>
      'This request can take time. We\'ll notify you immediately.';

  @override
  String get waitingWithdraw => 'Withdraw request';

  @override
  String get waitingSeatsRequested => 'Seats requested';

  @override
  String get waitingPricePerSeat => 'Price per seat';

  @override
  String get rateTripTitle => 'Rate this trip';

  @override
  String get rateTripDriverQuestion => 'How was your trip?';

  @override
  String get rateTripPassengerQuestion =>
      'How was each passenger on this trip?';

  @override
  String get rateTripNote =>
      'Your rating helps keep HolaRide trustworthy for everyone.';

  @override
  String get rateTripThanksDriver => 'Thanks — you\'ve rated your driver.';

  @override
  String rateTripThanksPassenger(String name) {
    return 'Thanks — you\'ve rated $name.';
  }

  @override
  String get rateTripYourDriver => 'Your driver';

  @override
  String get rateTripStarError => 'Tap a star rating first.';

  @override
  String get rateTripSubmitError => 'Could not submit this rating. Try again.';

  @override
  String get rateTripDriverComment => 'Anything about the ride? (optional)';

  @override
  String get rateTripPassengerComment =>
      'Anything about this passenger? (optional)';

  @override
  String get rateTripSubmit => 'Submit rating';

  @override
  String get paymentTitle => 'Payment';

  @override
  String get paymentAutoDetected => 'Auto-detected from your number';

  @override
  String get paymentAmountDue => 'Amount due';

  @override
  String get paymentFees => 'Fees: 2% included';

  @override
  String get paymentPhone => 'Phone';

  @override
  String paymentPrompt(String operator, String phone) {
    return 'You\'ll receive a $operator prompt on $phone. Confirm to complete the payment.';
  }

  @override
  String paymentPay(String amount) {
    return 'Pay $amount';
  }

  @override
  String get paymentSimulate => 'Simulate (dev only)';

  @override
  String get paymentConnecting => 'Connecting to Mobile Money...';

  @override
  String get paymentPleaseWait => 'Please wait';

  @override
  String get paymentCheckPhone => 'Check your phone';

  @override
  String paymentSentTo(String operator, String phone) {
    return 'A $operator payment request was sent to\n$phone';
  }

  @override
  String get paymentToConfirm => 'to confirm';

  @override
  String paymentOpenApp(String operator) {
    return 'Open $operator on your phone';
  }

  @override
  String paymentOrDial(String ussd) {
    return 'or dial $ussd to approve the request';
  }

  @override
  String get paymentCancelBtn => 'Cancel payment';

  @override
  String get paymentConfirmed => 'Payment confirmed!';

  @override
  String get paymentSeatsSecured =>
      'Your seat is secured.\nThe driver has been notified.';

  @override
  String get paymentBackHome => 'Back to Home';

  @override
  String get paymentFailed => 'Payment failed';

  @override
  String get paymentInsufficientBalance => 'Insufficient Balance';

  @override
  String paymentInsufficientMsg(String operator, String amount) {
    return 'Your $operator balance is too low for $amount.';
  }

  @override
  String paymentTopUp(String operator) {
    return 'Top up $operator';
  }

  @override
  String paymentDial(String ussd) {
    return 'Dial $ussd on your phone, then retry.';
  }

  @override
  String get paymentTryAgain => 'Try again';

  @override
  String get paymentGoHome => 'Go back to Home';

  @override
  String get paymentTimeout => 'Payment timed out. Please try again.';

  @override
  String get rebookTitle => 'Trip cancelled';

  @override
  String get rebookBody =>
      'The driver has cancelled this trip.\nWould you like to find another trip?';

  @override
  String get rebookOriginal => 'Original trip';

  @override
  String get rebookFind => 'Find Another Trip';

  @override
  String get rebookGoBookings => 'Go to My Bookings';

  @override
  String get cancelTripTitle => 'Cancel this trip?';

  @override
  String get cancelTripBody =>
      'Are you sure you want to cancel this trip? Depending on how close it is to departure, a cancellation fee may apply. This action cannot be undone.';

  @override
  String get withdrawTitle => 'Cancel this request?';

  @override
  String get withdrawBody =>
      'Are you sure you want to withdraw this request? This action cannot be undone.';

  @override
  String get cancelTripBtn => 'Cancel Trip';

  @override
  String get withdrawBtn => 'Withdraw Request';

  @override
  String get keepTripBtn => 'Keep Trip';

  @override
  String get keepRequestBtn => 'Keep Request';

  @override
  String get cancelError => 'Could not complete this right now. Try again.';

  @override
  String get helpTitle => 'Help & Support';

  @override
  String get helpQ1 => 'How does payment work?';

  @override
  String get helpA1 =>
      'You pay through Mobile Money once a driver accepts your seat request — either the full fare, or a 20% deposit with the rest due before the trip.';

  @override
  String get helpQ2 => 'What if my driver cancels?';

  @override
  String get helpA2 =>
      'You\'ll be notified immediately and can search for another trip in one tap from your booking.';

  @override
  String get helpQ3 => 'How do I become a driver?';

  @override
  String get helpA3 =>
      'Go to Profile → Become a Driver, add your vehicle details and photos, and HolaRide will review and approve it.';

  @override
  String get helpContactNote =>
      'Direct support contact isn\'t set up yet in this build — add a real support email or phone number here before launch.';

  @override
  String get helpEmail => 'Email support';

  @override
  String get helpCall => 'Call support';

  @override
  String get termsTitle => 'Terms & Privacy Policy';

  @override
  String get termsBody =>
      'This screen is a placeholder. Real Terms of Service and a Privacy Policy — ideally reviewed by a lawyer familiar with Cameroonian consumer and data protection law, given this app handles real payments and personal data — need to replace this text before launch.';

  @override
  String get termsNote =>
      'At minimum, your real policy should cover things like: what data HolaRide collects (phone number, location, payment details), how Mobile Money transactions are handled, the cancellation fee structure, driver vetting and liability, and how a person can request their data be deleted.';

  @override
  String get widgetSeatsLeft => 'seats left';

  @override
  String get welcomeTaglinePrefix => 'Travel between cities,\n';

  @override
  String get welcomeTaglineAccent => 'together.';

  @override
  String get welcomeSubtitle =>
      'Comfortable, affordable and safe\nrides across Cameroon.';
}
