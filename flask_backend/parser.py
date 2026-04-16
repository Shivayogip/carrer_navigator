import io
from PyPDF2 import PdfReader
import docx2txt

def extract_text(file_storage):
    filename = file_storage.filename.lower()
    
    if filename.endswith('.pdf'):
        pdf_reader = PdfReader(file_storage.stream)
        text = ""
        for page in pdf_reader.pages:
            text += page.extract_text()
        return text
    
    if filename.endswith('.docx'):
        # docx2txt expects a file-like object or a path
        text = docx2txt.process(file_storage.stream)
        return text
        
    raise Exception("Unsupported file type. Please upload PDF or DOCX.")
