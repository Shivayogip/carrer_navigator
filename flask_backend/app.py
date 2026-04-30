import os
from flask import Flask, request, jsonify
from flask_cors import CORS
from flask_mail import Mail, Message
from dotenv import load_dotenv
from ai_service import analyze_resume, chat_with_ai, analyze_github_profile
from parser import extract_text
import requests
import db
import pdf_generator
import json

load_dotenv()

app = Flask(__name__)
CORS(app) # Enable CORS for all routes

# Mail Configuration
app.config['MAIL_SERVER'] = os.getenv('MAIL_SERVER')
app.config['MAIL_PORT'] = int(os.getenv('MAIL_PORT', 587))
app.config['MAIL_USE_TLS'] = str(os.getenv('MAIL_USE_TLS', 'true')).lower() == 'true'
app.config['MAIL_USE_SSL'] = str(os.getenv('MAIL_USE_SSL', 'false')).lower() == 'true'
app.config['MAIL_USERNAME'] = os.getenv('MAIL_USERNAME')
app.config['MAIL_PASSWORD'] = os.getenv('MAIL_PASSWORD')
app.config['MAIL_DEFAULT_SENDER'] = os.getenv('MAIL_DEFAULT_SENDER')

mail = Mail(app)

@app.before_request
def log_request_info():
    print(f"Request: {request.method} {request.path}")

@app.route('/', methods=['GET'])
def health_check():
    return jsonify({"status": "healthy", "message": "Flask server is running"}), 200

