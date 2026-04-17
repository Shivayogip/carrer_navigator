import os
from flask import Flask, request, jsonify
from flask_cors import CORS
from flask_mail import Mail, Message
from dotenv import load_dotenv
from ai_service import analyze_resume, chat_with_ai
from parser import extract_text
import db

load_dotenv()

app = Flask(__name__)
CORS(app) # Enable CORS for all routes

# Mail Configuration
app.config['MAIL_SERVER'] = os.getenv('MAIL_SERVER')
app.config['MAIL_PORT'] = int(os.getenv('MAIL_PORT', 587))
app.config['MAIL_USE_TLS'] = os.getenv('MAIL_USE_TLS', 'True') == 'True'
app.config['MAIL_USE_SSL'] = os.getenv('MAIL_USE_SSL', 'False') == 'True'
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
            
        target_email = os.getenv('CONTACT_TARGET_EMAIL', 'shivayogi2006@gmail.com')
        
        msg = Message(
            subject=f"New Contact Form Submission from {user_email}",
            recipients=[target_email],
            body=f"You have received a new message from your career navigator app.\n\nFrom: {user_email}\n\nMessage:\n{message_content}"
        )
        
        mail.send(msg)
        print(f"Contact email sent to {target_email}")
        return jsonify({"status": "success", "message": "Email sent successfully"}), 200
    except Exception as e:
        print(f"Error sending contact email: {e}")
        return jsonify({"error": str(e)}), 500

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
    resume_text = data.get('resume_text', '')
    skills = data.get('skills', '')
    role = data.get('role', '')
    score = data.get('score', 0)
    db.save_user_data(user_id, resume_text, skills, role, score)
    return jsonify({"status": "success"})

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

if __name__ == '__main__':
    port = int(os.getenv("PORT", 5000))
    # Note: Use 0.0.0.0 to make it accessible from other devices in the same network
    app.run(host='0.0.0.0', port=port, debug=True)
