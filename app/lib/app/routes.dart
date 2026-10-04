import 'package:flutter/material.dart';

import '../data/models.dart';
import '../features/auth/auth_success_screen.dart';
import '../features/auth/create_password_screen.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/auth/identity_verification_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/personal_details_screen.dart';
import '../features/auth/sign_up_screen.dart';
import '../features/auth/verify_code_screen.dart';
import '../features/auth/account_blocked_screen.dart';
import '../features/auth/location_gate_screen.dart';
import '../features/chat/all_chats_screen.dart';
import '../features/credits/credits_screen.dart';
import '../features/wallet/certificates_screen.dart';
import '../features/wallet/wallet_screen.dart';
import '../features/requests/post_request_screen.dart';
import '../features/requests/request_detail_screen.dart';
import '../features/requests/requests_screen.dart';
import '../features/item/detail_extras.dart';
import '../features/post/list_item_screen.dart';
import '../features/post/upgrade_screens.dart';
import '../features/profile/edit_profile_screen.dart';
import '../features/listings/my_listings_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/settings/business_settings.dart';
import '../features/settings/change_password_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/support/support_screens.dart';
import '../features/settings/verification_flows.dart';
import '../features/chat/chat_screen.dart';
import '../features/transactions/transaction_screen.dart';
import '../features/transactions/transactions_screen.dart';
import '../features/item/item_detail_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/search/search_screen.dart';
import '../features/shell/main_shell.dart';
import '../features/splash/splash_screen.dart';

/// Central route table. Add each new screen here as it is built.
class Routes {
  Routes._();

  static const splash = '/';
  static const onboarding = '/onboarding';
  static const signUp = '/sign-up';
  static const logIn = '/log-in';
  static const forgotPassword = '/forgot-password';
  static const locationGate = '/location-gate';
  static const accountBlocked = '/account-blocked';
  static const verifyCode = '/verify-code';
  static const authSuccess = '/auth-success';
  static const personalDetails = '/personal-details';
  static const identityVerification = '/identity-verification';
  static const createPassword = '/create-password';
  static const home = '/home';
  static const search = '/search';
  static const notifications = '/notifications';
  static const itemDetail = '/item-detail';
  static const serviceDetail = '/service-detail';
  static const borrowRequest = '/borrow-request';
  static const lenderProfile = '/lender-profile';
  static const chat = '/chat';
  static const allChats = '/all-chats';
  static const listItem = '/list-item';
  static const postService = '/post-service';
  static const upgrade = '/upgrade';
  static const profile = '/profile';
  static const userSettings = '/settings';
  static const myListings = '/my-listings';
  static const businessDetails = '/business-details';
  static const companyDetails = '/company-details';
  static const confirmPhone = '/confirm-phone';
  static const changeEmail = '/change-email';
  static const changeLanguage = '/change-language';
  static const chatToggle = '/chat-toggle';
  static const feedbackToggle = '/feedback-toggle';
  static const manageNotifications = '/manage-notifications';
  static const changePassword = '/change-password';
  static const deleteAccount = '/delete-account';
  static const editProfile = '/edit-profile';
  static const support = '/support';
  static const supportChat = '/support-chat';
  static const pricing = '/pricing';
  static const transaction = '/transaction';
  static const transactions = '/transactions';
  static const credits = '/credits';
  static const requests = '/requests';
  static const postRequest = '/post-request';
  static const requestDetail = '/request-detail';
  static const wallet = '/wallet';
  static const certificates = '/certificates';

