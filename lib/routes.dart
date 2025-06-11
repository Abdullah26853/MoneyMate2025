import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:receipt_manager/screens/add_update_receipt_page.dart';
import 'package:receipt_manager/screens/budget_page.dart';
import 'package:receipt_manager/screens/category_page.dart';
import 'package:receipt_manager/screens/summary_page.dart';

import 'screens/base_page.dart';
import 'screens/email_sent_page.dart';
import 'screens/forgot_password_page.dart';
import 'screens/home_page.dart';
import 'screens/login_page.dart';
import 'screens/receipt_list_page.dart';
import 'screens/settings_page.dart';
import 'screens/signup_page.dart';
import 'screens/verification_link_page.dart';
import 'screens/welcome_page.dart';
import 'screens/legal/terms_of_service_page.dart';
import 'screens/legal/privacy_policy_page.dart';

Map<String, WidgetBuilder> appRoutes = {
  WelcomePage.id: (context) => WelcomePage(),
  SignUpPage.id: (context) => SignUpPage(),
  VerificationLinkPage.id: (context) => VerificationLinkPage(
        user: FirebaseAuth.instance.currentUser!,
      ),
  LogInPage.id: (context) => LogInPage(),
  ForgotPasswordPage.id: (context) => ForgotPasswordPage(),
  EmailSentPage.id: (context) => EmailSentPage(email: ''),
  BasePage.id: (context) => BasePage(),
  HomePage.id: (context) => HomePage(),
  ReceiptListPage.id: (context) => ReceiptListPage(),
  AddOrUpdateReceiptPage.id: (context) => AddOrUpdateReceiptPage(),
  SettingsPage.id: (context) => SettingsPage(),
  CategoryPage.id: (context) => CategoryPage(),
  BudgetPage.id: (context) => BudgetPage(),
  SummaryPage.id: (context) => SummaryPage(),
  TermsOfServicePage.id: (context) => TermsOfServicePage(),
  PrivacyPolicyPage.id: (context) => PrivacyPolicyPage(),
};
