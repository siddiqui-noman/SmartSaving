class AppColors {
  static const primary = 0xFF2196F3;
  static const primaryDark = 0xFF1976D2;
  static const accent = 0xFFFF5722;
  static const success = 0xFF4CAF50;
  static const warning = 0xFFFFC107;
  static const error = 0xFFE53935;
  static const background = 0xFFFAFAFA;
  static const surface = 0xFFFFFFFF;
  static const textPrimary = 0xFF212121;
  static const textSecondary = 0xFF757575;
  static const divider = 0xFFBDBDBD;
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

  static const borderRadiusS = 4.0;
  static const borderRadiusM = 8.0;
  static const borderRadiusL = 12.0;

  static const buttonHeight = 48.0;
  static const cardElevation = 2.0;
}

class MockData {
  static const mockImageUrl =
      'https://via.placeholder.com/300x300?text=Product';
}

class AppConfig {
  // Use 10.0.2.2 for Android Emulator, or your local machine IP (e.g., 10.10.13.128) for physical devices
  static const String apiBaseUrl = 'http://10.10.13.128:8000';
}
