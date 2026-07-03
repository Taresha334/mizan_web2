// MIZAN PLC: CONSOLIDATED PRODUCTION ROUTER (ARP-2026.06)
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Features & Shared
import '../../features/home/pages/home_page.dart';
import '../../features/nutrition/pages/nutrition_hub.dart';
import '../../features/education/pages/learning_hub.dart';
import '../../features/admin/pages/manage_categories_page.dart';
import '../../features/about/about_page.dart';
import '../../features/contact/pages/contact_page.dart';
import '../../features/farmers/pages/mizan_expert_advisors_page.dart';
import '../../features/farmers/pages/mizan_agent_map_page.dart';
import '../../features/auth/portal_login_page.dart';
import '../../features/auth/pages/profile_setup_page.dart';
import '../../features/marketplace/pages/market_explorer.dart';
import '../../features/marketplace/pages/listing_details_page.dart';
import '../../features/marketplace/non_partner_hub.dart';
import '../../features/agents/agent_hub.dart';
import '../../features/agents/pages/agent_portal.dart';
import '../../features/agents/pages/agent_application_form.dart';
import '../../features/agents/pages/application_status_page.dart';
import '../../features/home/pages/sell_on_mizan_hub.dart';
import '../../features/admin/pages/admin_dashboard.dart';
import '../../features/admin/pages/admin_approval_hub.dart';
import '../../features/admin/pages/payout_management.dart';
import '../../features/admin/pages/payment_verification_hub.dart';
import '../../features/admin/pages/admin_direct_post.dart';
import '../../features/admin/pages/admin_agent_creator.dart';
import '../../features/admin/pages/admin_orders_page.dart';
import '../../features/admin/pages/order_details_page.dart';
import '../../features/admin/pages/payment_audit_hub.dart';
import '../../features/admin/pages/unified_price_manager.dart';
import '../../features/admin/pages/moderation_hub.dart';
import '../../features/admin/pages/user_management.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../shared/layouts/main_layout.dart'; // Ensure this is imported

class AppRouterRefreshStream extends ChangeNotifier {
  AppRouterRefreshStream(Stream<dynamic> stream, AuthProvider? customAuth) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
    customAuth?.addListener(notifyListeners);
  }
  late final StreamSubscription<dynamic> _subscription;
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class AppRouter {
  static final rootNavigatorKey = GlobalKey<NavigatorState>();
  static final shellNavigatorKey = GlobalKey<NavigatorState>();
  static final adminShellNavigatorKey = GlobalKey<NavigatorState>();

  static AuthProvider? authProviderRef;

  static void setAuthProvider(AuthProvider provider) {
    authProviderRef = provider;
  }

  static final router = GoRouter(
    debugLogDiagnostics: true,
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: AppRouterRefreshStream(
      Supabase.instance.client.auth.onAuthStateChange,
      authProviderRef,
    ),
    redirect: (context, state) async {
      final String location = state.matchedLocation;
      final bool isCustomAuth = authProviderRef?.isCustomAuthenticated ?? false;
      final bool hasActiveSession =
          Supabase.instance.client.auth.currentSession != null || isCustomAuth;

      if (location.startsWith('/admin') &&
          (!hasActiveSession || authProviderRef?.customRole != 'admin')) {
        return '/login';
      }
      return null;
    },
    routes: [
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) =>
            MainLayout(child: child), // Use MainLayout
        routes: [
          GoRoute(path: '/', builder: (context, state) => const HomePage()),
          GoRoute(
            path: '/marketplace',
            builder: (context, state) => const MarketExplorer(),
          ),
          GoRoute(
            path: '/mizan-map',
            builder: (context, state) => const MizanAgentMapPage(),
          ),
          GoRoute(
            path: '/agent-hub',
            builder: (context, state) => const AgentHub(),
          ),
          GoRoute(
            path: '/non-partner-post',
            builder: (context, state) => const NonPartnerHub(),
          ),

          // Additional Pages that should share the shell
          GoRoute(
            path: '/nutrition',
            builder: (context, state) => const NutritionHub(),
          ),
          GoRoute(
            path: '/education',
            builder: (context, state) => const LearningHub(),
          ),
          GoRoute(
            path: '/about',
            builder: (context, state) => const AboutPage(),
          ),
          GoRoute(
            path: '/contact',
            builder: (context, state) => const ContactPage(),
          ),
          GoRoute(
            path: '/sell-hub',
            builder: (context, state) => const SellOnMizanHub(),
          ),
          GoRoute(
            path: '/expert-advisors',
            builder: (context, state) => const MizanExpertAdvisorsPage(),
          ),
          GoRoute(
            path: '/listing-details',
            builder: (context, state) => ListingDetailsPage(
              product: state.extra as Map<String, dynamic>,
            ),
          ),

          ShellRoute(
            navigatorKey: adminShellNavigatorKey,
            builder: (context, state, subChild) =>
                AdminDashboard(child: subChild),
            routes: [
              GoRoute(
                path: '/admin',
                redirect: (_, __) => '/admin/manage-products',
              ),
              GoRoute(
                path: '/admin/manage-products',
                builder: (context, state) => const ModerationHub(),
              ),
              GoRoute(
                path: '/admin/agents',
                builder: (context, state) => const UserManagement(),
              ),
              GoRoute(
                path: '/admin/approvals',
                builder: (context, state) => const AdminApprovalHub(),
              ),
              GoRoute(
                path: '/admin/prices',
                builder: (context, state) => const UnifiedPriceManager(),
              ),
              GoRoute(
                path: '/admin/payments',
                builder: (context, state) => const PaymentVerificationHub(),
              ),
              GoRoute(
                path: '/admin/audit',
                builder: (context, state) => const PaymentAuditHub(),
              ),
              GoRoute(
                path: '/admin/post-product',
                builder: (context, state) => const AdminDirectPost(),
              ),
              GoRoute(
                path: '/admin/payouts',
                builder: (context, state) => const PayoutManagement(),
              ),
              GoRoute(
                path: '/admin/add-agent',
                builder: (context, state) => const AdminAgentCreator(),
              ),
              GoRoute(
                path: '/admin/orders',
                builder: (context, state) => const AdminOrdersPage(),
              ),
              GoRoute(
                path: '/admin/order-details',
                builder: (context, state) => OrderDetailsPage(
                  order: state.extra as Map<String, dynamic>,
                ),
              ),
              GoRoute(
                path: '/admin/manage-categories',
                builder: (context, state) => const ManageCategoriesPage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const PortalLoginPage(),
      ),
      GoRoute(
        path: '/agent-portal',
        builder: (context, state) => const AgentPortal(),
      ),
      GoRoute(
        path: '/agent-application',
        builder: (context, state) => const AgentApplicationForm(),
      ),
      GoRoute(
        path: '/application-status',
        builder: (context, state) => const ApplicationStatusPage(),
      ),
      GoRoute(
        path: '/setup-profile',
        builder: (context, state) => const ProfileSetupPage(),
      ),
      GoRoute(
        path: '/post-product',
        redirect: (context, state) => (authProviderRef?.customRole == 'admin')
            ? '/admin/post-product'
            : '/agent-hub',
      ),
      GoRoute(path: '/my-submissions', redirect: (_, __) => '/agent-hub'),
    ],
  );
}
