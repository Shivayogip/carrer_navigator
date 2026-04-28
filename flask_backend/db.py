import os
import uuid
import hashlib
from supabase import create_client, Client

SUPABASE_URL = os.environ.get("SUPABASE_URL")
SUPABASE_KEY = os.environ.get("SUPABASE_KEY")
BUCKET_NAME = "pdf-reports"

if not SUPABASE_URL or not SUPABASE_KEY:
    print("WARNING: Supabase credentials not found in environment.")

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY) if SUPABASE_URL and SUPABASE_KEY else None

def upload_pdf_to_storage(user_id, report_type, pdf_bytes):
    """Uploads PDF bytes to Supabase Storage and returns the public URL."""
    try:
        from datetime import datetime
        filename = f"{user_id}/{report_type}_{int(datetime.now().timestamp())}.pdf"
        
        if not supabase:
            print("Error: Supabase client not initialized.")
            return None

        # Upload
        supabase.storage.from_(BUCKET_NAME).upload(
            filename, 
            pdf_bytes, 
            {"content-type": "application/pdf", "upsert": "true"}
        )
        
        # Get public URL
        url = supabase.storage.from_(BUCKET_NAME).get_public_url(filename)
        return url
    except Exception as e:
        import traceback
        traceback.print_exc()
        print(f"Error uploading PDF to storage ({report_type}): {e}")
        return None

def hash_password(password):
    return hashlib.sha256(password.encode()).hexdigest()

def create_user(email, password, name=""):
    try:
        user_id = str(uuid.uuid4())
        pwd_hash = hash_password(password) if password else ""
        data, count = supabase.table('users').insert({
            "id": user_id,
            "email": email,
            "password_hash": pwd_hash,
            "name": name
        }).execute()
        return user_id, None
    except Exception as e:
        if "duplicate key value violates unique constraint" in str(e).lower() or "already exists" in str(e).lower() or "duplicate" in str(e).lower() or "duplicate key" in str(e).lower() or "23505" in str(e):
            return None, "User already exists, please sign in"
        return None, str(e)

def verify_user(email, password):
    pwd_hash = hash_password(password)
    try:
        response = supabase.table('users').select('id, name').eq('email', email).eq('password_hash', pwd_hash).execute()
        if response.data and len(response.data) > 0:
            return response.data[0]['id'], response.data[0].get('name', '')
    except Exception as e:
        print(f"Error verifying user: {e}")
    return None, None

def create_session(user_id):
    token = str(uuid.uuid4())
    try:
        supabase.table('sessions').insert({
            "token": token,
            "user_id": user_id
        }).execute()
        return token
    except Exception as e:
        print(f"Error creating session: {e}")
    return token

def get_user_from_token(token):
    if not token:
        return None
    try:
        response = supabase.table('sessions').select('user_id').eq('token', token).execute()
        if response.data and len(response.data) > 0:
            return response.data[0]['user_id']
    except Exception as e:
        print(f"Error fetching session: {e}")
    return None

def get_or_create_google_user(email, name):
    try:
        response = supabase.table('users').select('id, name').eq('email', email).execute()
        if response.data and len(response.data) > 0:
            return response.data[0]['id'], response.data[0].get('name', name)
    except Exception as e:
        print(f"Error fetching user: {e}")
    
    user_id, err = create_user(email, "", name)
    return user_id, name

