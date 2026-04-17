import os
from dotenv import load_dotenv
from supabase import create_client, Client

load_dotenv(dotenv_path='flask_backend/.env')
SUPABASE_URL = os.environ.get("SUPABASE_URL")
SUPABASE_KEY = os.environ.get("SUPABASE_KEY")

print(f"URL: {SUPABASE_URL}")
print(f"KEY: {SUPABASE_KEY[:10]}...")

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

try:
    print("Testing select from 'users' table...")
    response = supabase.table('users').select('*').limit(1).execute()
    print("Success! Data:", response.data)
except Exception as e:
    print("Error during select:", str(e))

try:
    print("\nTesting insert into 'users' table...")
    test_id = "test-uuid"
    response = supabase.table('users').insert({
        "id": test_id,
        "email": "test@example.com",
        "password_hash": "test",
        "name": "Test User"
    }).execute()
    print("Success! Inserted:", response.data)
    # Clean up
    supabase.table('users').delete().eq('id', test_id).execute()
except Exception as e:
    print("Error during insert:", str(e))
