import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

class SupabaseService {
  static final supabase = Supabase.instance.client;
  static final String apiUrl = SupabaseConfig.apiUrl;

  // User methods
  static Future<bool> checkEmailExists(String email) async {
    try {
      final response = await supabase
          .from('users')
          .select('email')
          .eq('email', email)
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      return await supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();
    } catch (e) {
      throw Exception('Failed to fetch user profile: ${e.toString()}');
    }
  }

  static Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    try {
      await supabase
          .from('users')
          .update(data)
          .eq('id', userId);
    } catch (e) {
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  // Shop methods
  static Future<Map<String, dynamic>> createShop(Map<String, dynamic> shopData) async {
    try {
      return await supabase
          .from('shops')
          .insert(shopData)
          .select()
          .single();
    } catch (e) {
      throw Exception('Failed to create shop: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> updateShop(String shopId, Map<String, dynamic> data) async {
    try {
      return await supabase
          .from('shops')
          .update(data)
          .eq('id', shopId)
          .select()
          .single();
    } catch (e) {
      throw Exception('Failed to update shop: ${e.toString()}');
    }
  }

  // Shop Services methods
  static Future<Map<String, dynamic>> addShopService(Map<String, dynamic> serviceData) async {
    try {
      return await supabase
          .from('shop_services')
          .insert(serviceData)
          .select()
          .single();
    } catch (e) {
      throw Exception('Failed to add service: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> updateShopService(int serviceId, Map<String, dynamic> data) async {
    try {
      return await supabase
          .from('shop_services')
          .update(data)
          .eq('id', serviceId)
          .select()
          .single();
    } catch (e) {
      throw Exception('Failed to update service: ${e.toString()}');
    }
  }

  // Kilo Price methods
  static Future<Map<String, dynamic>> addKiloPrice(Map<String, dynamic> priceData) async {
    try {
      return await supabase
          .from('kilo_prices')
          .insert(priceData)
          .select()
          .single();
    } catch (e) {
      throw Exception('Failed to add kilo price: ${e.toString()}');
    }
  }

  // Transaction methods
  static Future<Map<String, dynamic>> updateTransactionStatus(String transactionId, String status) async {
    try {
      return await supabase
          .from('transactions')
          .update({'status': status})
          .eq('id', transactionId)
          .select()
          .single();
    } catch (e) {
      throw Exception('Failed to update transaction status: ${e.toString()}');
    }
  }

  static Future<List<Map<String, dynamic>>> getShopTransactions(String shopId) async {
    try {
      final response = await supabase
          .from('transactions')
          .select('*, users(*)')
          .eq('shop_id', shopId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch shop transactions: ${e.toString()}');
    }
  }

  // Real-time subscriptions for users
  static Stream<List<Map<String, dynamic>>> subscribeToUserTransactions(String userId) {
    return supabase
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at')
        .map((events) => List<Map<String, dynamic>>.from(events));
  }
}