  static Route<dynamic> generate(RouteSettings settings) {
    final Widget page;
    switch (settings.name) {
      case splash:
        page = const SplashScreen();
        break;
      case onboarding:
        page = const OnboardingScreen();
        break;
      case logIn:
        page = const LoginScreen();
        break;
      case home:
        page = const MainShell();
        break;
      case search:
        page = const SearchScreen();
        break;
      case notifications:
        page = const NotificationsScreen();
        break;
      case itemDetail:
        page = ItemDetailScreen(product: settings.arguments as Product);
        break;
      case borrowRequest:
        final prod = settings.arguments as Product;
        page = ChatScreen(
            args: ChatArgs(
                Person(
                    id: prod.ownerId,
                    name: prod.ownerName,
                    avatar: prod.ownerAvatar ?? '',
                    verified: prod.ownerVerified),
                product: prod));
        break;
      case chat:
        final a = settings.arguments;
        page = ChatScreen(
            args: a is ChatArgs
                ? a
                : ChatArgs(a is Person ? a : const Person(name: '')));
        break;
      case transaction:
        page = TransactionScreen(txId: settings.arguments as String);
        break;
      case transactions:
        page = const TransactionsScreen();
        break;
      case wallet:
        page = const WalletScreen();
        break;
      case certificates:
        page = const CertificatesScreen();
        break;
      case credits:
        page = const CreditsScreen();
        break;
      case requests:
        page = const RequestsScreen();
        break;
      case postRequest:
        page = const PostRequestScreen();
        break;
      case requestDetail:
        page = RequestDetailScreen(id: settings.arguments as String);
        break;
      case confirmPhone:
        page = const ConfirmPhoneScreen();
        break;
      case changeEmail:
        page = const ChangeEmailScreen();
        break;
      case changePassword:
        page = const ChangePasswordScreen();
        break;
      case support:
        page = const SupportScreen();
        break;
      case supportChat:
        page = const SupportChatScreen();
        break;
      case deleteAccount:
        page = const DeleteAccountScreen();
        break;
      case userSettings:
        page = const SettingsScreen();
        break;
      case changeLanguage:
        page = const ChangeLanguageScreen();
        break;
      case chatToggle:
        page = const SingleToggleScreen(chat: true);
        break;
      case feedbackToggle:
        page = const SingleToggleScreen(chat: false);
        break;
      case manageNotifications:
        page = const ManageNotificationScreen();
        break;
      case businessDetails:
        page = const BusinessDetailsScreen();
        break;
      case companyDetails:
        page = const CompanyDetailsScreen();
        break;
      case myListings:
        page = const MyListingsScreen();
        break;
      case editProfile:
        page = const EditProfileScreen();
        break;
      case profile:
        page = const ProfileScreen();
        break;
      case upgrade:
        page = const UpgradeIntroScreen();
        break;
      case pricing:
        page = const PricingPlansScreen();
        break;
      case listItem:
        page = const ListItemScreen();
        break;
      case allChats:
        page = const AllChatsScreen();
        break;
      case serviceDetail:
        final sv = settings.arguments;
        page = sv is ServiceItem
            ? ServiceDetailScreen(service: sv)
            : const SplashScreen();
        break;
      case lenderProfile:
        final lp = settings.arguments;
        page = lp is Person
            ? LenderProfileScreen(person: lp)
            : const SplashScreen();
        break;
      case postService:
        page = const ListItemScreen(requestService: true);
        break;
      case signUp:
        page = const SignUpScreen();
        break;
      case accountBlocked:
        page = const AccountBlockedScreen();
        break;
      case locationGate:
        page = const LocationGateScreen();
        break;
      case verifyCode:
        page = VerifyCodeScreen(
            args: settings.arguments as VerifyCodeArgs? ??
                const VerifyCodeArgs(''));
        break;
      case authSuccess:
        final sa = settings.arguments;
        page = sa is AuthSuccessArgs
            ? AuthSuccessScreen(args: sa)
            : const SplashScreen();
        break;
      case createPassword:
        final a = settings.arguments;
        page = a is VerifyCodeArgs
            ? CreatePasswordScreen(email: a.email, reset: a.reset)
            : CreatePasswordScreen(email: a as String? ?? '');
        break;
      case personalDetails:
        page = const PersonalDetailsScreen();
        break;
      case identityVerification:
        page =
            IdentityVerificationScreen(onboarding: settings.arguments != false);
        break;
      case forgotPassword:
        page = const ForgotPasswordScreen();
        break;
      default:
        page = const SplashScreen();
    }
    return _fade(page, settings);
  }

  static PageRouteBuilder<T> _fade<T>(Widget page, RouteSettings settings) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 380),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        final curved =
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}
