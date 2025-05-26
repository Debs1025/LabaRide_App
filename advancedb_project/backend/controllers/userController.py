from database.connection import create_connection
import bcrypt
from datetime import datetime, timedelta
import jwt

class UserController:
    def get_user_details(self, user_id):
        try:
            supabase = create_connection()
            response = supabase.table('users').select('*').eq('id', user_id).single().execute()
            
            if not response.data:
                return {'status': 404, 'message': 'User not found'}
            
            return {
                'status': 200,
                'message': 'User details retrieved successfully',
                'user': response.data
            }
        except Exception as e:
            return {'status': 500, 'message': str(e)}

    def update_profile(self, user_id, data):
        try:
            supabase = create_connection()
            
            # Get existing user data
            existing_user = supabase.table('users').select('name, email').eq('id', user_id).single().execute()
            
            if not existing_user.data:
                return {'status': 404, 'message': 'User not found'}

            # Use existing values if new ones are not provided
            name = data.get('name') if data.get('name') is not None else existing_user.data['name']
            email = data.get('email') if data.get('email') is not None else existing_user.data['email']
            
            # Handle birthdate formatting
            birthdate = data.get('birthdate')
            if birthdate:
                try:
                    clean_date = birthdate.split('T')[0]
                    datetime.strptime(clean_date, '%Y-%m-%d')
                    formatted_date = clean_date
                except ValueError:
                    return {'status': 400, 'message': 'Invalid date format. Use YYYY-MM-DD'}
            else:
                formatted_date = None

            update_data = {
                'name': name,
                'email': email,
                'phone': data.get('phone'),
                'birthdate': formatted_date,
                'gender': data.get('gender'),
                'zone': data.get('zone'),
                'street': data.get('street'),
                'barangay': data.get('barangay'),
                'building': data.get('building')
            }
            
            supabase.table('users').update(update_data).eq('id', user_id).execute()
            
            return {'status': 200, 'message': 'Profile updated successfully'}
                    
        except Exception as e:
            return {'status': 500, 'message': str(e)}

    def update_password(self, user_id, data):
        try:
            supabase = create_connection()
            
            # Get user password
            user = supabase.table('users').select('password').eq('id', user_id).single().execute()
            
            if not user.data:
                return {'status': 404, 'message': 'User not found'}
                
            if not bcrypt.checkpw(data['current_password'].encode('utf-8'), 
                                user.data['password'].encode('utf-8')):
                return {'status': 401, 'message': 'Current password is incorrect'}
            
            hashed_password = bcrypt.hashpw(data['new_password'].encode('utf-8'), 
                                        bcrypt.gensalt())
            
            supabase.table('users').update({
                'password': hashed_password.decode('utf-8')
            }).eq('id', user_id).execute()
            
            return {'status': 200, 'message': 'Password updated successfully'}
                    
        except Exception as e:
            return {'status': 500, 'message': str(e)}

    def signup(self, data):
        try:
            supabase = create_connection()
            
            # Create user with Supabase auth
            auth_response = supabase.auth.sign_up({
                'email': data['email'],
                'password': data['password'],
                'data': {
                    'name': data['name'],
                    'is_shop_owner': False
                }
            })
            
            if 'error' in auth_response:
                return {
                    'status': 400,
                    'message': auth_response['error']['message']
                }
                
            user = auth_response['user']
            
            # Insert additional user data
            user_data = {
                'id': user['id'],
                'name': data['name'].strip(),
                'email': data['email'].strip(),
                'is_shop_owner': False
            }
            
            supabase.table('users').insert(user_data).execute()
            
            return {
                'status': 201,
                'message': 'User registered successfully',
                'user_id': user['id'],
                'token': auth_response['access_token']
            }
                
        except Exception as e:
            print(f"Signup error: {str(e)}")
            return {'status': 500, 'message': str(e)}

    def delete_account(self, user_id):
        try:
            supabase = create_connection()
            
            user = supabase.table('users').select('id').eq('id', user_id).execute()
            if not user.data:
                return {'status': 404, 'message': 'User not found'}
                
            supabase.table('users').delete().eq('id', user_id).execute()
            return {'status': 200, 'message': 'Account deleted successfully'}
                
        except Exception as e:
            return {'status': 500, 'message': str(e)}

    def register_shop(self, user_id, shop_data):
        try:
            supabase = create_connection()
            
            # Check if user has a shop
            existing_shop = supabase.table('shops').select('id').eq('user_id', user_id).execute()
            if existing_shop.data:
                return {'status': 400, 'message': 'User already has a shop'}
            
            shop_data['user_id'] = user_id
            response = supabase.table('shops').insert(shop_data).execute()
            shop_id = response.data[0]['id']
            
            # Add services
            services = shop_data.get('services', [])
            if services:
                service_data = [{
                    'shop_id': shop_id,
                    'service_name': service['service_name'],
                    'price': service['price']
                } for service in services]
                supabase.table('shop_services').insert(service_data).execute()
            
            # Update user to shop owner
            supabase.table('users').update({
                'is_shop_owner': True
            }).eq('id', user_id).execute()
            
            return {
                'status': 201,
                'message': 'Shop registered successfully',
                'shop_id': shop_id
            }
                
        except Exception as e:
            return {'status': 500, 'message': str(e)}