@app.route('/api/resume/upload', methods=['POST'], strict_slashes=False)
def upload_resume():
    if 'resume' not in request.files:
        print("Error: No file uploaded")
        return jsonify({"error": "No file uploaded"}), 400
    
    file = request.files['resume']
    if file.filename == '':
        print("Error: No selected file")
        return jsonify({"error": "No selected file"}), 400
    
    try:
        print(f"Processing file: {file.filename}")
        
        # Extract text from resume
        text = extract_text(file)
        
        # AI Analysis using Gemini
        analysis = analyze_resume(text)
        analysis['resume_text'] = text
        
        # PROACTIVE SAVE: If token is provided, save resume text and skills immediately
        try:
            token = request.headers.get('Authorization', '').replace('Bearer ', '')
            user_id = db.get_user_from_token(token)
            if user_id:
                # Save extracted text and skills
                db.save_user_data(
                    user_id, 
                    resume_text=text, 
                    skills=json.dumps(analysis.get('skills', [])),
                    score=analysis.get('resume_score', 0)
                )
                print(f"Auto-saved resume for user {user_id}")
        except Exception as se:
            print(f"Auto-save failed: {se}")

        # Generate Analysis Report PDF (Already logic for this, keep it)
        try:
             # Construct a nice markdown for the report
             report_md = f"# Resume Analysis Report\n\n"
             report_md += f"## Score: {analysis.get('resume_score', 0)}/100\n\n"
             report_md += f"## Key Skills\n" + "\n".join([f"* {s}" for s in analysis.get('skills', [])]) + "\n\n"
             report_md += f"## Suggestions\n" + "\n".join([f"* {s}" for s in analysis.get('suggestions', [])]) + "\n\n"
             
             pdf_bytes = pdf_generator.generate_report_pdf("Resume Analysis Report", report_md)
             
             # If user is logged in, we'll save it. 
             # But this endpoint is often called BEFORE login or without a token.
             # The save_data endpoint will handle persistent storage.
             # For now, we just indicate it's ready.
        except Exception as pe:
             print(f"Error generating analysis PDF: {pe}")
        
        return jsonify(analysis)
    except Exception as e:
        print(f"Resume processing error: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/api/contact', methods=['POST'], strict_slashes=False)
def contact_form():
    try:
        data = request.get_json()
        user_email = data.get('email')
        message_content = data.get('message')
        
        if not user_email or not message_content:
            return jsonify({"error": "Email and message are required"}), 400
            
        target_email = os.getenv('CONTACT_TARGET_EMAIL', 'careernavigator28@gmail.com')
        
        print(f"DEBUG: Preparing email from {user_email} to {target_email}")
        
        msg = Message(
            subject=f"New Contact Form Submission from {user_email}",
            recipients=[target_email],
            body=f"You have received a new message from your career navigator app.\n\nFrom: {user_email}\n\nMessage:\n{message_content}",
            sender=app.config.get('MAIL_DEFAULT_SENDER')
        )
        
        print(f"DEBUG: Attempting to send mail via {app.config['MAIL_SERVER']}...")
        mail.send(msg)
        print(f"Contact email sent successfully to {target_email}")
        return jsonify({"status": "success", "message": "Email sent successfully"}), 200
    except Exception as e:
        import traceback
        traceback.print_exc()
        print(f"CRITICAL: Error sending contact email: {e}")
        return jsonify({"error": str(e), "type": type(e).__name__}), 500

@app.route('/api/ai/chat', methods=['POST'], strict_slashes=False)
def chat():
    try:
        data = request.get_json()
        message = data.get('message')
        history = data.get('history', [])
        
        print(f"Chat message received: {message}")
        
        if not message:
            return jsonify({"error": "Message is required"}), 400
        
        # history in python SDK is a list of content objects
        # [{"role": "user", "parts": ["..."]}, {"role": "model", "parts": ["..."]}]
        ai_response = chat_with_ai(message, history)
        return jsonify({"response": ai_response})
    except Exception as e:
        print(f"AI Assistant endpoint error: {str(e)}")
        return jsonify({"error": str(e)}), 500

@app.route('/api/auth/signup', methods=['POST'], strict_slashes=False)
def auth_signup():
    data = request.get_json()
    email = data.get('email')
    password = data.get('password')
    name = data.get('name', '')
    if not email or not password:
        return jsonify({"error": "Email and password required"}), 400
    user_id, error = db.create_user(email, password, name)
    if error:
        return jsonify({"error": error}), 400
    token = db.create_session(user_id)
    return jsonify({"token": token, "user": {"id": user_id, "email": email, "name": name}})

@app.route('/api/auth/login', methods=['POST'], strict_slashes=False)
def auth_login():
    data = request.get_json()
    email = data.get('email')
    password = data.get('password')
    user_id, name = db.verify_user(email, password)
    if user_id:
        token = db.create_session(user_id)
        return jsonify({"token": token, "user": {"id": user_id, "email": email, "name": name}})
    return jsonify({"error": "Invalid credentials"}), 401

@app.route('/api/auth/google', methods=['POST'], strict_slashes=False)
def auth_google():
    data = request.get_json()
    email = data.get('email')
    name = data.get('name', '')
    if not email:
        return jsonify({"error": "Email required"}), 400
    user_id, name = db.get_or_create_google_user(email, name)
    token = db.create_session(user_id)
    return jsonify({"token": token, "user": {"id": user_id, "email": email, "name": name}})

@app.route('/api/user/save_data', methods=['POST'], strict_slashes=False)
def user_save_data():
    token = request.headers.get('Authorization', '').replace('Bearer ', '')
    user_id = db.get_user_from_token(token)
    if not user_id:
        return jsonify({"error": "Unauthorized"}), 401
    
    data = request.get_json()
    resume_text = data.get('resume_text')
    skills = data.get('skills')
    role = data.get('role')
    score = data.get('score')
    target_company = data.get('target_company')
    career_path = data.get('career_path')
    career_roadmap = data.get('career_roadmap')
    missing_skills = data.get('missing_skills')
    project_recommendations = data.get('project_recommendations')
    
    # Persist data
    db.save_user_data(
        user_id, resume_text, skills, role, score,
        target_company=target_company,
        career_path=career_path,
        career_roadmap=career_roadmap,
        missing_skills=missing_skills,
        project_recommendations=project_recommendations
    )
    
    # PDF Generation for reports (Async-like logic or just sequential for now)
    pdf_urls = {}
    try:
        if career_path:
            pdf_bytes = pdf_generator.generate_report_pdf("Career Path Analysis", career_path)
            url = db.upload_pdf_to_storage(user_id, "career_path", pdf_bytes)
            if url: pdf_urls["career_path_url"] = url
            
        if career_roadmap:
            # If it's a list (structured), we need to handle it or assume it's markdown
            # Based on ResumeService.dart, it can be either.
            content = career_roadmap
            if isinstance(career_roadmap, list):
                content = "## Career Roadmap\n\n" + "\n".join([f"### Step {i+1}: {s.get('goal')} ({s.get('duration')})" for i, s in enumerate(career_roadmap)])
            
            pdf_bytes = pdf_generator.generate_report_pdf("Career Roadmap", content)
            url = db.upload_pdf_to_storage(user_id, "career_roadmap", pdf_bytes)
            if url: pdf_urls["career_roadmap_url"] = url
            
        if project_recommendations:
            pdf_bytes = pdf_generator.generate_report_pdf("Project Recommendations", project_recommendations)
            url = db.upload_pdf_to_storage(user_id, "projects", pdf_bytes)
            if url: pdf_urls["project_recommendations_url"] = url
            
        # Update DB with URLs
        if pdf_urls:
            db.save_user_data(user_id, **pdf_urls)
            
    except Exception as pe:
        import traceback
        traceback.print_exc()
        print(f"Error in automatic PDF generation: {pe}")

    return jsonify({
        "status": "success", 
        "urls": pdf_urls,
        "resume_analysis_url": pdf_urls.get('resume_analysis_url'),
        "career_path_url": pdf_urls.get('career_path_url'),
        "career_roadmap_url": pdf_urls.get('career_roadmap_url'),
        "project_recommendations_url": pdf_urls.get('project_recommendations_url'),
        "resume_builder_url": pdf_urls.get('resume_builder_url')
    })

@app.route('/api/user/data', methods=['GET'], strict_slashes=False)
def get_user_data():
    token = request.headers.get('Authorization', '').replace('Bearer ', '')
    user_id = db.get_user_from_token(token)
    if not user_id:
        return jsonify({"error": "Unauthorized"}), 401
    
    user_data = db.get_user_data(user_id)
    if user_data:
        return jsonify(user_data)
    return jsonify({"error": "No data found"}), 404

@app.route('/api/user/tasks', methods=['POST', 'GET'], strict_slashes=False)
def manage_tasks():
    token = request.headers.get('Authorization', '').replace('Bearer ', '')
    user_id = db.get_user_from_token(token)
    if not user_id:
        return jsonify({"error": "Unauthorized"}), 401
    
    if request.method == 'POST':
        data = request.get_json()
        task_desc = data.get('task_desc')
        if not task_desc:
            return jsonify({"error": "Task description is required"}), 400
        
        success = db.log_daily_task(user_id, task_desc)
        if success:
            # Return updated user data (including new streak)
            return jsonify({"status": "success", "user_data": db.get_user_data(user_id)})
        return jsonify({"error": "Failed to log task"}), 500
    else:
        # GET request
        tasks = db.get_daily_tasks(user_id)
        return jsonify(tasks)

@app.route('/api/user/profile', methods=['POST'], strict_slashes=False)
def update_profile():
    token = request.headers.get('Authorization', '').replace('Bearer ', '')
    user_id = db.get_user_from_token(token)
    if not user_id:
        return jsonify({"error": "Unauthorized"}), 401
    
    data = request.get_json()
    success, error = db.update_user_profile(user_id, data)
    if success:
        return jsonify({"status": "success"})
    return jsonify({"error": error}), 400

@app.route('/api/user/change-password', methods=['POST'], strict_slashes=False)
def update_password():
    token = request.headers.get('Authorization', '').replace('Bearer ', '')
    user_id = db.get_user_from_token(token)
    if not user_id:
        return jsonify({"error": "Unauthorized"}), 401
    
    data = request.get_json()
    current_password = data.get('current_password')
    new_password = data.get('new_password')
    
    if not current_password or not new_password:
        return jsonify({"error": "Current and new passwords are required"}), 400
        
    success, error = db.change_password(user_id, current_password, new_password)
    if success:
        return jsonify({"status": "success", "message": "Password updated successfully"})
    return jsonify({"error": error}), 400

@app.route('/api/github/analyze/<username>', methods=['GET'], strict_slashes=False)
def analyze_github(username):
    try:
        target_role = request.args.get('role', 'Full Stack Developer')
        print(f"Analyzing GitHub for: {username} (Target: {target_role})")
        
        # 1. Fetch Repositories
        repos_url = f"https://api.github.com/users/{username}/repos?sort=updated&per_page=15"
        repos_response = requests.get(repos_url)
        if repos_response.status_code != 200:
            return jsonify({"error": f"Failed to fetch GitHub repos: {repos_response.text}"}), repos_response.status_code
        repos = repos_response.json()
        
        # 2. Fetch Events (Activity)
        events_url = f"https://api.github.com/users/{username}/events?per_page=20"
        events_response = requests.get(events_url)
        events = events_response.json() if events_response.status_code == 200 else []
        
        # 3. AI Analysis
        analysis = analyze_github_profile(username, repos, events, target_role)
        return jsonify({"response": analysis})
        
    except Exception as e:
        print(f"GitHub endpoint error: {str(e)}")
        return jsonify({"error": str(e)}), 500

@app.route('/api/pdf/generate', methods=['POST'], strict_slashes=False)
def generate_pdf_direct():
    try:
        data = request.get_json()
        title = data.get('title', 'AI Career Report')
        content = data.get('content', '')
        
        print(f"Direct PDF generation request: {title}")
        pdf_out = pdf_generator.generate_report_pdf(title, content)
        
        # Handle string output (legacy fpdf) vs bytes (fpdf2)
        if isinstance(pdf_out, str):
            pdf_bytes = pdf_out.encode('latin-1')
        else:
            pdf_bytes = bytes(pdf_out)
            
        from flask import make_response
        response = make_response(pdf_bytes)
        response.headers.set('Content-Type', 'application/pdf')
        response.headers.set('Content-Disposition', 'attachment', filename=f"{title.replace(' ', '_')}.pdf")
        return response
    except Exception as e:
        import traceback
        traceback.print_exc()
        print(f"Direct PDF generation error: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/api/resume/export', methods=['POST'], strict_slashes=False)
def export_resume_direct():
    try:
        data = request.get_json()
        print(f"Direct Resume Export request for: {data.get('name')}")
        pdf_out = pdf_generator.generate_resume_pdf(data)
        
        if isinstance(pdf_out, str):
            pdf_bytes = pdf_out.encode('latin-1')
        else:
            pdf_bytes = bytes(pdf_out)
            
        from flask import make_response
        response = make_response(pdf_bytes)
        response.headers.set('Content-Type', 'application/pdf')
        response.headers.set('Content-Disposition', 'attachment', filename="resume.pdf")
        return response
    except Exception as e:
        import traceback
        traceback.print_exc()
        print(f"Direct Resume export error: {e}")
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    port = int(os.getenv("PORT", 5000))
    # Note: Use 0.0.0.0 to make it accessible from other devices in the same network
    app.run(host='0.0.0.0', port=port, debug=True)
