import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()

def create_connection():
    try:
        supabase_url = 'https://xpspoikdajgvuepywjna.supabase.co'
        supabase_key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhwc3BvaWtkYWpndnVlcHl3am5hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU5OTE2MjgsImV4cCI6MjA2MTU2NzYyOH0.frGwcjiqeGhBaIa-VKF8vi1TlK4SyyCOPSWfiXYTZGY'
        return create_client(supabase_url, supabase_key)
    except Exception as e:
        print(f"Error connecting to Supabase: {e}")
        raise