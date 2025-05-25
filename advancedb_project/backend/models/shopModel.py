from database.connection import create_connection

class ShopModel:
    def __init__(self):
        pass

    def get_shop_by_user(self, user_id):
        try:
            supabase = create_connection()
            response = supabase.table('shops')\
                .select('*, shop_services(*)')\
                .eq('user_id', user_id)\
                .execute()
            return response.data
        except Exception as e:
            print(f"Error getting shop: {e}")
            return None

    def update_shop_details(self, shop_id, data):
        try:
            supabase = create_connection()
            response = supabase.table('shops')\
                .update({
                    'shop_name': data['shop_name'],
                    'contact_number': data['contact_number'],
                    'zone': data['zone'],
                    'street': data['street'],
                    'barangay': data['barangay'],
                    'building': data.get('building'),
                    'opening_time': data['opening_time'],
                    'closing_time': data['closing_time']
                })\
                .eq('id', shop_id)\
                .execute()
            return True if response.data else False
        except Exception as e:
            print(f"Error updating shop: {e}")
            return False