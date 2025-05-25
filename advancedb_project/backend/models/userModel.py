from database.connection import create_connection

class User:
    def __init__(self, name=None, email=None, password=None, phone=None, 
                 birthdate=None, gender=None, zone=None, street=None, 
                 barangay=None, building=None):
        self.name = name
        self.email = email
        self.password = password
        self.phone = phone
        self.birthdate = birthdate
        self.gender = gender
        self.zone = zone
        self.street = street
        self.barangay = barangay
        self.building = building

    def to_dict(self):
        return {
            'name': self.name,
            'email': self.email,
            'phone': self.phone,
            'birthdate': self.birthdate,
            'gender': self.gender,
            'zone': self.zone,
            'street': self.street,
            'barangay': self.barangay,
            'building': self.building,
            'is_shop_owner': False  
        }
    
    def get_user_shop(self, user_id):
        try:
            supabase = create_connection()
            response = supabase.table('shops')\
                .select('*')\
                .eq('user_id', user_id)\
                .single()\
                .execute()
            return response.data
        except Exception as e:
            print(f"Error getting user shop: {e}")
            return None

    def create_shop(self, user_id, shop_data):
        try:
            supabase = create_connection()
            
            # Insert shop data
            shop_insert = supabase.table('shops').insert({
                'user_id': user_id,
                'shop_name': shop_data['shop_name'],
                'contact_number': shop_data['contact_number'],
                'zone': shop_data['zone'],
                'street': shop_data['street'],
                'barangay': shop_data['barangay'],
                'building': shop_data.get('building'),
                'opening_time': shop_data['opening_time'],
                'closing_time': shop_data['closing_time']
            }).execute()
            
            shop_id = shop_insert.data[0]['id']
            
            # Update user to shop owner
            supabase.table('users')\
                .update({'is_shop_owner': True})\
                .eq('id', user_id)\
                .execute()
            
            return shop_id
        except Exception as e:
            print(f"Error creating shop: {e}")
            raise