import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

abstract class AppLocalizations {
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    delegate,
  ];

  static const List<Locale> supportedLocales = [
    Locale('en', ''),
    Locale('fr', ''),
  ];

  // Navigation
  String get home;
  String get courses;
  String get messages;
  String get profile;
  String get library;

  // Authentication
  String get signIn;
  String get signUp;
  String get email;
  String get password;
  String get confirmPassword;
  String get forgotPassword;
  String get resetPassword;
  String get login;
  String get register;
  String get logout;

  // Common
  String get welcome;
  String get search;
  String get cancel;
  String get confirm;
  String get save;
  String get edit;
  String get delete;
  String get back;
  String get next;
  String get previous;
  String get loading;
  String get error;
  String get success;
  String get retry;
  String get close;
  String get yes;
  String get no;

  // Profile
  String get editProfile;
  String get personalInfo;
  String get settings;
  String get language;
  String get notifications;
  String get privacy;
  String get about;

  // Courses
  String get myCourses;
  String get allCourses;
  String get enrolled;
  String get completed;
  String get inProgress;
  String get enroll;
  String get enrollment;
  String get instructor;
  String get duration;
  String get rating;
  String get price;
  String get free;
  String get premium;

  // Messages
  String get conversations;
  String get support;
  String get newMessage;
  String get typeMessage;
  String get sendMessage;

  // Payments
  String get payment;
  String get paymentMethod;
  String get mobileMoneyMTN;
  String get mobileMoneyOrange;
  String get bankTransfer;
  String get creditCard;
  String get phoneNumber;
  String get amount;
  String get total;
  String get orderNumber;
  String get paymentConfirmation;
  String get paymentSuccess;
  String get paymentFailed;

  // QR Code
  String get qrCode;
  String get generateQR;
  String get scanQR;
  String get shareQR;
  String get qrCodeGenerated;
  String get scanToEnroll;

  // Export
  String get export;
  String get exportProgress;
  String get exportCertificates;
  String get exportResults;
  String get downloadExcel;

  // Errors
  String get networkError;
  String get serverError;
  String get validationError;
  String get notFound;
  String get unauthorized;
  String get forbidden;

  // Language specific
  String get french;
  String get english;
  String get changeLanguage;
  String get languageChanged;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(_lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales.contains(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations _lookupAppLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    default:
      return AppLocalizationsFr(); // Default to French
  }
}