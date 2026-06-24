import os
import smtplib
from email.message import EmailMessage
from dotenv import load_dotenv

load_dotenv()

def test_mail():
    try:
        msg = EmailMessage()
        msg.set_content("This is a test message from the Career Navigator setup.")
        msg['Subject'] = "Test Email"
        msg['From'] = os.getenv('MAIL_DEFAULT_SENDER')
        msg['To'] = os.getenv('CONTACT_TARGET_EMAIL')

        print(f"Connecting to {os.getenv('MAIL_SERVER')}:{os.getenv('MAIL_PORT')}...")
        
        server = smtplib.SMTP(os.getenv('MAIL_SERVER'), int(os.getenv('MAIL_PORT')))
        server.starttls()
        print("Logging in...")
        server.login(os.getenv('MAIL_USERNAME'), os.getenv('MAIL_PASSWORD'))
        print("Sending...")
        server.send_message(msg)
        server.quit()
        print("Success!")
    except Exception as e:
        print(f"Failed: {e}")

if __name__ == "__main__":
    test_mail()
