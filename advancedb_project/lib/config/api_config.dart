class ApiConfig {
  // Environment configuration
  static const bool isProduction = true;
  
  // Base URLs for different environments
  static const String _devBaseUrl = 'http://localhost:5000';
  static const String _prodBaseUrl = 'https://backend-production-5974.up.railway.app';
  
  // Use production URL if in production mode, otherwise use development URL
  static String get baseUrl => isProduction ? _prodBaseUrl : _devBaseUrl;
  
  // API endpoints
  static String get loginUrl => '$baseUrl/login';
  static String get signupUrl => '$baseUrl/signup';
  static String getUserUrl(int userId) => '$baseUrl/user/$userId';
  static String getShopsUrl() => '$baseUrl/shops';
  static String getShopUrl(String shopId) => '$baseUrl/shop/$shopId';
  static String getShopServicesUrl(String shopId) => '$baseUrl/shop/$shopId/services';
  static String getShopClothingUrl(String shopId) => '$baseUrl/shop/$shopId/clothing';
  static String getShopHouseholdUrl(String shopId) => '$baseUrl/shop/$shopId/household';
  static String getNearbyShopsUrl(double lat, double lng) => '$baseUrl/nearby_shops?lat=$lat&lng=$lng';
  static String updateUserDetailsUrl(int userId) => '$baseUrl/update_user_details/$userId';
  static String getShopUserUrl(int userId) => '$baseUrl/shop/user/$userId';
  static String getTransactionUrl(String transactionId) => '$baseUrl/transactions/$transactionId';
  static String deleteTransactionUrl(String transactionId) => '$baseUrl/delete_transaction/$transactionId';
  static String getShopRegistrationUrl(int userId) => '$baseUrl/register_shop/$userId';
  static String getShopUpdateUrl(String shopId) => '$baseUrl/update_shop/$shopId';
  static String getShopDeleteUrl(String shopId) => '$baseUrl/delete_shop/$shopId';
  static String getShopOrdersUrl(String shopId) => '$baseUrl/shop/$shopId/orders';
  static String getShopReviewsUrl(String shopId) => '$baseUrl/shop/$shopId/reviews';
  static String getUserOrdersUrl(int userId) => '$baseUrl/user/$userId/orders';
  static String getUserReviewsUrl(int userId) => '$baseUrl/user/$userId/reviews';
  static String getCreateOrderUrl() => '$baseUrl/create_order';
  static String getUpdateOrderUrl(String orderId) => '$baseUrl/update_order/$orderId';
  static String getDeleteOrderUrl(String orderId) => '$baseUrl/delete_order/$orderId';
  static String getCreateReviewUrl() => '$baseUrl/create_review';
  static String getUpdateReviewUrl(String reviewId) => '$baseUrl/update_review/$reviewId';
  static String getDeleteReviewUrl(String reviewId) => '$baseUrl/delete_review/$reviewId';
  static String updateShopLocationUrl(String shopId) => '$baseUrl/update_shop_location/$shopId';
}