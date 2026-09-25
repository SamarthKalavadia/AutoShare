import 'package:flutter/material.dart';

/// Centralized localization for AutoShare supporting English ('en'), Hindi ('hi'), and Gujarati ('gu').
abstract class AppLocalizations {
  final Locale locale;
  const AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizationsEn();
  }

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('hi'),
    Locale('gu'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations forLocale(Locale locale) {
    switch (locale.languageCode) {
      case 'hi':
        return AppLocalizationsHi();
      case 'gu':
        return AppLocalizationsGu();
      case 'en':
      default:
        return AppLocalizationsEn();
    }
  }

  // App Identity
  String get appName => 'AutoShare';

  // Common Actions & Labels
  String get ok;
  String get cancel;
  String get confirm;
  String get save;
  String get edit;
  String get delete;
  String get done;
  String get next;
  String get back;
  String get close;
  String get retry;
  String get continueText;
  String get submit;
  String get skip;
  String get apply;
  String get reset;
  String get search;
  String get loading;
  String get error;
  String get success;
  String get optional;
  String get viewAll;
  String get seeMore;
  String get yes;
  String get no;

  // Bottom Navigation
  String get navHome;
  String get navSearch;
  String get navChats;
  String get navNotifications;
  String get navProfile;
  String get navMyRides;

  // Auth & Onboarding
  String get onboardingTitle1;
  String get onboardingSubtitle1;
  String get onboardingTitle2;
  String get onboardingSubtitle2;
  String get onboardingTitle3;
  String get onboardingSubtitle3;
  String get getStarted;
  String get welcomeBack;
  String get welcomeToAutoShare;
  String get loginSubtitle;
  String get emailAddress;
  String get enterEmail;
  String get password;
  String get enterPassword;
  String get rememberMe;
  String get forgotPassword;
  String get signIn;
  String get orContinueWith;
  String get signInWithGoogle;
  String get dontHaveAccount;
  String get signUp;
  String get createAccount;
  String get joinAutoShareSubtitle;
  String get fullName;
  String get enterFullName;
  String get phoneNumber;
  String get enterPhoneNumber;
  String get gender;
  String get genderMale;
  String get genderFemale;
  String get genderOther;
  String get confirmPassword;
  String get reEnterPassword;
  String get termsAgreement;
  String get alreadyHaveAccount;
  String get resetPassword;
  String get resetPasswordSubtitle;
  String get sendResetLink;
  String get backToLogin;
  String get verifyEmail;
  String get verifyEmailSubtitle;
  String get resendEmail;
  String get completeProfile;

  // Home Screen
  String get greetingMorning;
  String get greetingAfternoon;
  String get greetingEvening;
  String get whereGoing;
  String get findRide;
  String get createRide;
  String get pickupLocation;
  String get dropoffLocation;
  String get today;
  String get time;
  String get passengers;
  String get searchRides;
  String get quickActions;
  String get offerRide;
  String get availableRides;
  String get recentRides;
  String get activeRides;
  String get noRidesAvailable;
  String get driverDirectory;

  // Search / Find Ride
  String get pickupLocationHint;
  String get dropoffDestinationHint;
  String get date;
  String get requiredSeats;
  String get maxFare;
  String get filters;
  String get clearFilters;
  String get resetFilters;
  String get applyFilters;
  String get womenOnlyRides;
  String get sortBy;
  String get earliestDeparture;
  String get lowestFare;
  String get highestRated;
  String get noRidesFoundTitle;
  String get noRidesFoundSubtitle;

  // Create Ride
  String get publishRide;
  String get route;
  String get pickupPoint;
  String get selectPickupLocation;
  String get dropoffDestination;
  String get selectDropoffLocation;
  String get dateTime;
  String get capacityPricing;
  String get availableSeats;
  String get farePerSeat;
  String get recommendedFare;
  String get womenOnlyRide;
  String get womenOnlyRideDesc;
  String get additionalDetailsOptional;
  String get vehicleNumber;
  String get vehicleNumberHint;
  String get rideDescription;
  String get addNotesPassengers;
  String get ridePublishedSuccess;

  // Ride Details & Booking
  String get rideDetails;
  String get driver;
  String get routeDetails;
  String get seatsLeft;
  String get bookRide;
  String get requestSeat;
  String get cancelRequest;
  String get chatWithDriver;
  String get rideFull;
  String get rideCompleted;
  String get rideCancelled;
  String get thisIsYourOwnRide;
  String get rideAlreadyCompleted;
  String get rideWasCancelled;
  String get rideAlreadyDeparted;
  String get noSeatsAvailable;
  String get pendingApproval;
  String get requestSentSuccess;

  // My Rides
  String get myActivity;
  String get requests;
  String get filterAll;
  String get filterOffered;
  String get filterBooked;
  String get filterCompleted;
  String get filterCancelled;
  String get cancelRide;
  String get completeRide;
  String get cancelRideConfirm;
  String get noRidesFound;

  // Requests
  String get incomingRequests;
  String get accept;
  String get reject;
  String get accepted;
  String get rejected;
  String get pending;
  String get noRequestsFound;

  // Chat
  String get typeMessage;
  String get online;
  String get offline;
  String get noMessagesYet;
  String get sayHi;
  String get rideChat;

  // Notifications
  String get markAllAsRead;
  String get clearAll;
  String get noNotifications;
  String get noNotificationsSubtitle;

  // Profile & Driver Directory
  String get editProfile;
  String get personalInfo;
  String get ridesOffered;
  String get ridesTaken;
  String get rating;
  String get reviews;
  String get logOut;
  String get logOutConfirmTitle;
  String get logOutConfirmMessage;
  String get deleteAccount;
  String get deleteAccountConfirm;
  String get verifiedDriver;
  String get searchDrivers;
  String get noDriversFound;
  String get call;
  String get whatsapp;

  // Settings
  String get settings;
  String get preferences;
  String get darkMode;
  String get pushNotifications;
  String get emailNotifications;
  String get language;
  String get securityPrivacy;
  String get security;
  String get privacySettings;
  String get about;
  String get aboutAutoShare;
  String get helpSupport;
  String get termsConditions;
  String get privacyPolicy;
  String get selectAppLanguage;
  String get languageSubtext;
  String get languageUpdated;

  // Ratings
  String get rateYourRide;
  String get howWasRide;
  String get addReviewOptional;

  // Validation / Error Messages
  String get pleaseEnterEmail;
  String get enterValidEmail;
  String get pleaseEnterPassword;
  String get passwordMinLength;
  String get pleaseEnterName;
  String get pleaseEnterPhone;
  String get enterValidPhone;
  String get passwordsDoNotMatch;
  String get acceptTermsPrompt;
  String get selectPickupError;
  String get selectDropoffError;
  String get genericError;

  // Additional UI Labels
  String get yesterday;
  String get earlier;
  String get selectAll;
  String get deselectAll;
  String get selectedCountText;
  String get markAsRead;
  String get markAsUnread;
  String get account;
  String get rideActivity;
  String get created;
  String get joined;
  String get completed;
  String get passwordAndSecurity;
  String get emailAndVerification;
  String get verified;
  String get unverified;
  String get aboutAndSupport;
  String get accountActions;
  String get typing;
  String get startConversation;
  String get noChatsSubtitle;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'hi', 'gu'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations.forLocale(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension LocalizationExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// ============================================================================
/// ENGLISH IMPLEMENTATION (Default & Fallback)
/// ============================================================================
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn() : super(const Locale('en'));

  @override
  String get ok => 'OK';
  @override
  String get cancel => 'Cancel';
  @override
  String get confirm => 'Confirm';
  @override
  String get save => 'Save';
  @override
  String get edit => 'Edit';
  @override
  String get delete => 'Delete';
  @override
  String get done => 'Done';
  @override
  String get next => 'Next';
  @override
  String get back => 'Back';
  @override
  String get close => 'Close';
  @override
  String get retry => 'Retry';
  @override
  String get continueText => 'Continue';
  @override
  String get submit => 'Submit';
  @override
  String get skip => 'Skip';
  @override
  String get apply => 'Apply';
  @override
  String get reset => 'Reset';
  @override
  String get search => 'Search';
  @override
  String get loading => 'Loading...';
  @override
  String get error => 'Error';
  @override
  String get success => 'Success';
  @override
  String get optional => 'Optional';
  @override
  String get viewAll => 'View All';
  @override
  String get seeMore => 'See More';
  @override
  String get yes => 'Yes';
  @override
  String get no => 'No';

  @override
  String get navHome => 'Home';
  @override
  String get navSearch => 'Search';
  @override
  String get navChats => 'Chats';
  @override
  String get navNotifications => 'Notifications';
  @override
  String get navProfile => 'Profile';
  @override
  String get navMyRides => 'My Rides';

  @override
  String get onboardingTitle1 => 'Share the Ride, Split the Cost';
  @override
  String get onboardingSubtitle1 => 'Connect with co-travelers going your way and save on daily commute.';
  @override
  String get onboardingTitle2 => 'Safe & Verified Community';
  @override
  String get onboardingSubtitle2 => 'Travel with verified college peers and colleagues with real-time tracking.';
  @override
  String get onboardingTitle3 => 'Track in Real-Time';
  @override
  String get onboardingSubtitle3 => 'Live ride tracking and easy chat for a hassle-free journey.';
  @override
  String get getStarted => 'Get Started';
  @override
  String get welcomeBack => 'Welcome Back';
  @override
  String get welcomeToAutoShare => 'Welcome to AutoShare';
  @override
  String get loginSubtitle => 'Share rides. Save money. Travel together.';
  @override
  String get emailAddress => 'Email address';
  @override
  String get enterEmail => 'Enter your email address';
  @override
  String get password => 'Password';
  @override
  String get enterPassword => 'Enter your password';
  @override
  String get rememberMe => 'Remember me';
  @override
  String get forgotPassword => 'Forgot password?';
  @override
  String get signIn => 'Sign In';
  @override
  String get orContinueWith => 'OR';
  @override
  String get signInWithGoogle => 'Sign in with Google';
  @override
  String get dontHaveAccount => "Don't have an account?";
  @override
  String get signUp => 'Sign Up';
  @override
  String get createAccount => 'Create Account';
  @override
  String get joinAutoShareSubtitle => 'Join AutoShare to share rides and save costs.';
  @override
  String get fullName => 'Full Name';
  @override
  String get enterFullName => 'Enter your full name';
  @override
  String get phoneNumber => 'Phone Number';
  @override
  String get enterPhoneNumber => 'Enter phone number';
  @override
  String get gender => 'Gender';
  @override
  String get genderMale => 'Male';
  @override
  String get genderFemale => 'Female';
  @override
  String get genderOther => 'Other';
  @override
  String get confirmPassword => 'Confirm Password';
  @override
  String get reEnterPassword => 'Re-enter your password';
  @override
  String get termsAgreement => 'I agree to the Terms of Service & Privacy Policy';
  @override
  String get alreadyHaveAccount => 'Already have an account?';
  @override
  String get resetPassword => 'Reset Password';
  @override
  String get resetPasswordSubtitle => 'Enter your email to receive a password reset link';
  @override
  String get sendResetLink => 'Send Reset Link';
  @override
  String get backToLogin => 'Back to Login';
  @override
  String get verifyEmail => 'Verify Your Email';
  @override
  String get verifyEmailSubtitle => 'We have sent a verification link to your email address.';
  @override
  String get resendEmail => 'Resend Email';
  @override
  String get completeProfile => 'Complete Profile';

  @override
  String get greetingMorning => 'Good Morning,';
  @override
  String get greetingAfternoon => 'Good Afternoon,';
  @override
  String get greetingEvening => 'Good Evening,';
  @override
  String get whereGoing => 'Where are you going?';
  @override
  String get findRide => 'Find Ride';
  @override
  String get createRide => 'Create Ride';
  @override
  String get pickupLocation => 'Pickup Location';
  @override
  String get dropoffLocation => 'Dropoff Location';
  @override
  String get today => 'Today';
  @override
  String get time => 'Time';
  @override
  String get passengers => 'Passengers';
  @override
  String get searchRides => 'Search Rides';
  @override
  String get quickActions => 'Quick Actions';
  @override
  String get offerRide => 'Offer a Ride';
  @override
  String get availableRides => 'Available Rides';
  @override
  String get recentRides => 'Recent Rides';
  @override
  String get activeRides => 'Active Rides';
  @override
  String get noRidesAvailable => 'No rides available';
  @override
  String get driverDirectory => 'Driver Directory';

  @override
  String get pickupLocationHint => 'Pickup location';
  @override
  String get dropoffDestinationHint => 'Drop-off destination';
  @override
  String get date => 'Date';
  @override
  String get requiredSeats => 'Required Seats';
  @override
  String get maxFare => 'Max Fare';
  @override
  String get filters => 'Filters';
  @override
  String get clearFilters => 'Clear Filters';
  @override
  String get resetFilters => 'Reset Filters';
  @override
  String get applyFilters => 'Apply Filters';
  @override
  String get womenOnlyRides => 'Women Only Rides';
  @override
  String get sortBy => 'Sort by';
  @override
  String get earliestDeparture => 'Earliest Departure';
  @override
  String get lowestFare => 'Lowest Fare';
  @override
  String get highestRated => 'Highest Rated';
  @override
  String get noRidesFoundTitle => 'No rides found';
  @override
  String get noRidesFoundSubtitle => 'Try adjusting your search criteria';

  @override
  String get publishRide => 'Publish Ride';
  @override
  String get route => 'ROUTE';
  @override
  String get pickupPoint => 'Pickup Point';
  @override
  String get selectPickupLocation => 'Select pickup location';
  @override
  String get dropoffDestination => 'Drop-off Destination';
  @override
  String get selectDropoffLocation => 'Select drop-off location';
  @override
  String get dateTime => 'DATE & TIME';
  @override
  String get capacityPricing => 'CAPACITY & PRICING';
  @override
  String get availableSeats => 'Available Seats';
  @override
  String get farePerSeat => 'Fare per seat (₹)';
  @override
  String get recommendedFare => 'Recommended';
  @override
  String get womenOnlyRide => 'Women Only Ride';
  @override
  String get womenOnlyRideDesc => 'Only female passengers can join this ride';
  @override
  String get additionalDetailsOptional => 'ADDITIONAL DETAILS (Optional)';
  @override
  String get vehicleNumber => 'Vehicle Number';
  @override
  String get vehicleNumberHint => 'e.g. GJ 01 AB 1234';
  @override
  String get rideDescription => 'Ride Description';
  @override
  String get addNotesPassengers => 'Add notes for passengers';
  @override
  String get ridePublishedSuccess => 'Ride published successfully!';

  @override
  String get rideDetails => 'Ride Details';
  @override
  String get driver => 'Driver';
  @override
  String get routeDetails => 'Route';
  @override
  String get seatsLeft => 'seats left';
  @override
  String get bookRide => 'Book Ride';
  @override
  String get requestSeat => 'Request Seat';
  @override
  String get cancelRequest => 'Cancel Request';
  @override
  String get chatWithDriver => 'Chat with Driver';
  @override
  String get rideFull => 'Ride Full';
  @override
  String get rideCompleted => 'Ride Completed';
  @override
  String get rideCancelled => 'Ride Cancelled';
  @override
  String get thisIsYourOwnRide => 'This is your own ride';
  @override
  String get rideAlreadyCompleted => 'Ride already completed';
  @override
  String get rideWasCancelled => 'Ride was cancelled';
  @override
  String get rideAlreadyDeparted => 'Ride has already departed';
  @override
  String get noSeatsAvailable => 'No seats available';
  @override
  String get pendingApproval => 'Pending Approval';
  @override
  String get requestSentSuccess => 'Request sent successfully!';

  @override
  String get myActivity => 'My Activity';
  @override
  String get requests => 'Requests';
  @override
  String get filterAll => 'All';
  @override
  String get filterOffered => 'Offered';
  @override
  String get filterBooked => 'Booked';
  @override
  String get filterCompleted => 'Completed';
  @override
  String get filterCancelled => 'Cancelled';
  @override
  String get cancelRide => 'Cancel Ride';
  @override
  String get completeRide => 'Complete Ride';
  @override
  String get cancelRideConfirm => 'Are you sure you want to cancel this ride?';
  @override
  String get noRidesFound => 'No rides found';

  @override
  String get incomingRequests => 'Incoming Requests';
  @override
  String get accept => 'Accept';
  @override
  String get reject => 'Reject';
  @override
  String get accepted => 'Accepted';
  @override
  String get rejected => 'Rejected';
  @override
  String get pending => 'Pending';
  @override
  String get noRequestsFound => 'No requests found';

  @override
  String get typeMessage => 'Type a message...';
  @override
  String get online => 'Online';
  @override
  String get offline => 'Offline';
  @override
  String get noMessagesYet => 'No messages yet';
  @override
  String get sayHi => 'Say hi to start the conversation!';
  @override
  String get rideChat => 'Ride Chat';

  @override
  String get markAllAsRead => 'Mark all as read';
  @override
  String get clearAll => 'Clear all';
  @override
  String get noNotifications => 'No notifications yet';
  @override
  String get noNotificationsSubtitle => 'Stay tuned for updates on your rides and chats';

  @override
  String get editProfile => 'Edit Profile';
  @override
  String get personalInfo => 'Personal Information';
  @override
  String get ridesOffered => 'Rides Offered';
  @override
  String get ridesTaken => 'Rides Taken';
  @override
  String get rating => 'Rating';
  @override
  String get reviews => 'Reviews';
  @override
  String get logOut => 'Log Out';
  @override
  String get logOutConfirmTitle => 'Log Out';
  @override
  String get logOutConfirmMessage => 'Are you sure you want to log out?';
  @override
  String get deleteAccount => 'Delete Account';
  @override
  String get deleteAccountConfirm =>
      'Are you sure you want to delete your account? This action is permanent and will delete all your data, rides, and settings.';
  @override
  String get verifiedDriver => 'Verified Driver';
  @override
  String get searchDrivers => 'Search drivers...';
  @override
  String get noDriversFound => 'No drivers found';
  @override
  String get call => 'Call';
  @override
  String get whatsapp => 'WhatsApp';

  @override
  String get settings => 'Settings';
  @override
  String get preferences => 'Preferences';
  @override
  String get darkMode => 'Dark Mode';
  @override
  String get pushNotifications => 'Push Notifications';
  @override
  String get emailNotifications => 'Email Notifications';
  @override
  String get language => 'Language';
  @override
  String get securityPrivacy => 'Security & Privacy';
  @override
  String get security => 'Security';
  @override
  String get privacySettings => 'Privacy Settings';
  @override
  String get about => 'About';
  @override
  String get aboutAutoShare => 'About AutoShare';
  @override
  String get helpSupport => 'Help & Support';
  @override
  String get termsConditions => 'Terms & Conditions';
  @override
  String get privacyPolicy => 'Privacy Policy';
  @override
  String get selectAppLanguage => 'SELECT APP LANGUAGE';
  @override
  String get languageSubtext =>
      'Select your preferred language. The entire app will update immediately.';
  @override
  String get languageUpdated => 'Language updated successfully';

  @override
  String get rateYourRide => 'Rate your ride';
  @override
  String get howWasRide => 'How was your ride?';
  @override
  String get addReviewOptional => 'Add a review (optional)';

  @override
  String get pleaseEnterEmail => 'Please enter your email';
  @override
  String get enterValidEmail => 'Enter a valid email address';
  @override
  String get pleaseEnterPassword => 'Please enter your password';
  @override
  String get passwordMinLength => 'Password must be at least 6 characters';
  @override
  String get pleaseEnterName => 'Please enter your name';
  @override
  String get pleaseEnterPhone => 'Please enter your phone number';
  @override
  String get enterValidPhone => 'Enter a valid 10-digit phone number';
  @override
  String get passwordsDoNotMatch => 'Passwords do not match';
  @override
  String get acceptTermsPrompt =>
      'Please accept the Terms of Service & Privacy Policy to proceed.';
  @override
  String get selectPickupError => 'Please select pickup location';
  @override
  String get selectDropoffError => 'Please select dropoff location';
  @override
  String get genericError => 'An error occurred. Please try again.';

  @override
  String get yesterday => 'Yesterday';
  @override
  String get earlier => 'Earlier';
  @override
  String get selectAll => 'Select all';
  @override
  String get deselectAll => 'Deselect all';
  @override
  String get selectedCountText => 'selected';
  @override
  String get markAsRead => 'Mark as read';
  @override
  String get markAsUnread => 'Mark as unread';
  @override
  String get account => 'Account';
  @override
  String get rideActivity => 'Ride Activity';
  @override
  String get created => 'Created';
  @override
  String get joined => 'Joined';
  @override
  String get completed => 'Completed';
  @override
  String get passwordAndSecurity => 'Password & Security';
  @override
  String get emailAndVerification => 'Email & Verification';
  @override
  String get verified => 'Verified';
  @override
  String get unverified => 'Unverified';
  @override
  String get aboutAndSupport => 'About & Support';
  @override
  String get accountActions => 'Account Actions';
  @override
  String get typing => 'typing...';
  @override
  String get startConversation => 'Start a conversation';
  @override
  String get noChatsSubtitle => 'Conversations with drivers and riders will appear here.';
}

/// ============================================================================
/// HINDI IMPLEMENTATION ('hi')
/// ============================================================================
class AppLocalizationsHi extends AppLocalizationsEn {
  AppLocalizationsHi() : super();

  @override
  Locale get locale => const Locale('hi');

  @override
  String get ok => 'ठीक है';
  @override
  String get cancel => 'रद्द करें';
  @override
  String get confirm => 'पुष्टि करें';
  @override
  String get save => 'सहेजें';
  @override
  String get edit => 'संपादित करें';
  @override
  String get delete => 'हटाएं';
  @override
  String get done => 'हो गया';
  @override
  String get next => 'आगे';
  @override
  String get back => 'पीछे';
  @override
  String get close => 'बंद करें';
  @override
  String get retry => 'पुनः प्रयास करें';
  @override
  String get continueText => 'जारी रखें';
  @override
  String get submit => 'जमा करें';
  @override
  String get skip => 'छोड़ें';
  @override
  String get apply => 'लागू करें';
  @override
  String get reset => 'रीसेट करें';
  @override
  String get search => 'खोजें';
  @override
  String get loading => 'लोड हो रहा है...';
  @override
  String get error => 'त्रुटि';
  @override
  String get success => 'सफलता';
  @override
  String get optional => 'वैकल्पिक';
  @override
  String get viewAll => 'सभी देखें';
  @override
  String get seeMore => 'और देखें';
  @override
  String get yes => 'हां';
  @override
  String get no => 'नहीं';

  @override
  String get navHome => 'होम';
  @override
  String get navSearch => 'खोजें';
  @override
  String get navChats => 'चैट्स';
  @override
  String get navNotifications => 'सूचनाएं';
  @override
  String get navProfile => 'प्रोफ़ाइल';
  @override
  String get navMyRides => 'मेरी राइड्स';

  @override
  String get onboardingTitle1 => 'राइड शेयर करें, खर्च बांटें';
  @override
  String get onboardingSubtitle1 =>
      'अपने मार्ग पर जाने वाले सह-यात्रियों से जुड़ें और दैनिक यात्रा पर बचत करें।';
  @override
  String get onboardingTitle2 => 'सुरक्षित और सत्यापित समुदाय';
  @override
  String get onboardingSubtitle2 =>
      'सत्यापित सहपाठियों और सहयोगियों के साथ रीयल-टाइम ट्रैकिंग के साथ यात्रा करें।';
  @override
  String get onboardingTitle3 => 'रीयल-टाइम में ट्रैक करें';
  @override
  String get onboardingSubtitle3 =>
      'परेशानी मुक्त यात्रा के लिए लाइव राइड ट्रैकिंग और आसान चैट।';
  @override
  String get getStarted => 'शुरू करें';
  @override
  String get welcomeBack => 'वापसी पर स्वागत है';
  @override
  String get welcomeToAutoShare => 'AutoShare में आपका स्वागत है';
  @override
  String get loginSubtitle => 'राइड शेयर करें। पैसे बचाएं। साथ यात्रा करें।';
  @override
  String get emailAddress => 'ईमेल पता';
  @override
  String get enterEmail => 'अपना ईमेल पता दर्ज करें';
  @override
  String get password => 'पासवर्ड';
  @override
  String get enterPassword => 'अपना पासवर्ड दर्ज करें';
  @override
  String get rememberMe => 'मुझे याद रखें';
  @override
  String get forgotPassword => 'पासवर्ड भूल गए?';
  @override
  String get signIn => 'साइन इन';
  @override
  String get orContinueWith => 'या';
  @override
  String get signInWithGoogle => 'Google से साइन इन करें';
  @override
  String get dontHaveAccount => 'खाता नहीं है?';
  @override
  String get signUp => 'साइन अप';
  @override
  String get createAccount => 'खाता बनाएं';
  @override
  String get joinAutoShareSubtitle =>
      'राइड शेयर करने और लागत बचाने के लिए AutoShare से जुड़ें।';
  @override
  String get fullName => 'पूरा नाम';
  @override
  String get enterFullName => 'अपना पूरा नाम दर्ज करें';
  @override
  String get phoneNumber => 'फ़ोन नंबर';
  @override
  String get enterPhoneNumber => 'फ़ोन नंबर दर्ज करें';
  @override
  String get gender => 'लिंग';
  @override
  String get genderMale => 'पुरुष';
  @override
  String get genderFemale => 'महिला';
  @override
  String get genderOther => 'अन्य';
  @override
  String get confirmPassword => 'पासवर्ड की पुष्टि करें';
  @override
  String get reEnterPassword => 'अपना पासवर्ड दोबारा दर्ज करें';
  @override
  String get termsAgreement =>
      'मैं सेवा की शर्तों और गोपनीयता नीति से सहमत हूं';
  @override
  String get alreadyHaveAccount => 'पहले से खाता है?';
  @override
  String get resetPassword => 'पासवर्ड रीसेट करें';
  @override
  String get resetPasswordSubtitle =>
      'पासवर्ड रीसेट लिंक प्राप्त करने के लिए अपना ईमेल दर्ज करें';
  @override
  String get sendResetLink => 'रीसेट लिंक भेजें';
  @override
  String get backToLogin => 'लॉगिन पर वापस जाएं';
  @override
  String get verifyEmail => 'अपना ईमेल सत्यापित करें';
  @override
  String get verifyEmailSubtitle =>
      'हमने आपके ईमेल पते पर एक सत्यापन लिंक भेजा है।';
  @override
  String get resendEmail => 'ईमेल दोबारा भेजें';
  @override
  String get completeProfile => 'प्रोफ़ाइल पूरी करें';

  @override
  String get greetingMorning => 'शुभ प्रभात,';
  @override
  String get greetingAfternoon => 'शुभ दोपहर,';
  @override
  String get greetingEvening => 'शुभ संध्या,';
  @override
  String get whereGoing => 'आप कहां जा रहे हैं?';
  @override
  String get findRide => 'राइड खोजें';
  @override
  String get createRide => 'राइड बनाएं';
  @override
  String get pickupLocation => 'पिकअप स्थान';
  @override
  String get dropoffLocation => 'ड्रॉपऑफ़ स्थान';
  @override
  String get today => 'आज';
  @override
  String get time => 'समय';
  @override
  String get passengers => 'यात्री';
  @override
  String get searchRides => 'राइड्स खोजें';
  @override
  String get quickActions => 'त्वरित क्रियाएं';
  @override
  String get offerRide => 'राइड ऑफर करें';
  @override
  String get availableRides => 'उपलब्ध राइड्स';
  @override
  String get recentRides => 'हाल की राइड्स';
  @override
  String get activeRides => 'सक्रिय राइड्स';
  @override
  String get noRidesAvailable => 'कोई राइड उपलब्ध नहीं है';
  @override
  String get driverDirectory => 'ड्राइवर डायरेक्टरी';

  @override
  String get pickupLocationHint => 'पिकअप स्थान';
  @override
  String get dropoffDestinationHint => 'ड्रॉपऑफ़ गंतव्य';
  @override
  String get date => 'दिनांक';
  @override
  String get requiredSeats => 'आवश्यक सीटें';
  @override
  String get maxFare => 'अधिकतम किराया';
  @override
  String get filters => 'फ़िल्टर';
  @override
  String get clearFilters => 'फ़िल्टर हटाएं';
  @override
  String get resetFilters => 'फ़िल्टर रीसेट करें';
  @override
  String get applyFilters => 'फ़िल्टर लागू करें';
  @override
  String get womenOnlyRides => 'केवल महिलाओं के लिए राइड्स';
  @override
  String get sortBy => 'क्रमबद्ध करें';
  @override
  String get earliestDeparture => 'जल्द से जल्द प्रस्थान';
  @override
  String get lowestFare => 'न्यूनतम किराया';
  @override
  String get highestRated => 'उच्चतम रेटिंग';
  @override
  String get noRidesFoundTitle => 'कोई राइड नहीं मिली';
  @override
  String get noRidesFoundSubtitle => 'अपने खोज मानदंड बदलने का प्रयास करें';

  @override
  String get publishRide => 'राइड प्रकाशित करें';
  @override
  String get route => 'मार्ग';
  @override
  String get pickupPoint => 'पिकअप बिंदु';
  @override
  String get selectPickupLocation => 'पिकअप स्थान चुनें';
  @override
  String get dropoffDestination => 'ड्रॉपऑफ़ गंतव्य';
  @override
  String get selectDropoffLocation => 'ड्रॉपऑफ़ स्थान चुनें';
  @override
  String get dateTime => 'दिनांक और समय';
  @override
  String get capacityPricing => 'क्षमता और मूल्य';
  @override
  String get availableSeats => 'उपलब्ध सीटें';
  @override
  String get farePerSeat => 'प्रति सीट किराया (₹)';
  @override
  String get recommendedFare => 'अनुशंसित';
  @override
  String get womenOnlyRide => 'केवल महिलाओं के लिए राइड';
  @override
  String get womenOnlyRideDesc =>
      'केवल महिला यात्री इस राइड में शामिल हो सकती हैं';
  @override
  String get additionalDetailsOptional => 'अतिरिक्त विवरण (वैकल्पिक)';
  @override
  String get vehicleNumber => 'वाहन संख्या';
  @override
  String get vehicleNumberHint => 'उदा. GJ 01 AB 1234';
  @override
  String get rideDescription => 'राइड का विवरण';
  @override
  String get addNotesPassengers => 'यात्रियों के लिए नोट्स जोड़ें';
  @override
  String get ridePublishedSuccess => 'राइड सफलतापूर्वक प्रकाशित हुई!';

  @override
  String get rideDetails => 'राइड विवरण';
  @override
  String get driver => 'ड्राइवर';
  @override
  String get routeDetails => 'मार्ग';
  @override
  String get seatsLeft => 'सीटें शेष';
  @override
  String get bookRide => 'राइड बुक करें';
  @override
  String get requestSeat => 'सीट का अनुरोध करें';
  @override
  String get cancelRequest => 'अनुरोध रद्द करें';
  @override
  String get chatWithDriver => 'ड्राइवर से चैट करें';
  @override
  String get rideFull => 'राइड फुल है';
  @override
  String get rideCompleted => 'राइड पूर्ण';
  @override
  String get rideCancelled => 'राइड रद्द';
  @override
  String get thisIsYourOwnRide => 'यह आपकी अपनी राइड है';
  @override
  String get rideAlreadyCompleted => 'राइड पहले ही पूर्ण हो चुकी है';
  @override
  String get rideWasCancelled => 'राइड रद्द कर दी गई थी';
  @override
  String get rideAlreadyDeparted => 'राइड पहले ही प्रस्थान कर चुकी है';
  @override
  String get noSeatsAvailable => 'कोई सीट उपलब्ध नहीं है';
  @override
  String get pendingApproval => 'स्वीकृति लंबित';
  @override
  String get requestSentSuccess => 'अनुरोध सफलतापूर्वक भेजा गया!';

  @override
  String get myActivity => 'मेरी गतिविधि';
  @override
  String get requests => 'अनुरोध';
  @override
  String get filterAll => 'सभी';
  @override
  String get filterOffered => 'ऑफर की गई';
  @override
  String get filterBooked => 'बुक की गई';
  @override
  String get filterCompleted => 'पूर्ण';
  @override
  String get filterCancelled => 'रद्द';
  @override
  String get cancelRide => 'राइड रद्द करें';
  @override
  String get completeRide => 'राइड पूर्ण करें';
  @override
  String get cancelRideConfirm =>
      'क्या आप वाकई यह राइड रद्द करना चाहते हैं?';
  @override
  String get noRidesFound => 'कोई राइड नहीं मिली';

  @override
  String get incomingRequests => 'प्राप्त अनुरोध';
  @override
  String get accept => 'स्वीकार करें';
  @override
  String get reject => 'अस्वीकार करें';
  @override
  String get accepted => 'स्वीकृत';
  @override
  String get rejected => 'अस्वीकृत';
  @override
  String get pending => 'लंबित';
  @override
  String get noRequestsFound => 'कोई अनुरोध नहीं मिला';

  @override
  String get typeMessage => 'संदेश लिखें...';
  @override
  String get online => 'ऑनलाइन';
  @override
  String get offline => 'ऑफलाइन';
  @override
  String get noMessagesYet => 'अभी तक कोई संदेश नहीं';
  @override
  String get sayHi => 'बातचीत शुरू करने के लिए नमस्ते कहें!';
  @override
  String get rideChat => 'राइड चैट';

  @override
  String get markAllAsRead => 'सभी को पढ़ा हुआ चिह्नित करें';
  @override
  String get clearAll => 'सभी हटाएं';
  @override
  String get noNotifications => 'अभी तक कोई सूचना नहीं';
  @override
  String get noNotificationsSubtitle =>
      'अपनी राइड्स और चैट के अपडेट के लिए बने रहें';

  @override
  String get editProfile => 'प्रोफ़ाइल संपादित करें';
  @override
  String get personalInfo => 'व्यक्तिगत जानकारी';
  @override
  String get ridesOffered => 'ऑफर की गई राइड्स';
  @override
  String get ridesTaken => 'ली गई राइड्स';
  @override
  String get rating => 'रेटिंग';
  @override
  String get reviews => 'समीक्षाएं';
  @override
  String get logOut => 'लॉग आउट';
  @override
  String get logOutConfirmTitle => 'लॉग आउट';
  @override
  String get logOutConfirmMessage => 'क्या आप वाकई लॉग आउट करना चाहते हैं?';
  @override
  String get deleteAccount => 'खाता हटाएं';
  @override
  String get deleteAccountConfirm =>
      'क्या आप वाकई अपना खाता हटाना चाहते हैं? यह कार्रवाई स्थायी है और आपका सारा डेटा, राइड्स और सेटिंग्स हटा देगी।';
  @override
  String get verifiedDriver => 'सत्यापित ड्राइवर';
  @override
  String get searchDrivers => 'ड्राइवर खोजें...';
  @override
  String get noDriversFound => 'कोई ड्राइवर नहीं मिला';
  @override
  String get call => 'कॉल';
  @override
  String get whatsapp => 'WhatsApp';

  @override
  String get settings => 'सेटिंग्स';
  @override
  String get preferences => 'प्राथमिकताएं';
  @override
  String get darkMode => 'डार्क मोड';
  @override
  String get pushNotifications => 'पुश सूचनाएं';
  @override
  String get emailNotifications => 'ईमेल सूचनाएं';
  @override
  String get language => 'भाषा';
  @override
  String get securityPrivacy => 'सुरक्षा और गोपनीयता';
  @override
  String get security => 'सुरक्षा';
  @override
  String get privacySettings => 'गोपनीयता सेटिंग्स';
  @override
  String get about => 'के बारे में';
  @override
  String get aboutAutoShare => 'AutoShare के बारे में';
  @override
  String get helpSupport => 'सहायता और समर्थन';
  @override
  String get termsConditions => 'नियम और शर्तें';
  @override
  String get privacyPolicy => 'गोपनीयता नीति';
  @override
  String get selectAppLanguage => 'ऐप की भाषा चुनें';
  @override
  String get languageSubtext =>
      'अपनी पसंदीदा भाषा चुनें। पूरी ऐप तुरंत अपडेट हो जाएगी।';
  @override
  String get languageUpdated => 'भाषा सफलतापूर्वक अपडेट की गई';

  @override
  String get rateYourRide => 'अपनी राइड को रेट करें';
  @override
  String get howWasRide => 'आपकी राइड कैसी रही?';
  @override
  String get addReviewOptional => 'समीक्षा जोड़ें (वैकल्पिक)';

  @override
  String get pleaseEnterEmail => 'कृपया अपना ईमेल दर्ज करें';
  @override
  String get enterValidEmail => 'एक वैध ईमेल पता दर्ज करें';
  @override
  String get pleaseEnterPassword => 'कृपया अपना पासवर्ड दर्ज करें';
  @override
  String get passwordMinLength => 'पासवर्ड कम से कम 6 अक्षरों का होना चाहिए';
  @override
  String get pleaseEnterName => 'कृपया अपना नाम दर्ज करें';
  @override
  String get pleaseEnterPhone => 'कृपया अपना फ़ोन नंबर दर्ज करें';
  @override
  String get enterValidPhone => '10 अंकों का वैध फ़ोन नंबर दर्ज करें';
  @override
  String get passwordsDoNotMatch => 'पासवर्ड मेल नहीं खाते';
  @override
  String get acceptTermsPrompt =>
      'आगे बढ़ने के लिए कृपया सेवा की शर्तों और गोपनीयता नीति को स्वीकार करें।';
  @override
  String get selectPickupError => 'कृपया पिकअप स्थान चुनें';
  @override
  String get selectDropoffError => 'कृपया ड्रॉपऑफ़ स्थान चुनें';
  @override
  String get genericError => 'एक त्रुटि हुई। कृपया पुनः प्रयास करें।';

  @override
  String get yesterday => 'कल';
  @override
  String get earlier => 'पहले';
  @override
  String get selectAll => 'सभी चुनें';
  @override
  String get deselectAll => 'सभी अचयनित करें';
  @override
  String get selectedCountText => 'चयनित';
  @override
  String get markAsRead => 'पढ़ा हुआ चिह्नित करें';
  @override
  String get markAsUnread => 'अपठित चिह्नित करें';
  @override
  String get account => 'खाता';
  @override
  String get rideActivity => 'राइड गतिविधि';
  @override
  String get created => 'बनाई गई';
  @override
  String get joined => 'शामिल हुए';
  @override
  String get completed => 'पूर्ण';
  @override
  String get passwordAndSecurity => 'पासवर्ड और सुरक्षा';
  @override
  String get emailAndVerification => 'ईमेल और सत्यापन';
  @override
  String get verified => 'सत्यापित';
  @override
  String get unverified => 'असत्यापित';
  @override
  String get aboutAndSupport => 'के बारे में और सहायता';
  @override
  String get accountActions => 'खाता क्रियाएं';
  @override
  String get typing => 'टाइप कर रहे हैं...';
  @override
  String get startConversation => 'बातचीत शुरू करें';
  @override
  String get noChatsSubtitle => 'ड्राइवरों और सवारों के साथ बातचीत यहां दिखाई देगी।';
}

/// ============================================================================
/// GUJARATI IMPLEMENTATION ('gu')
/// ============================================================================
class AppLocalizationsGu extends AppLocalizationsEn {
  AppLocalizationsGu() : super();

  @override
  Locale get locale => const Locale('gu');

  @override
  String get ok => 'બરાબર';
  @override
  String get cancel => 'રદ કરો';
  @override
  String get confirm => 'પુષ્ટિ કરો';
  @override
  String get save => 'સાચવો';
  @override
  String get edit => 'સંપાદિત કરો';
  @override
  String get delete => 'કાઢી નાખો';
  @override
  String get done => 'પૂર્ણ';
  @override
  String get next => 'આગળ';
  @override
  String get back => 'પાછા';
  @override
  String get close => 'બંધ કરો';
  @override
  String get retry => 'ફરી પ્રયાસ કરો';
  @override
  String get continueText => 'ચાલુ રાખો';
  @override
  String get submit => 'સબમિટ કરો';
  @override
  String get skip => 'છોડો';
  @override
  String get apply => 'લાગુ કરો';
  @override
  String get reset => 'રીસેટ કરો';
  @override
  String get search => 'શોધો';
  @override
  String get loading => 'લોડ થઈ રહ્યું છે...';
  @override
  String get error => 'ભૂલ';
  @override
  String get success => 'સફળતા';
  @override
  String get optional => 'વૈકલ્પિક';
  @override
  String get viewAll => 'બધા જુઓ';
  @override
  String get seeMore => 'વધુ જુઓ';
  @override
  String get yes => 'હા';
  @override
  String get no => 'ના';

  @override
  String get navHome => 'હોમ';
  @override
  String get navSearch => 'શોધો';
  @override
  String get navChats => 'ચેટ્સ';
  @override
  String get navNotifications => 'સૂચનાઓ';
  @override
  String get navProfile => 'પ્રોફાઇલ';
  @override
  String get navMyRides => 'મારી રાઇડ્સ';

  @override
  String get onboardingTitle1 => 'રાઇડ શેર કરો, ખર્ચ વહેંચો';
  @override
  String get onboardingSubtitle1 =>
      'તમારા રૂટ પર જતા મુસાફરો સાથે જોડાવો અને દૈનિક મુસાફરીમાં બચત કરો.';
  @override
  String get onboardingTitle2 => 'સુરક્ષિત અને ચકાસાયેલ સમુદાય';
  @override
  String get onboardingSubtitle2 =>
      'રીઅલ-ટાઇમ ટ્રેકિંગ સાથે ચકાસાયેલ કૉલેજના સાથીઓ સાથે મુસાફરી કરો.';
  @override
  String get onboardingTitle3 => 'રીઅલ-ટાઇમમાં ટ્રેક કરો';
  @override
  String get onboardingSubtitle3 =>
      'સરળ મુસાફરી માટે લાઇવ રાઇડ ટ્રેકિંગ અને સરળ ચેટ.';
  @override
  String get getStarted => 'શરૂ કરો';
  @override
  String get welcomeBack => 'સ્વાગત છે';
  @override
  String get welcomeToAutoShare => 'AutoShare માં સ્વાગત છે';
  @override
  String get loginSubtitle => 'રાઇડ શેર કરો. પૈસા બચાવો. સાથે મુસાફરી કરો.';
  @override
  String get emailAddress => 'ઇમેઇલ સરનામું';
  @override
  String get enterEmail => 'તમારું ઇમેઇલ સરનામું દાખલ કરો';
  @override
  String get password => 'પાસવર્ડ';
  @override
  String get enterPassword => 'તમારો પાસવર્ડ દાખલ કરો';
  @override
  String get rememberMe => 'મને યાદ રાખો';
  @override
  String get forgotPassword => 'પાસવર્ડ ભૂલી ગયા છો?';
  @override
  String get signIn => 'સાઇન ઇન';
  @override
  String get orContinueWith => 'અથવા';
  @override
  String get signInWithGoogle => 'Google વડે સાઇન ઇન કરો';
  @override
  String get dontHaveAccount => 'ખાતું નથી?';
  @override
  String get signUp => 'સાઇન અપ';
  @override
  String get createAccount => 'ખાતું બનાવો';
  @override
  String get joinAutoShareSubtitle =>
      'રાઇડ શેર કરવા અને ખર્ચ બચાવવા માટે AutoShare માં જોડાઓ.';
  @override
  String get fullName => 'પૂરું નામ';
  @override
  String get enterFullName => 'તમારું પૂરું નામ દાખલ કરો';
  @override
  String get phoneNumber => 'ફોન નંબર';
  @override
  String get enterPhoneNumber => 'ફોન નંબર દાખલ કરો';
  @override
  String get gender => 'જાતિ';
  @override
  String get genderMale => 'પુરુષ';
  @override
  String get genderFemale => 'સ્ત્રી';
  @override
  String get genderOther => 'અન્ય';
  @override
  String get confirmPassword => 'પાસવર્ડની પુષ્ટિ કરો';
  @override
  String get reEnterPassword => 'તમારો પાસવર્ડ ફરી દાખલ કરો';
  @override
  String get termsAgreement =>
      'હું સેવાની શરતો અને ગોપનીયતા નીતિ સાથે સંમત છું';
  @override
  String get alreadyHaveAccount => 'પહેલેથી ખાતું છે?';
  @override
  String get resetPassword => 'પાસવર્ડ રીસેટ કરો';
  @override
  String get resetPasswordSubtitle =>
      'પાસવર્ડ રીસેટ લિંક મેળવવા માટે તમારો ઇમેઇલ દાખલ કરો';
  @override
  String get sendResetLink => 'રીસેટ લિંક મોકલો';
  @override
  String get backToLogin => 'લૉગિન પર પાછા જાઓ';
  @override
  String get verifyEmail => 'તમારો ઇમેઇલ ચકાસો';
  @override
  String get verifyEmailSubtitle =>
      'અમે તમારા ઇમેઇલ સરનામાં પર ચકાસણી લિંક મોકલી છે.';
  @override
  String get resendEmail => 'ઇમેઇલ ફરી મોકલો';
  @override
  String get completeProfile => 'પ્રોફાઇલ પૂર્ણ કરો';

  @override
  String get greetingMorning => 'સુપ્રભાત,';
  @override
  String get greetingAfternoon => 'શુભ બપોર,';
  @override
  String get greetingEvening => 'શુભ સાંજ,';
  @override
  String get whereGoing => 'તમે ક્યાં જઈ રહ્યા છો?';
  @override
  String get findRide => 'રાઇડ શોધો';
  @override
  String get createRide => 'રાઇડ બનાવો';
  @override
  String get pickupLocation => 'પિકઅપ સ્થળ';
  @override
  String get dropoffLocation => 'ડ્રોપઑફ સ્થળ';
  @override
  String get today => 'આજે';
  @override
  String get time => 'સમય';
  @override
  String get passengers => 'મુસાફરો';
  @override
  String get searchRides => 'રાઇડ્સ શોધો';
  @override
  String get quickActions => 'ઝડપી ક્રિયાઓ';
  @override
  String get offerRide => 'રાઇડ ઑફર કરો';
  @override
  String get availableRides => 'ઉપલબ્ધ રાઇડ્સ';
  @override
  String get recentRides => 'તાજેતરની રાઇડ્સ';
  @override
  String get activeRides => 'સક્રિય રાઇડ્સ';
  @override
  String get noRidesAvailable => 'કોઈ રાઇડ ઉપલબ્ધ નથી';
  @override
  String get driverDirectory => 'ડ્રાઇવર ડિરેક્ટરી';

  @override
  String get pickupLocationHint => 'પિકઅપ સ્થળ';
  @override
  String get dropoffDestinationHint => 'ડ્રોપઑફ સ્થળ';
  @override
  String get date => 'તારીખ';
  @override
  String get requiredSeats => 'જરૂરી સીટો';
  @override
  String get maxFare => 'મહત્તમ ભાડું';
  @override
  String get filters => 'ફિલ્ટર્સ';
  @override
  String get clearFilters => 'ફિલ્ટર્સ સાફ કરો';
  @override
  String get resetFilters => 'ફિલ્ટર્સ રીસેટ કરો';
  @override
  String get applyFilters => 'ફિલ્ટર્સ લાગુ કરો';
  @override
  String get womenOnlyRides => 'માત્ર મહિલાઓ માટે રાઇડ્સ';
  @override
  String get sortBy => 'આ મુજબ ક્રમબદ્ધ કરો';
  @override
  String get earliestDeparture => 'સૌથી વહેલું પ્રસ્થાન';
  @override
  String get lowestFare => 'સૌથી ઓછું ભાડું';
  @override
  String get highestRated => 'સૌથી વધુ રેટિંગ';
  @override
  String get noRidesFoundTitle => 'કોઈ રાઇડ મળી નથી';
  @override
  String get noRidesFoundSubtitle => 'તમારા શોધ માપદંડ બદલવાનો પ્રયાસ કરો';

  @override
  String get publishRide => 'રાઇડ પ્રકાશિત કરો';
  @override
  String get route => 'રૂટ';
  @override
  String get pickupPoint => 'પિકઅપ પોઇન્ટ';
  @override
  String get selectPickupLocation => 'પિકઅપ સ્થળ પસંદ કરો';
  @override
  String get dropoffDestination => 'ડ્રોપઑફ સ્થળ';
  @override
  String get selectDropoffLocation => 'ડ્રોપઑફ સ્થળ પસંદ કરો';
  @override
  String get dateTime => 'તારીખ અને સમય';
  @override
  String get capacityPricing => 'ક્ષમતા અને ભાડું';
  @override
  String get availableSeats => 'ઉપલબ્ધ સીટો';
  @override
  String get farePerSeat => 'સીટ દીઠ ભાડું (₹)';
  @override
  String get recommendedFare => 'ભલામણ કરેલ';
  @override
  String get womenOnlyRide => 'માત્ર મહિલાઓ માટે રાઇડ';
  @override
  String get womenOnlyRideDesc =>
      'માત્ર મહિલા મુસાફરો જ આ રાઇડમાં જોડાઈ શકે છે';
  @override
  String get additionalDetailsOptional => 'વધારાની વિગતો (વૈકલ્પિક)';
  @override
  String get vehicleNumber => 'વાહન નંબર';
  @override
  String get vehicleNumberHint => 'દા.ત. GJ 01 AB 1234';
  @override
  String get rideDescription => 'રાઇડ વર્ણન';
  @override
  String get addNotesPassengers => 'મુસાફરો માટે નોંધ ઉમેરો';
  @override
  String get ridePublishedSuccess => 'રાઇડ સફળતાપૂર્વક પ્રકાશિત થઈ!';

  @override
  String get rideDetails => 'રાઇડ વિગતો';
  @override
  String get driver => 'ડ્રાઇવર';
  @override
  String get routeDetails => 'રૂટ';
  @override
  String get seatsLeft => 'સીટો બાકી';
  @override
  String get bookRide => 'રાઇડ બુક કરો';
  @override
  String get requestSeat => 'સીટની વિનંતી કરો';
  @override
  String get cancelRequest => 'વિનંતી રદ કરો';
  @override
  String get chatWithDriver => 'ડ્રાઇવર સાથે વાત કરો';
  @override
  String get rideFull => 'રાઇડ ભરેલી છે';
  @override
  String get rideCompleted => 'રાઇડ પૂર્ણ';
  @override
  String get rideCancelled => 'રાઇડ રદ';
  @override
  String get thisIsYourOwnRide => 'આ તમારી પોતાની રાઇડ છે';
  @override
  String get rideAlreadyCompleted => 'રાઇડ પહેલાથી જ પૂર્ણ થઈ ગઈ છે';
  @override
  String get rideWasCancelled => 'રાઇડ રદ કરવામાં આવી હતી';
  @override
  String get rideAlreadyDeparted => 'રાઇડ પહેલાથી જ ઉપડી ગઈ છે';
  @override
  String get noSeatsAvailable => 'કોઈ સીટ ઉપલબ્ધ નથી';
  @override
  String get pendingApproval => 'મંજૂરી બાકી';
  @override
  String get requestSentSuccess => 'વિનંતી સફળતાપૂર્વક મોકલવામાં આવી!';

  @override
  String get myActivity => 'મારી પ્રવૃત્તિ';
  @override
  String get requests => 'વિનંતીઓ';
  @override
  String get filterAll => 'બધા';
  @override
  String get filterOffered => 'ઑફર કરેલી';
  @override
  String get filterBooked => 'બુક કરેલી';
  @override
  String get filterCompleted => 'પૂર્ણ';
  @override
  String get filterCancelled => 'રદ';
  @override
  String get cancelRide => 'રાઇડ રદ કરો';
  @override
  String get completeRide => 'રાઇડ પૂર્ણ કરો';
  @override
  String get cancelRideConfirm =>
      'શું તમે ખરેખર આ રાઇડ રદ કરવા માંગો છો?';
  @override
  String get noRidesFound => 'કોઈ રાઇડ મળી નથી';

  @override
  String get incomingRequests => 'આવેલી વિનંતીઓ';
  @override
  String get accept => 'સ્વીકારો';
  @override
  String get reject => 'અસ્વીકારો';
  @override
  String get accepted => 'સ્વીકારેલ';
  @override
  String get rejected => 'અસ્વીકારેલ';
  @override
  String get pending => 'બાકી';
  @override
  String get noRequestsFound => 'કોઈ વિનંતી મળી નથી';

  @override
  String get typeMessage => 'સંદેશ લખો...';
  @override
  String get online => 'ઑનલાઇન';
  @override
  String get offline => 'ઑફલાઇન';
  @override
  String get noMessagesYet => 'હજી સુધી કોઈ સંદેશ નથી';
  @override
  String get sayHi => 'વાતચીત શરૂ કરવા માટે હાય કહો!';
  @override
  String get rideChat => 'રાઇડ ચેટ';

  @override
  String get markAllAsRead => 'બધા વાંચેલા તરીકે ચિહ્નિત કરો';
  @override
  String get clearAll => 'બધા સાફ કરો';
  @override
  String get noNotifications => 'હજી સુધી કોઈ સૂચના નથી';
  @override
  String get noNotificationsSubtitle =>
      'તમારી રાઇડ્સ અને ચેટ્સના અપડેટ્સ માટે જોડાયેલા રહો';

  @override
  String get editProfile => 'પ્રોફાઇલ સંપાદિત કરો';
  @override
  String get personalInfo => 'વ્યક્તિગત માહિતી';
  @override
  String get ridesOffered => 'ઑફર કરેલી રાઇડ્સ';
  @override
  String get ridesTaken => 'લીધેલી રાઇડ્સ';
  @override
  String get rating => 'રેટિંગ';
  @override
  String get reviews => 'સમીક્ષાઓ';
  @override
  String get logOut => 'લૉગ આઉટ';
  @override
  String get logOutConfirmTitle => 'લૉગ આઉટ';
  @override
  String get logOutConfirmMessage => 'શું તમે ખરેખર લૉગ આઉટ કરવા માંગો છો?';
  @override
  String get deleteAccount => 'ખાતું કાઢી નાખો';
  @override
  String get deleteAccountConfirm =>
      'શું તમે ખરેખર તમારું ખાતું કાઢી નાખવા માંગો છો? આ ક્રિયા કાયમી છે અને તમારો તમામ ડેટા, રાઇડ્સ અને સેટિંગ્સ કાઢી નાખશે.';
  @override
  String get verifiedDriver => 'ચકાસાયેલ ડ્રાઇવર';
  @override
  String get searchDrivers => 'ડ્રાઇવર શોધો...';
  @override
  String get noDriversFound => 'કોઈ ડ્રાઇવર મળ્યા નથી';
  @override
  String get call => 'કૉલ';
  @override
  String get whatsapp => 'WhatsApp';

  @override
  String get settings => 'સેટિંગ્સ';
  @override
  String get preferences => 'પસંદગીઓ';
  @override
  String get darkMode => 'ડાર્ક મોડ';
  @override
  String get pushNotifications => 'પુશ સૂચનાઓ';
  @override
  String get emailNotifications => 'ઇમેઇલ સૂચનાઓ';
  @override
  String get language => 'ભાષા';
  @override
  String get securityPrivacy => 'સુરક્ષા અને ગોપનીયતા';
  @override
  String get security => 'સુરક્ષા';
  @override
  String get privacySettings => 'ગોપનીયતા સેટિંગ્સ';
  @override
  String get about => 'વિશે';
  @override
  String get aboutAutoShare => 'AutoShare વિશે';
  @override
  String get helpSupport => 'મદદ અને સપોર્ટ';
  @override
  String get termsConditions => 'નિયમો અને શરતો';
  @override
  String get privacyPolicy => 'ગોપનીયતા નીતિ';
  @override
  String get selectAppLanguage => 'ઍપની ભાષા પસંદ કરો';
  @override
  String get languageSubtext =>
      'તમારી પસંદગીની ભાષા પસંદ કરો. સમગ્ર ઍપ તરત જ અપડેટ થઈ જશે.';
  @override
  String get languageUpdated => 'ભાષા સફળતાપૂર્વક અપડેટ થઈ';

  @override
  String get rateYourRide => 'તમારી રાઇડને રેટ કરો';
  @override
  String get howWasRide => 'તમારી રાઇડ કેવી રહી?';
  @override
  String get addReviewOptional => 'સમીક્ષા ઉમેરો (વૈકલ્પિક)';

  @override
  String get pleaseEnterEmail => 'કૃપા કરીને તમારો ઇમેઇલ દાખલ કરો';
  @override
  String get enterValidEmail => 'માન્ય ઇમેઇલ સરનામું દાખલ કરો';
  @override
  String get pleaseEnterPassword => 'કૃપા કરીને તમારો પાસવર્ડ દાખલ કરો';
  @override
  String get passwordMinLength => 'પાસવર્ડ ઓછામાં ઓછો 6 અક્ષરોનો હોવો જોઈએ';
  @override
  String get pleaseEnterName => 'કૃપા કરીને તમારું નામ દાખલ કરો';
  @override
  String get pleaseEnterPhone => 'કૃપા કરીને તમારો ફોન નંબર દાખલ કરો';
  @override
  String get enterValidPhone => '10 અંકનો માન્ય ફોન નંબર દાખલ કરો';
  @override
  String get passwordsDoNotMatch => 'પાસવર્ડ મેળ ખાતા નથી';
  @override
  String get acceptTermsPrompt =>
      'આગળ વધવા માટે કૃપા કરીને સેવાની શરતો અને ગોપનીયતા નીતિ સ્વીકારો.';
  @override
  String get selectPickupError => 'કૃપા કરીને પિકઅપ સ્થળ પસંદ કરો';
  @override
  String get selectDropoffError => 'કૃપા કરીને ડ્રોપઑફ સ્થળ પસંદ કરો';
  @override
  String get genericError => 'એક ભૂલ આવી. કૃપા કરીને ફરી પ્રયાસ કરો.';

  @override
  String get yesterday => 'ગઈકાલે';
  @override
  String get earlier => 'અગાઉ';
  @override
  String get selectAll => 'બધું પસંદ કરો';
  @override
  String get deselectAll => 'બધું નાપસંદ કરો';
  @override
  String get selectedCountText => 'પસંદ કરેલ';
  @override
  String get markAsRead => 'વાંચેલું તરીકે ચિહ્નિત કરો';
  @override
  String get markAsUnread => 'ન વાંચેલું તરીકે ચિહ્નિત કરો';
  @override
  String get account => 'ખાતું';
  @override
  String get rideActivity => 'રાઇડ પ્રવૃત્તિ';
  @override
  String get created => 'બનાવેલ';
  @override
  String get joined => 'જોડાયેલ';
  @override
  String get completed => 'પૂર્ણ થયેલ';
  @override
  String get passwordAndSecurity => 'પાસવર્ડ અને સુરક્ષા';
  @override
  String get emailAndVerification => 'ઇમેઇલ અને ચકાસણી';
  @override
  String get verified => 'ચકાસાયેલ';
  @override
  String get unverified => 'બિનચકાસાયેલ';
  @override
  String get aboutAndSupport => 'વિશે અને સહાય';
  @override
  String get accountActions => 'ખાતાની ક્રિયાઓ';
  @override
  String get typing => 'ટાઇપ કરી રહ્યાં છે...';
  @override
  String get startConversation => 'વાતચીત શરૂ કરો';
  @override
  String get noChatsSubtitle => 'ડ્રાઇવરો અને સવારો સાથેની વાતચીત અહીં દેખાશે.';
}
