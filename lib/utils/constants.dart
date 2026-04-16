import '../services/api_config.dart';

class AppColors {
  // Premium tech-startup aesthetics (Deep Ocean Blue / Minimalist)
  static const primary = 0xFF2563EB; // Azure Blue
  static const primaryDark = 0xFF1E3A8A; // Deep Oceanic Blue
  static const accent = 0xFF10B981; // Emerald
  static const success = 0xFF10B981;
  static const warning = 0xFFF59E0B; // Amber
  static const error = 0xFFEF4444; // Ruby Red
  static const background = 0xFFF8FAFC; // Slate 50
  static const surface = 0xFFFFFFFF;
  static const textPrimary = 0xFF0F172A; // Slate 900
  static const textSecondary = 0xFF64748B; // Slate 500
  static const divider = 0xFFE2E8F0; // Slate 200
}

class AppStrings {
  // App
  static const appName = 'SmartSaving';
  static const appTagline = 'Smart Price Tracking';

  // Auth
  static const email = 'Email';
  static const password = 'Password';
  static const name = 'Full Name';
  static const login = 'Login';
  static const register = 'Register';
  static const logout = 'Logout';
  static const signUp = 'Sign Up';
  static const forgotPassword = 'Forgot Password?';
  static const dontHaveAccount = "Don't have an account? ";
  static const alreadyHaveAccount = 'Already have an account? ';
  static const noAccount = 'Create one now';

  // Products
  static const searchProducts = 'Search products...';
  static const noProducts = 'No products found';
  static const bestPrice = 'Best Price';
  static const priceComparison = 'Price Comparison';
  static const priceHistory = 'Price History';
  static const pricePrediction = 'Price Prediction';

  // Platforms
  static const amazon = 'Amazon';
  static const flipkart = 'Flipkart';

  // Tracking
  static const track = 'Track';
  static const untrack = 'Untrack';
  static const trackedProducts = 'Tracked Products';
  static const noTrackedProducts = 'No tracked products yet';
  static const addAlert = 'Set Price Alert';
  static const targetPrice = 'Target Price (₹)';

  // Notifications
  static const priceDropped = 'Price Dropped!';
  static const alertTriggered = 'Your price alert has been triggered';

  // General
  static const loading = 'Loading...';
  static const error = 'Error';
  static const retry = 'Retry';
  static const cancel = 'Cancel';
  static const save = 'Save';
  static const delete = 'Delete';
  static const settings = 'Settings';
  static const profile = 'Profile';
  static const home = 'Home';
}

class AppDimensions {
  static const paddingXS = 4.0;
  static const paddingS = 8.0;
  static const paddingM = 16.0;
  static const paddingL = 24.0;
  static const paddingXL = 32.0;

  static const borderRadiusS = 8.0;
  static const borderRadiusM = 12.0;
  static const borderRadiusL = 20.0;

  static const buttonHeight = 54.0; // Slightly larger, more premium bounds
  static const cardElevation = 0.0; // Use subtle box shadows manually or flat designs
}

class MockData {
  static const mockImageUrl =
      'https://via.placeholder.com/300x300?text=Product';
}

class AppConfig {
  static const String apiBaseUrl = ApiConfig.backendBaseUrl;
}
