from database.connection import create_connection

class TransactionController:
    def create_transaction(self, user_id, data):
        try:
            supabase = create_connection()
            
            # Get user details
            user_response = supabase.table('users').select('*').eq('id', user_id).single().execute()
            user_data = user_response.data
            
            if not user_data:
                return {'status': 404, 'message': 'User not found'}

            transaction_data = {
                'user_id': user_id,
                'shop_id': data['shop_id'],
                'user_name': user_data['name'],
                'user_email': user_data['email'],
                'user_phone': user_data.get('phone', ''),
                'service_name': data['service_name'],
                'kilo_amount': float(data.get('kilo_amount', 0)),
                'subtotal': float(data['subtotal']),
                'delivery_fee': float(data['delivery_fee']),
                'voucher_discount': float(data['voucher_discount']),
                'total_amount': float(data['total_amount']),
                'delivery_type': data['delivery_type'],
                'zone': data['zone'],
                'street': data['street'],
                'barangay': data['barangay'],
                'building': data['building'],
                'scheduled_date': data['scheduled_date'],
                'scheduled_time': data['scheduled_time'],
                'payment_method': data.get('payment_method', 'Cash on Delivery'),
                'notes': data.get('notes', ''),
                'status': 'Pending'
            }

            response = supabase.table('transactions').insert(transaction_data).execute()
            
            return {
                'status': 201,
                'message': 'Transaction created successfully',
                'transaction_id': response.data[0]['id']
            }
        except Exception as e:
            print(f"Error creating transaction: {e}")
            return {'status': 500, 'message': str(e)}

    def get_transaction(self, transaction_id):
        try:
            supabase = create_connection()
            
            response = supabase.table('transactions')\
                .select('*, shops(*)').eq('id', transaction_id).single().execute()
            
            if not response.data:
                return {'status': 404, 'message': 'Transaction not found'}

            return {'status': 200, 'data': response.data}

        except Exception as e:
            return {'status': 500, 'message': str(e)}

    def cancel_transaction(self, transaction_id, reason=None, notes=None):
        try:
            supabase = create_connection()
            
            # Check if transaction exists
            transaction = supabase.table('transactions').select('id').eq('id', transaction_id).single().execute()
            
            if not transaction.data:
                return {'status': 404, 'message': 'Transaction not found'}
            
            cancel_note = f"Cancelled - {reason}: {notes}" if notes else f"Cancelled - {reason}"
            
            supabase.table('transactions').update({
                'status': 'Cancelled',
                'notes': cancel_note
            }).eq('id', transaction_id).execute()
            
            return {
                'status': 200,
                'message': 'Transaction cancelled successfully'
            }
                
        except Exception as e:
            print(f"Error cancelling transaction: {e}")
            return {'status': 500, 'message': str(e)}