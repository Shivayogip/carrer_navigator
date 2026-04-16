import sqlite3
import os
import uuid
import hashlib

DB_FILE = 'users.db'

def get_db():
    conn = sqlite3.connect(DB_FILE)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    with get_db() as conn:
        conn.execute('''
            CREATE TABLE IF NOT EXISTS users (
                id TEXT PRIMARY KEY,
                email TEXT UNIQUE,
                password_hash TEXT,
                name TEXT
            )
        ''')
        conn.execute('''
            CREATE TABLE IF NOT EXISTS sessions (
                token TEXT PRIMARY KEY,
                user_id TEXT,
                FOREIGN KEY(user_id) REFERENCES users(id)
            )
        ''')
        conn.execute('''
            CREATE TABLE IF NOT EXISTS user_data (
                user_id TEXT PRIMARY KEY,
                resume_text TEXT,
                skills TEXT,
                role TEXT,
                score INTEGER,
                FOREIGN KEY(user_id) REFERENCES users(id)
            )
        ''')
        conn.commit()

init_db()

def hash_password(password):
    return hashlib.sha256(password.encode()).hexdigest()

def create_user(email, password, name=""):
    try:
        user_id = str(uuid.uuid4())
        pwd_hash = hash_password(password) if password else ""
        with get_db() as conn:
            conn.execute('INSERT INTO users (id, email, password_hash, name) VALUES (?, ?, ?, ?)', (user_id, email, pwd_hash, name))
            conn.commit()
        return user_id, None
    except sqlite3.IntegrityError:
        return None, "Email already exists"

def verify_user(email, password):
    pwd_hash = hash_password(password)
    with get_db() as conn:
        user = conn.execute('SELECT id FROM users WHERE email = ? AND password_hash = ?', (email, pwd_hash)).fetchone()
        if user:
            return user['id']
    return None

def create_session(user_id):
    token = str(uuid.uuid4())
    with get_db() as conn:
        conn.execute('INSERT INTO sessions (token, user_id) VALUES (?, ?)', (token, user_id))
        conn.commit()
    return token

def get_user_from_token(token):
    if not token:
        return None
    with get_db() as conn:
        session = conn.execute('SELECT user_id FROM sessions WHERE token = ?', (token,)).fetchone()
        if session:
            return session['user_id']
    return None

def get_or_create_google_user(email, name):
    with get_db() as conn:
        user = conn.execute('SELECT id FROM users WHERE email = ?', (email,)).fetchone()
        if user:
            return user['id']
    return create_user(email, "", name)[0]

def save_user_data(user_id, resume_text, skills, role, score):
    with get_db() as conn:
        conn.execute('''
            INSERT OR REPLACE INTO user_data (user_id, resume_text, skills, role, score)
            VALUES (?, ?, ?, ?, ?)
        ''', (user_id, resume_text, skills, role, score))
        conn.commit()

def get_user_data(user_id):
    with get_db() as conn:
        data = conn.execute('''
            SELECT u.email, u.name, d.resume_text, d.skills, d.role, d.score
            FROM users u
            LEFT JOIN user_data d ON u.id = d.user_id
            WHERE u.id = ?
        ''', (user_id,)).fetchone()
        if data:
            return dict(data)
    return None
