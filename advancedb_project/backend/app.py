from flask import Flask, request, jsonify
from flask_cors import CORS
from controllers.userController import UserController
from controllers.transactionController import TransactionController
from database.connection import create_connection
from functools import wraps
import jwt
import os
from flask_socketio import SocketIO, emit, join_room 
from datetime import datetime, timedelta
from decimal import Decimal
import json

app = Flask(__name__)
CORS(app)
socketio = SocketIO(app, cors_allowed_origins="*", async_mode='threading')
app.config['SECRET_KEY'] = os.getenv('JWT_SECRET_KEY', 'labaride102504')

@app.route('/test-connection', methods=['GET'])
def test_connection():
    try:
        supabase = create_connection()
        response = supabase.table('users').select('count').execute()
        return jsonify({'message': 'Connection successful', 'data': response.data}), 200
    except Exception as e:
        return jsonify({'error': f'Connection failed: {str(e)}'}), 500
    
# Initialize controllers
user_controller = UserController()
transaction_controller = TransactionController()

# Socket event handlers
@socketio.on('connect')
def handle_connect():
    print('Client connected')
    supabase = create_connection()
    # Subscribe to real-time changes
    supabase.table('transactions').on('INSERT', lambda payload: 
        socketio.emit('new_transaction', payload.new_record)
    ).subscribe()
    return True

@socketio.on('disconnect')
def handle_disconnect():
    print('Client disconnected')

@socketio.on('join_shop_room')
def handle_join_shop(data):
    shop_id = data.get('shop_id')
    if shop_id:
        join_room(f"shop_{shop_id}")
        emit('room_joined', {'room': f"shop_{shop_id}"})
        print(f"Shop {shop_id} joined room")

@socketio.on('join_user_room')
def handle_join_user(data):
    user_id = data.get('user_id')
    if user_id:
        join_room(f"user_{user_id}")
        emit('room_joined', {'room': f"user_{user_id}"})
        print(f"User {user_id} joined room")

# JWT decorator for protected routes
def jwt_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = request.headers.get('Authorization')
        
        if not token:
            return jsonify({'message': 'Token is missing'}), 401
            
        try:
            if ' ' not in token:
                return jsonify({'message': 'Invalid token format'}), 401
                
            scheme, token = token.split(' ')
            if scheme.lower() != 'bearer':
                return jsonify({'message': 'Invalid authentication scheme'}), 401

            # Debug prints
            print(f"Debug - Token being decoded: {token}")
            print(f"Debug - Secret key being used: {app.config['SECRET_KEY']}")
            
            data = jwt.decode(
                token, 
                app.config['SECRET_KEY'],
                algorithms=["HS256"]
            )
            
            print(f"Debug - Decoded token data: {data}")
            
            request.user = data
            return f(*args, **kwargs)
            
        except jwt.InvalidTokenError as e:
            print(f"Debug - Token error: {str(e)}")
            return jsonify({'message': f'Token is invalid: {str(e)}'}), 401
            
    return decorated

@app.route('/verify_token', methods=['POST'])
def verify_token():
    token = request.headers.get('Authorization')
    if not token:
        return jsonify({'valid': False, 'message': 'No token provided'}), 401
        
    try:
        scheme, token = token.split(' ')
        if scheme.lower() != 'bearer':
            return jsonify({'valid': False, 'message': 'Invalid token format'}), 401
            
        decoded = jwt.decode(token, app.config['SECRET_KEY'], algorithms=["HS256"])
        return jsonify({
            'valid': True,
            'user_id': decoded.get('user_id'),
            'email': decoded.get('email')
        })
    except Exception as e:
        return jsonify({'valid': False, 'message': str(e)}), 401

