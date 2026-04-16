class ResumeService {
  // 🔒 Singleton (one global instance)
  static final ResumeService _instance = ResumeService._internal();

  factory ResumeService() {
    return _instance;
  }

  ResumeService._internal();

  // 📄 STORED DATA
  String resumeText = "";
  List<String> extractedSkills = [];
  String? selectedRole;
  String? selectedCompany;
  List<String> dynamicMissingSkills = [];

  // 🔥 SET RESUME
  void setResume(String text) {
    resumeText = text;
    extractedSkills = extractSkills(text);
  }

  // 🎯 SET TARGET ROLE & COMPANY
  void setTarget(String role, {String? company}) {
    selectedRole = role;
    selectedCompany = company;
    dynamicMissingSkills = []; // reset missing skills upon target change
  }

  // 🧠 SKILL EXTRACTION LOGIC
  List<String> extractSkills(String text) {
    List<String> skillsDatabase = [
      "java",
      "python",
      "c++",
      "flutter",
      "react",
      "html",
      "css",
      "javascript",
      "node",
      "express",
      "mongodb",
      "sql",
      "dsa",
      "oop",
      "machine learning",
      "deep learning",
      "ai",
      "data science",
      "pandas",
      "numpy",
      "tensorflow",
      "docker",
      "kubernetes",
      "aws",
      "linux",
      "git",
      "github"
    ];

    text = text.toLowerCase();

    return skillsDatabase
        .where((skill) => text.contains(skill))
        .toSet() // remove duplicates
        .toList();
  }

  // 🧹 OPTIONAL: CLEAR DATA (for reset/logout)
  void clearAll() {
    resumeText = "";
    extractedSkills = [];
    selectedRole = null;
    selectedCompany = null;
    dynamicMissingSkills = [];
  }
}