def save_user_data(user_id, resume_text=None, skills=None, role=None, score=None, 
                   target_company=None, career_path=None, career_roadmap=None, 
                   missing_skills=None, project_recommendations=None,
                   resume_analysis_url=None, career_path_url=None, 
                   career_roadmap_url=None, project_recommendations_url=None,
                   resume_builder_url=None):
    try:
        data = {"user_id": user_id}
        
        if resume_text is not None: data["resume_text"] = resume_text
        if skills is not None: data["skills"] = skills
        if role is not None: data["role"] = role
        if score is not None: data["score"] = score
        if target_company is not None: data["target_company"] = target_company
        if career_path is not None: data["career_path"] = career_path
        if career_roadmap is not None: data["career_roadmap"] = career_roadmap
        if missing_skills is not None: data["missing_skills"] = missing_skills
        if project_recommendations is not None: data["project_recommendations"] = project_recommendations
        
        # New PDF URL fields
        if resume_analysis_url is not None: data["resume_analysis_url"] = resume_analysis_url
        if career_path_url is not None: data["career_path_url"] = career_path_url
        if career_roadmap_url is not None: data["career_roadmap_url"] = career_roadmap_url
        if project_recommendations_url is not None: data["project_recommendations_url"] = project_recommendations_url
        if resume_builder_url is not None: data["resume_builder_url"] = resume_builder_url

        # Try updating first
        response = supabase.table('user_data').update(data).eq('user_id', user_id).execute()
        
        # If no rows updated, it means the record doesn't exist, so we insert
        if not response.data or len(response.data) == 0:
            supabase.table('user_data').insert(data).execute()
    except Exception as e:
        print(f"Error saving user data: {e}")

def log_daily_task(user_id, task_desc):
    try:
        from datetime import datetime
        today = datetime.now().strftime('%Y-%m-%d')
        
        # Log the task
        supabase.table('daily_tasks').insert({
            "user_id": user_id,
            "task_desc": task_desc,
            "is_completed": True
        }).execute()
        
        # Update streak logic
        user_data = supabase.table('user_data').select('current_streak, last_activity_date').eq('user_id', user_id).execute()
        
        final_streak = 1
        if user_data.data and len(user_data.data) > 0:
            last_date_str = user_data.data[0].get('last_activity_date')
            current_streak = user_data.data[0].get('current_streak', 0)
            
            if last_date_str == today:
                final_streak = current_streak
            else:
                from datetime import timedelta
                # Try parsing the date, safely handling types
                try:
                    last_date = datetime.strptime(str(last_date_str), '%Y-%m-%d')
                    yesterday = datetime.now() - timedelta(days=1)
                    
                    if last_date_str == yesterday.strftime('%Y-%m-%d'):
                        final_streak = current_streak + 1
                    else:
                        # Missed a day, start new streak at 1
                        final_streak = 1
                except (ValueError, TypeError):
                    final_streak = 1
                    
                supabase.table('user_data').update({
                    "current_streak": final_streak,
                    "last_activity_date": today
                }).eq('user_id', user_id).execute()
        else:
            final_streak = 1
            supabase.table('user_data').upsert({
                "user_id": user_id,
                "current_streak": final_streak,
                "last_activity_date": today
            }).execute()
            
        # Check and Award Badges based on streak
        check_and_award_badges(user_id, final_streak)
        
        return True
    except Exception as e:
        import traceback
        traceback.print_exc()
        print(f"Error logging daily task: {e}")
        return False

def check_and_award_badges(user_id, streak):
    try:
        # Milestone mapping
        milestones = {
            1: 'welcome',
            5: 'consistent',
            15: 'explorer',
            30: 'achiever'
        }
        
        for day, b_type in milestones.items():
            if streak >= day:
                award_badge(user_id, b_type)
    except Exception as e:
        print(f"Error in badge logic: {e}")

def award_badge(user_id, badge_type):
    try:
        # Check if already has it first to be safe, though UNIQUE constraint handles it
        supabase.table('user_badges').upsert({
            "user_id": user_id,
            "badge_type": badge_type
        }, on_conflict="user_id, badge_type").execute()
    except Exception as e:
        # Likely duplicate key which is fine
        pass

def get_user_badges(user_id):
    try:
        response = supabase.table('user_badges').select('badge_type').eq('user_id', user_id).execute()
        return [b['badge_type'] for b in response.data] if response.data else []
    except Exception as e:
        print(f"Error fetching badges: {e}")
        return []

def get_daily_tasks(user_id):
    try:
        from datetime import datetime
        today_start = datetime.now().strftime('%Y-%m-%dT00:00:00Z')
        # Simple string compare for basic implementation, or use supabase filter
        response = supabase.table('daily_tasks')\
            .select('id, task_desc, created_at')\
            .eq('user_id', user_id)\
            .gte('created_at', today_start)\
            .execute()
        return response.data
    except Exception as e:
        print(f"Error fetching daily tasks: {e}")
        return []

