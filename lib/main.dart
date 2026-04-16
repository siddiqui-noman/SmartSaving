import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/product.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/price_history_screen.dart';
import 'screens/chat_screen.dart';
import 'utils/constants.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await notificationService.initialize();
  runApp(const ProviderScope(child: SmartSavingApp()));
}

class SmartSavingApp extends StatelessWidget {
  const SmartSavingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(AppColors.background),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(AppColors.primary),
          primary: const Color(AppColors.primary),
          secondary: const Color(AppColors.accent),
          error: const Color(AppColors.error),
          surface: const Color(AppColors.surface),
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.outfitTextTheme(),
        appBarTheme: const AppBarTheme(
          centerTitle: true, 
          elevation: 0,
          backgroundColor: Color(AppColors.background),
          foregroundColor: Color(AppColors.textPrimary),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingM,
            vertical: AppDimensions.paddingM,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.borderRadiusM),
            borderSide: const BorderSide(color: Color(AppColors.divider)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.borderRadiusM),
            borderSide: const BorderSide(color: Color(AppColors.divider)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(AppColors.primary),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.borderRadiusL),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingL,
              vertical: AppDimensions.paddingM,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(AppColors.primary),
            side: const BorderSide(color: Color(AppColors.primary), width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.borderRadiusL),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingL,
              vertical: AppDimensions.paddingM,
            ),
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(AppColors.surface),
          elevation: AppDimensions.cardElevation,
          margin: EdgeInsets.zero,
          shadowColor: Colors.black.withOpacity(0.04), // Soft ambient shadow
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.borderRadiusL),
            side: BorderSide(color: const Color(AppColors.divider).withOpacity(0.5)), // Sleek outline
          ),
        ),
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/product-detail') {
          final arguments = settings.arguments;
          if (arguments is Product) {
            return MaterialPageRoute(
              builder: (context) => ProductDetailScreen(
                productId: arguments.id,
                fallbackProduct: arguments,
              ),
            );
          } else if (arguments is String) {
            return MaterialPageRoute(
              builder: (context) => ProductDetailScreen(productId: arguments),
            );
          }
        }
        
        if (settings.name == '/price-history') {
          final productId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => PriceHistoryScreen(productId: productId),
          );
        }

        // --- UPDATED CHAT ROUTE ---
        if (settings.name == '/chat') {
          final args = settings.arguments;
          
          // Check if we passed a Product object (which is what we want)
          if (args is Product) {
            return MaterialPageRoute(
              builder: (context) => ChatScreen(product: args),
            );
          } 
          // If for some reason you still use ChatScreenArgs elsewhere, 
          // you'll need to remove that logic or update it here.
        }
        return null;
      },
    );
  }
}
