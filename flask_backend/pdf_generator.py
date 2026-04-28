import os
from fpdf import FPDF
from datetime import datetime

def sanitize_text(text):
    if not isinstance(text, str):
        return str(text)
    # Aggressive sanitation for Latin-1
    replacements = {
        '\u2013': '-', '\u2014': '-', '\u2018': "'", '\u2019': "'",
        '\u201c': '"', '\u201d': '"', '\u2022': '-', '\u2026': '...',
        '\u00a0': ' ', '\u2012': '-', '\u2013': '-', '\u2014': '-',
        '\u2219': '-', '\u2022': '-', '\u00b7': '-'
    }
    for k, v in replacements.items():
        text = text.replace(k, v)
    return text.encode('latin-1', 'replace').decode('latin-1')

class PDFReport(FPDF):
    def __init__(self, title, **kwargs):
        super().__init__(**kwargs)
        self.report_title = title
        self.set_margins(20, 20, 20)
        self.set_auto_page_break(True, margin=20)

    def header(self):
        self.set_font('helvetica', 'B', 16)
        self.set_text_color(0, 51, 102)
        self.cell(0, 15, sanitize_text(self.report_title).upper(), border='B', ln=1, align='L')
        self.ln(10)

    def footer(self):
        self.set_y(-15)
        self.set_font('helvetica', 'I', 8)
        self.set_text_color(150, 150, 150)
        self.cell(0, 10, f'Page {self.page_no()} | AI Career Navigator', 0, 0, 'C')

def generate_report_pdf(title, markdown_content):
    pdf = PDFReport(title=title)
    pdf.add_page()
    
    pdf.set_font("helvetica", size=11)
    pdf.set_text_color(40, 40, 40)
    
    w = 170 
    
    lines = markdown_content.split('\n')
    for line in lines:
        line = sanitize_text(line.strip())
        if not line:
            pdf.ln(5)
            continue
            
        if line.startswith('## '):
            pdf.ln(5)
            pdf.set_font("helvetica", 'B', 14)
            pdf.set_text_color(0, 51, 102)
            pdf.multi_cell(w, 9, line[3:])
            pdf.set_text_color(40, 40, 40)
            pdf.set_font("helvetica", size=11)
            pdf.ln(3)
        elif line.startswith('# '):
            pdf.ln(8)
            pdf.set_font("helvetica", 'B', 18)
            pdf.multi_cell(w, 12, line[2:])
            pdf.set_font("helvetica", size=11)
            pdf.ln(5)
        elif line.startswith('### '):
            pdf.ln(3)
            pdf.set_font("helvetica", 'B', 12)
            pdf.multi_cell(w, 8, line[4:])
            pdf.set_font("helvetica", size=11)
            pdf.ln(3)
        elif line.startswith('* ') or line.startswith('- ') or (line[0:1].isdigit() and line[1:2] == '.'):
            pdf.set_x(25)
            # Use safe standard characters only
            pdf.multi_cell(w - 10, 8, f'- {line[2:] if not line[0].isdigit() else line}')
            pdf.ln(4) # More space after list items to prevent overlap
        else:
            clean_line = line.replace('**', '')
            pdf.multi_cell(w, 7, clean_line)
            pdf.ln(4) # More space between paragraphs
            
    return pdf.output()
            
    return pdf.output()
            
    return pdf.output()

def generate_resume_pdf(data):
    pdf = FPDF()
    pdf.set_margins(20, 20, 20)
    pdf.add_page()
    
    # Executive Header
    pdf.set_fill_color(44, 62, 80) # Slate Grey
    pdf.rect(0, 0, 210, 45, 'F')
    
    # Name
    pdf.set_y(12)
    pdf.set_text_color(255, 255, 255)
    pdf.set_font("helvetica", 'B', 24)
    pdf.cell(0, 12, data.get('name', 'YOUR NAME').upper(), ln=True, align='C')
    
    # Contact Info Bar
    pdf.set_font("helvetica", size=9)
    contact = data.get('email', 'email@example.com')
    if data.get('mobile'): contact += f"  |  {data['mobile']}"
    pdf.cell(0, 8, sanitize_text(contact), ln=True, align='C')
    
    pdf.set_y(50)
    pdf.set_text_color(44, 62, 80)
    
    def add_header(text):
        pdf.ln(5)
        pdf.set_font("helvetica", 'B', 12)
        pdf.cell(0, 8, text, ln=True)
        pdf.set_draw_color(44, 62, 80)
        pdf.line(20, pdf.get_y(), 190, pdf.get_y())
        pdf.ln(2)
        pdf.set_font("helvetica", size=10)
        pdf.set_text_color(60, 60, 60)

    # Summary
    if data.get('summary'):
        add_header("PROFESSIONAL SUMMARY")
        pdf.multi_cell(0, 5, sanitize_text(data['summary']))
        
    # Experience
    experiences = data.get('experience', [])
    if experiences:
        add_header("PROFESSIONAL EXPERIENCE")
        for exp in experiences:
            pdf.set_font("helvetica", 'B', 10.5)
            pdf.set_text_color(44, 62, 80)
            title = sanitize_text(exp.get('title', ''))
            company = sanitize_text(exp.get('company', ''))
            pdf.cell(0, 7, f"{title} | {company}", ln=True)
            pdf.set_font("helvetica", 'I', 9.5)
            pdf.set_text_color(80, 80, 80)
            pdf.multi_cell(0, 5, sanitize_text(exp.get('description', '')))
            pdf.ln(2)
        
    # Education
    education = data.get('education', [])
    if education:
        add_header("EDUCATION")
        for edu in education:
            pdf.set_font("helvetica", 'B', 10.5)
            pdf.set_text_color(44, 62, 80)
            pdf.cell(130, 7, sanitize_text(edu.get('school', '')))
            pdf.set_font("helvetica", size=9)
            pdf.cell(0, 7, sanitize_text(edu.get('year', '')), align='R', ln=True)
            pdf.set_font("helvetica", 'I', 9.5)
            pdf.cell(0, 5, sanitize_text(edu.get('degree', '')), ln=True)
            pdf.ln(2)

    # Skills
    if data.get('skills'):
        add_header("TECHNICAL SKILLS")
        skills = data['skills']
        skills_txt = ", ".join(skills) if isinstance(skills, list) else str(skills)
        pdf.multi_cell(0, 5, sanitize_text(skills_txt))
        
    return pdf.output()