def get_user_data(user_id):
    try:
        user_response = supabase.table('users').select('email, name, mobile, course, branch, year, interest_field').eq('id', user_id).execute()
        if not user_response.data or len(user_response.data) == 0:
            return None
        
        user_info = user_response.data[0]
        
        data_response = supabase.table('user_data').select('resume_text, skills, role, score, current_streak, last_activity_date, target_company, career_path, career_roadmap, missing_skills, project_recommendations, resume_analysis_url, career_path_url, career_roadmap_url, project_recommendations_url, resume_builder_url').eq('user_id', user_id).execute()
        
        result = {
            "email": user_info.get("email"),
            "name": user_info.get("name"),
            "mobile": user_info.get("mobile"),
            "course": user_info.get("course"),
            "branch": user_info.get("branch"),
            "year": user_info.get("year"),
            "interest_field": user_info.get("interest_field"),
            "resume_text": None,
            "skills": None,
            "role": None,
            "score": None,
            "target_company": None,
            "career_path": None,
            "career_roadmap": None,
            "missing_skills": None,
            "project_recommendations": None,
            "resume_analysis_url": None,
            "career_path_url": None,
            "career_roadmap_url": None,
            "project_recommendations_url": None,
            "resume_builder_url": None,
            "current_streak": 0,
            "last_activity_date": None
        }
        
        if data_response.data and len(data_response.data) > 0:
            d = data_response.data[0]
            last_date_str = d.get("last_activity_date")
            current_streak = d.get("current_streak", 0)
            
            # Proactive Streak Reset Logic for the UI
            from datetime import datetime, timedelta
            today = datetime.now().strftime('%Y-%m-%d')
            yesterday = (datetime.now() - timedelta(days=1)).strftime('%Y-%m-%d')
            
            if last_date_str and last_date_str != today and last_date_str != yesterday:
                current_streak = 0
                # Optionally update DB here, but let's just return 0 for the UI first
                # to avoid unnecessary writes on every GET request.
            
            result.update({
                "resume_text": d.get("resume_text"),
                "skills": d.get("skills"),
                "role": d.get("role"),
                "score": d.get("score"),
                "target_company": d.get("target_company"),
                "career_path": d.get("career_path"),
                "career_roadmap": d.get("career_roadmap"),
                "missing_skills": d.get("missing_skills"),
                "project_recommendations": d.get("project_recommendations"),
                "resume_analysis_url": d.get("resume_analysis_url"),
                "career_path_url": d.get("career_path_url"),
                "career_roadmap_url": d.get("career_roadmap_url"),
                "project_recommendations_url": d.get("project_recommendations_url"),
                "resume_builder_url": d.get("resume_builder_url"),
                "current_streak": current_streak,
                "last_activity_date": last_date_str
            })
            
        result["badges"] = get_user_badges(user_id)
        return result
    except Exception as e:
        print(f"Error getting user data: {e}")
    return None

def update_user_profile(user_id, data):
    try:
        # data may contain: name, mobile, course, branch, year, interest_field
        supabase.table('users').update(data).eq('id', user_id).execute()
        return True, None
    except Exception as e:
        print(f"Error updating user profile: {e}")
        return False, str(e)

def change_password(user_id, current_password, new_password):
    try:
        # Verification: check if current password is correct
        pwd_hash = hash_password(current_password)
        user_response = supabase.table('users').select('id').eq('id', user_id).eq('password_hash', pwd_hash).execute()
        
        if not user_response.data or len(user_response.data) == 0:
            return False, "Current password is incorrect"
            
        # Update with new hash
        new_pwd_hash = hash_password(new_password)
        supabase.table('users').update({"password_hash": new_pwd_hash}).eq('id', user_id).execute()
        return True, None
    except Exception as e:
        print(f"Error changing password: {e}")
        return False, str(e)