# User Routes
@app.route('/signup', methods=['POST'])
def signup():
    try:
        data = request.get_json()
        supabase = create_connection()
        
        # Create complete user data
        user = {
            'name': data['name'],
            'email': data['email'],
            'password': data['password'],
            'phone': data.get('phone', ''),
            'zone': data.get('zone', ''),
            'street': data.get('street', ''),
            'barangay': data.get('barangay', ''),
            'building': data.get('building', ''),
            'gender': data.get('gender', ''),
            'is_shop_owner': False
        }
        
        # Insert into users table first
        response = supabase.table('users').insert(user).execute()
        
        if response.data:
            # Then create auth user
            auth_response = supabase.auth.sign_up({
                'email': data['email'],
                'password': data['password'],
                'data': {
                    'name': data['name']
                }
            })
            
            return jsonify({
                'message': 'User created successfully',
                'user_id': response.data[0]['id']
            }), 201
            
        return jsonify({'error': 'Failed to create user'}), 500
        
    except Exception as e:
        print(f"Signup error: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/login', methods=['POST'])
def login():
    try:
        result = user_controller.login(request.json)
        return jsonify(result), result['status']
    except Exception as e:
        return jsonify({'status': 500, 'message': str(e)}), 500

@app.route('/user/<int:user_id>', methods=['GET'])
@jwt_required
def get_user(user_id):
    try:
        result = user_controller.get_user_details(user_id)
        return jsonify(result), result['status']
    except Exception as e:
        return jsonify({'status': 500, 'message': str(e)}), 500

@app.route('/update_user_details/<int:user_id>', methods=['PUT'])
@jwt_required
def update_user_details(user_id):
    try:
        result = user_controller.update_profile(user_id, request.json)
        return jsonify(result), result['status']
    except Exception as e:
        return jsonify({'status': 500, 'message': str(e)}), 500

@app.route('/update_password/<int:user_id>', methods=['PUT'])
@jwt_required
def update_password(user_id):
    try:
        result = user_controller.update_password(user_id, request.json)
        return jsonify(result), result['status']
    except Exception as e:
        return jsonify({'status': 500, 'message': str(e)}), 500

@app.route('/delete_account/<int:user_id>', methods=['DELETE'])
@jwt_required
def delete_account(user_id):
    result = user_controller.delete_account(user_id)
    return jsonify(result), result['status']


# Shop Routes
@app.route('/register_shop/<int:user_id>', methods=['POST'])
@jwt_required
def register_shop(user_id):
    try:
        data = request.json
        if not data:
            return jsonify({'status': 400, 'message': 'No data provided'}), 400

        required_fields = ['shop_name', 'contact_number', 'zone', 'street', 
                         'barangay', 'opening_time', 'closing_time']
        
        # Validate required fields
        for field in required_fields:
            if field not in data:
                return jsonify({'status': 400, 'message': f'Missing {field}'}), 400

        supabase = create_connection()
        
        # Create shop
        shop_data = {
            'user_id': user_id,
            'shop_name': data['shop_name'],
            'contact_number': data['contact_number'],
            'zone': data['zone'],
            'street': data['street'],
            'barangay': data['barangay'],
            'building': data.get('building'),
            'opening_time': data['opening_time'],
            'closing_time': data['closing_time']
        }
        
        response = supabase.table('shops').insert(shop_data).execute()
        shop_id = response.data[0]['id']

        # Update user to shop owner
        supabase.table('users').update({
            'is_shop_owner': True
        }).eq('id', user_id).execute()
        
        return jsonify({
            'status': 201,
            'message': 'Shop registered successfully',
            'shop_id': shop_id
        }), 201

    except Exception as e:
        return jsonify({'status': 500, 'message': f'Error: {str(e)}'}), 500

@app.route('/shops', methods=['GET'])
def get_shops():
    try:
        supabase = create_connection()
        response = supabase.table('shops')\
            .select('*, users!inner(name, email), shop_services(*)')\
            .execute()
        return jsonify({"shops": response.data}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/shops/recent', methods=['GET'])
def get_recent_shops():
    try:
        supabase = create_connection()
        response = supabase.table('shops')\
            .select('id, shop_name, contact_number, zone, street, barangay, building, opening_time, closing_time, created_at')\
            .order('created_at', desc=True)\
            .limit(10)\
            .execute()
        return jsonify(response.data), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500     
            
@app.route('/shop/<int:shop_id>', methods=['GET'])
@jwt_required
def get_shop_by_id(shop_id):
    try:
        supabase = create_connection()
        response = supabase.table('shops')\
            .select('id, shop_name, contact_number, zone, street, barangay, building, opening_time, closing_time, created_at')\
            .eq('id', shop_id)\
            .single()\
            .execute()
            
        if not response.data:
            return jsonify({'message': 'Shop not found'}), 404

        shop = response.data
        # Format datetime for JSON
        if 'created_at' in shop:
            shop['created_at'] = datetime.fromisoformat(shop['created_at']).strftime('%Y-%m-%d %H:%M:%S')
            
        return jsonify(shop)
        
    except Exception as e:
        print(f"Error fetching shop {shop_id}: {str(e)}")
        return jsonify({'error': str(e)}), 500
            
# Transaction Routes
@app.route('/create_transaction/<int:user_id>', methods=['POST'])
@jwt_required
def create_transaction(user_id):
    try:
        result = transaction_controller.create_transaction(user_id, request.json)
        if result['status'] == 201:
            shop_id = request.json['shop_id']
            transaction_data = {
                'transaction_id': result['transaction_id'],
                'user_id': user_id,
                'shop_id': shop_id,
                'service_name': request.json.get('service_name'),
                'items': request.json.get('items', []),
                'status': 'Pending',
                'total_amount': request.json['total_amount'],
                'created_at': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            }
            
            # Emit to both shop and user rooms
            socketio.emit('new_transaction', transaction_data, room=f"shop_{shop_id}")
            socketio.emit('transaction_update', transaction_data, room=f"user_{user_id}")
            
        return jsonify(result), result['status']
    except Exception as e:
        print(f"Error in create_transaction: {str(e)}")
        return jsonify({'status': 500, 'message': str(e)}), 500

@app.route('/user_transactions/<int:user_id>', methods=['GET'])
@jwt_required
def get_user_transactions(user_id):
    try:
        supabase = create_connection()
        response = supabase.table('transactions')\
            .select('*, shops(shop_name)')\
            .eq('user_id', user_id)\
            .order('created_at', desc=True)\
            .execute()
            
        transactions = response.data
        return jsonify({'status': 'success', 'data': transactions}), 200
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/shop_transactions/<int:shop_id>', methods=['GET'])
@jwt_required
def get_shop_transactions(shop_id):
    try:
        supabase = create_connection()
        response = supabase.table('transactions')\
            .select('*, users!inner(name:customer_name, email:customer_email)')\
            .eq('shop_id', shop_id)\
            .order('created_at', desc=True)\
            .execute()
            
        transactions = response.data
        return jsonify({"transactions": transactions}), 200
    except Exception as e:
        print(f"Error fetching transactions: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/update_transaction_status/<string:transaction_id>', methods=['PUT'])
@jwt_required
def update_transaction_status(transaction_id):
    try:
        result = transaction_controller.update_transaction_status(
            transaction_id,
            request.json['status'],
            request.json.get('notes')
        )
        
        if result['status'] == 200:
            update_data = {
                'transaction_id': transaction_id,
                'status': request.json['status'],
                'notes': request.json.get('notes'),
                'total_amount': request.json.get('total_amount')
            }
            
            # Emit to both rooms
            socketio.emit('status_update', update_data, room=f"shop_{result['shop_id']}")
            socketio.emit('status_update', update_data, room=f"user_{result['user_id']}")
            
        return jsonify(result), result['status']
    except Exception as e:
        print(f"Error in update_transaction_status: {str(e)}")
        return jsonify({'status': 500, 'message': str(e)}), 500

@app.route('/cancel_transaction/<string:transaction_id>', methods=['PUT'])
@jwt_required
def cancel_transaction(transaction_id):
    try:
        result = transaction_controller.cancel_transaction(
            transaction_id,
            request.json.get('reason'),
            request.json.get('notes')
        )
        return jsonify(result), result['status']
    except Exception as e:
        return jsonify({'status': 500, 'message': str(e)}), 500

@app.route('/user/<int:user_id>/has_shop', methods=['GET'])
@jwt_required
def check_user_shop(user_id):
    try:
        supabase = create_connection()
        response = supabase.table('users')\
            .select('is_shop_owner')\
            .eq('id', user_id)\
            .single()\
            .execute()
            
        if response.data:
            return jsonify({
                'has_shop': response.data['is_shop_owner']
            }), 200
        return jsonify({'message': 'User not found'}), 404
    except Exception as e:
        return jsonify({"error": str(e)}), 500

#Service Routes
@app.route('/shop/<int:shop_id>/services', methods=['GET'])
@jwt_required
def get_shop_services(shop_id):
    try:
        supabase = create_connection()
        response = supabase.table('shop_services')\
            .select('id, service_name, color, price')\
            .eq('shop_id', shop_id)\
            .execute()
        return jsonify({'services': response.data}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/shop/<int:shop_id>/service', methods=['POST'])
@jwt_required
def add_shop_service(shop_id):
    try:
        data = request.json
        supabase = create_connection()
        
        service_data = {
            'shop_id': shop_id,
            'service_name': data['service_name'],
            'color': data['color'],
            'price': float(data.get('price', 0))
        }
        
        response = supabase.table('shop_services')\
            .insert(service_data)\
            .execute()
            
        return jsonify({'message': 'Service added successfully'}), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/shop/service/<int:service_id>', methods=['PUT', 'DELETE'])
@jwt_required
def manage_shop_service(service_id):
    try:
        supabase = create_connection()
        
        if request.method == 'DELETE':
            supabase.table('shop_services').delete().eq('id', service_id).execute()
            message = 'Service deleted successfully'
        else:
            data = request.json
            supabase.table('shop_services').update({
                'service_name': data['name'],
                'price': data['price']
            }).eq('id', service_id).execute()
            message = 'Service updated successfully'
            
        return jsonify({'message': message}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/shop/<int:shop_id>/household', methods=['GET', 'POST'])
@jwt_required
def manage_household_items(shop_id):
    try:
        supabase = create_connection()
        
        if request.method == 'GET':
            response = supabase.table('household_items')\
                .select('*')\
                .eq('shop_id', shop_id)\
                .execute()
            return jsonify({'items': response.data}), 200
            
        else:  # POST
            data = request.json
            # Check if item exists
            existing = supabase.table('household_items')\
                .select('id')\
                .eq('shop_id', shop_id)\
                .eq('item_name', data['name'])\
                .execute()
                
            if existing.data:
                return jsonify({
                    'message': 'Item already exists',
                    'item_id': existing.data[0]['id']
                }), 409

            response = supabase.table('household_items').insert({
                'shop_id': shop_id,
                'item_name': data['name'],
                'price': data['price']
            }).execute()
            return jsonify({'message': 'Item added successfully'}), 201
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/shop/<int:shop_id>/clothing', methods=['GET', 'POST'])
@jwt_required
def manage_clothing_types(shop_id):
    try:
        supabase = create_connection()
        
        if request.method == 'GET':
            response = supabase.table('clothing_types')\
                .select('*')\
                .eq('shop_id', shop_id)\
                .execute()
            return jsonify({'types': response.data}), 200
            
        else:  # POST
            data = request.json
            # Check if type exists
            existing = supabase.table('clothing_types')\
                .select('id')\
                .eq('shop_id', shop_id)\
                .eq('type_name', data['name'])\
                .execute()
                
            if existing.data:
                return jsonify({
                    'message': 'Type already exists',
                    'type_id': existing.data[0]['id']
                }), 409

            response = supabase.table('clothing_types').insert({
                'shop_id': shop_id,
                'type_name': data['name'],
                'price': data['price']
            }).execute()
            return jsonify({'message': 'Clothing type added successfully'}), 201
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/shop/household/<int:item_id>', methods=['PUT'])
@jwt_required
def update_household_item(item_id):
    try:
        data = request.json
        supabase = create_connection()
        
        supabase.table('household_items')\
            .update({'price': data['price']})\
            .eq('id', item_id)\
            .execute()
            
        return jsonify({'message': 'Item updated successfully'}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/shop/clothing/<int:type_id>', methods=['PUT'])
@jwt_required
def update_clothing_type(type_id):
    try:
        data = request.json
        supabase = create_connection()
        
        supabase.table('clothing_types')\
            .update({'price': data['price']})\
            .eq('id', type_id)\
            .execute()
            
        return jsonify({'message': 'Type updated successfully'}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Order System Routes
@app.route('/shop/services', methods=['GET'])
@jwt_required
def get_all_shop_services():
    try:
        supabase = create_connection()
        response = supabase.table('shop_services')\
            .select('id, service_name, price, color, description')\
            .eq('is_active', True)\
            .order('service_name')\
            .execute()
            
        services = [{**service, 'price': float(service['price'])} 
                   for service in response.data]
        
        return jsonify({'services': services}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/shop/items', methods=['GET'])
@jwt_required
def get_all_shop_items():
    try:
        supabase = create_connection()
        response = supabase.table('household_items')\
            .select('id, item_name, price')\
            .order('item_name')\
            .execute()
            
        items = [{**item, 'price': float(item['price'])} 
                for item in response.data]
        
        return jsonify({'items': items}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Kilo Price Routes
@app.route('/shop/<int:shop_id>/kilo-prices', methods=['GET'])
@jwt_required
def get_kilo_prices(shop_id):
    try:
        supabase = create_connection()
        response = supabase.table('kilo_prices')\
            .select('min_kilo, max_kilo, price_per_kilo')\
            .eq('shop_id', shop_id)\
            .execute()
            
        prices = [{
            'min_kilo': float(price['min_kilo']),
            'max_kilo': float(price['max_kilo']),
            'price_per_kilo': float(price['price_per_kilo'])
        } for price in response.data]
        
        return jsonify({'prices': prices}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    
@app.route('/shop/<int:shop_id>/kilo-price', methods=['POST'])
@jwt_required
def add_kilo_price(shop_id):
    try:
        data = request.json
        supabase = create_connection()

        # Check for overlapping ranges
        existing = supabase.table('kilo_prices')\
            .select('id')\
            .eq('shop_id', shop_id)\
            .gte('min_kilo', data['min_kilo'])\
            .lte('max_kilo', data['max_kilo'])\
            .execute()
            
        if existing.data:
            return jsonify({
                'error': 'This range overlaps with an existing range'
            }), 400
            
        response = supabase.table('kilo_prices').insert({
            'shop_id': shop_id,
            'min_kilo': data['min_kilo'],
            'max_kilo': data['max_kilo'],
            'price_per_kilo': data['price_per_kilo']
        }).execute()
        
        return jsonify({'message': 'Price range added successfully'}), 201
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/shop/<int:shop_id>/kilo-price', methods=['DELETE'])
@jwt_required
def delete_kilo_price(shop_id):
    try:
        data = request.json
        supabase = create_connection()
        
        supabase.table('kilo_prices')\
            .delete()\
            .eq('shop_id', shop_id)\
            .eq('min_kilo', data['min_kilo'])\
            .eq('max_kilo', data['max_kilo'])\
            .execute()
            
        return jsonify({'message': 'Price range deleted successfully'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500
            
@app.route('/api/orders', methods=['GET'])
@jwt_required
def get_orders():
    try:
        shop_id = request.args.get('shop_id')
        status = request.args.get('status')

        if not shop_id:
            return jsonify({'error': 'shop_id is required'}), 400

        supabase = create_connection()
        query = supabase.table('transactions').select('*').eq('shop_id', shop_id)
        
        if status:
            query = query.eq('status', status)
            
        response = query.order('created_at', desc=True).execute()
        orders = response.data

        return jsonify({'orders': orders}), 200

    except Exception as e:
        print(f"Error in /api/orders: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/orders/<int:order_id>/decline', methods=['PUT'])
@jwt_required
def decline_order(order_id):
    try:
        supabase = create_connection()
        supabase.table('transactions')\
            .update({'status': 'cancelled'})\
            .eq('id', order_id)\
            .execute()
        return jsonify({'message': 'Order declined successfully'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/api/orders/<int:order_id>/set_price', methods=['PUT'])
@jwt_required
def set_order_price(order_id):
    try:
        data = request.get_json()
        price_per_kilo = data.get('price_per_kilo')
        if price_per_kilo is None:
            return jsonify({'error': 'Missing price_per_kilo'}), 400

        supabase = create_connection()
        
        # Update transaction
        supabase.table('transactions')\
            .update({
                'price_per_kilo': price_per_kilo,
                'status': 'processing'
            })\
            .eq('id', order_id)\
            .execute()
            
        # Get transaction details
        transaction = supabase.table('transactions')\
            .select('user_id, shop_id')\
            .eq('id', order_id)\
            .single()\
            .execute()
            
        if not transaction.data:
            return jsonify({'error': 'Transaction not found'}), 404
            
        user_id = transaction.data['user_id']
        shop_id = transaction.data['shop_id']
        
        # Get shop name
        shop = supabase.table('shops')\
            .select('shop_name')\
            .eq('id', shop_id)\
            .single()\
            .execute()
            
        shop_name = shop.data['shop_name'] if shop.data else 'Shop'
        
        # Create notification
        notification_data = {
            'user_id': user_id,
            'message': f"The shop set the price per kilo to ₱{price_per_kilo} for your order.",
            'is_read': False,
            'from_name': shop_name
        }
        
        supabase.table('notifications').insert(notification_data).execute()
        
        return jsonify({'message': 'Price per kilo updated and user notified successfully'}), 200
    except Exception as e:
        print(f"Error in set_order_price: {e}")
        return jsonify({'error': str(e)}), 500
            
@app.route('/api/notifications/<int:user_id>', methods=['GET'])
@jwt_required
def get_notifications(user_id):
    try:
        supabase = create_connection()
        response = supabase.table('notifications')\
            .select('*')\
            .eq('user_id', user_id)\
            .order('created_at', desc=True)\
            .execute()
            
        notifications = response.data
        
        # Format datetime
        for n in notifications:
            if 'created_at' in n and n['created_at']:
                n['created_at'] = datetime.fromisoformat(n['created_at']).strftime('%Y-%m-%d %H:%M:%S')
                
        return jsonify({'notifications': notifications}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    try:
        print("Starting Flask-SocketIO server...")
        # For development
        if app.debug:
            socketio.run(app, debug=True, port=5000, allow_unsafe_werkzeug=True)
        # For production
        else:
            socketio.run(app, host='0.0.0.0', port=int(os.environ.get('PORT', 5000)))
    except Exception as e:
        print(f"Error starting server: {e}")