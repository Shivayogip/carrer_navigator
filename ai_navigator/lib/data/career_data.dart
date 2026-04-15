class Career {
  final String title;
  final List<String> skills;
  final String difficulty;
  final String salary;
  final List<String> companies;

  Career({
    required this.title,
    required this.skills,
    required this.difficulty,
    required this.salary,
    required this.companies,
  });
}

List<Career> careers = [
  Career(
    title: "Software Engineer",
    skills: ["java", "dsa", "oop", "sql"],
    difficulty: "Medium",
    salary: "₹6-15 LPA",
    companies: ["Google", "Microsoft", "Amazon"],
  ),
  Career(
    title: "AI Engineer",
    skills: ["python", "machine learning", "ai", "tensorflow"],
    difficulty: "High",
    salary: "₹10-25 LPA",
    companies: ["OpenAI", "Google", "NVIDIA"],
  ),
  Career(
    title: "Data Scientist",
    skills: ["python", "statistics", "pandas", "ml"],
    difficulty: "High",
    salary: "₹8-20 LPA",
    companies: ["Meta", "Amazon", "Flipkart"],
  ),
  Career(
    title: "DevOps Engineer",
    skills: ["docker", "kubernetes", "aws", "linux"],
    difficulty: "Medium",
    salary: "₹7-18 LPA",
    companies: ["Infosys", "TCS", "Accenture"],
  ),
  Career(
    title: "Product Engineer",
    skills: ["react", "flutter", "ui", "backend"],
    difficulty: "Medium",
    salary: "₹6-16 LPA",
    companies: ["Swiggy", "Zomato", "Razorpay"],
  ),
];