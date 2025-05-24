import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()

def create_connection():
    try:
        supabase_url = os.getenv('SUPABASE_URL')
        supabase_key = os.getenv('SUPABASE_ANON_KEY')

        if not supabase_url or not supabase_key:
            raise ValueError("Supabase credentials not found in environment variables")
            
        supabase = create_client(supabase_url, supabase_key)
        print("Successfully connected to Supabase")
        return supabase
    except Exception as e:
        print(f"Error connecting to Supabase: {e}")
        raise