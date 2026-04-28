import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/auth_service.dart';
import '../widgets/navbar.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _mobileController;
  late TextEditingController _courseController;
  late TextEditingController _branchController;
  late TextEditingController _interestController;
  String? _selectedYear;

  final List<String> _years = ["1st Year", "2nd Year", "3rd Year", "4th Year", "Graduated"];

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthService>(context, listen: false).user;
    _nameController = TextEditingController(text: user?.displayName ?? "");
    _mobileController = TextEditingController(text: user?.mobile ?? "");
    _courseController = TextEditingController(text: user?.course ?? "");
    _branchController = TextEditingController(text: user?.branch ?? "");
    _interestController = TextEditingController(text: user?.interestField ?? "");
    _selectedYear = user?.year != null && _years.contains(user!.year) ? user.year : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _courseController.dispose();
    _branchController.dispose();
    _interestController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.updateProfile({
      "name": _nameController.text,
      "mobile": _mobileController.text,
      "course": _courseController.text,
      "branch": _branchController.text,
      "year": _selectedYear,
      "interest_field": _interestController.text,
    });

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update profile")),
        );
      }
    }
  }

  void _showPasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isUpdating = false;
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.darkSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: AppTheme.borderSubtle),
          ),
          title: Text("CHANGE_ACCESS_TOKEN", style: Theme.of(context).textTheme.titleLarge),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: obscureCurrent,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Current Password",
                  labelStyle: const TextStyle(color: AppTheme.textDim),
                  suffixIcon: IconButton(
                    icon: Icon(obscureCurrent ? Icons.visibility_off : Icons.visibility, size: 20, color: AppTheme.textDim),
                    onPressed: () => setDialogState(() => obscureCurrent = !obscureCurrent),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPasswordController,
                obscureText: obscureNew,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "New Password",
                  labelStyle: const TextStyle(color: AppTheme.textDim),
                  suffixIcon: IconButton(
                    icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility, size: 20, color: AppTheme.textDim),
                    onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordController,
                obscureText: obscureConfirm,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Confirm New Password",
                  labelStyle: const TextStyle(color: AppTheme.textDim),
                  suffixIcon: IconButton(
                    icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility, size: 20, color: AppTheme.textDim),
                    onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL", style: TextStyle(color: AppTheme.textDim)),
            ),
            ElevatedButton(
              onPressed: isUpdating ? null : () async {
                if (newPasswordController.text != confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Passwords do not match")),
                  );
                  return;
                }

                setDialogState(() => isUpdating = true);
                final authService = Provider.of<AuthService>(context, listen: false);
                final error = await authService.changePassword(
                  currentPasswordController.text,
                  newPasswordController.text,
                );

                if (mounted) {
                  setDialogState(() => isUpdating = false);
                  if (error == null) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Password updated successfully!")),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error)),
                    );
                  }
                }
              },
              child: isUpdating ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text("UPDATE"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).user;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Column(
        children: [
          const Navbar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "USER_PROFILE.CFG",
                                  style: theme.textTheme.labelLarge,
                                ).animate().fadeIn().slideX(),
                                Text(
                                  "Credentials & Academic Data",
                                  style: theme.textTheme.displayMedium,
                                ).animate().fadeIn(delay: 200.ms).slideX(),
                              ],
                            ),
                          ),
                          if (!_isEditing)
                            ElevatedButton.icon(
                              onPressed: () => setState(() => _isEditing = true),
                              icon: const Icon(Icons.edit_note, size: 20),
                              label: const Text("EDIT_CONFIG"),
                            ).animate().scale(delay: 400.ms),
                        ],
                      ),
                      const SizedBox(height: 40),

                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildInfoCard(
                              "IDENTITY_PROTOCOL",
                              [
                                _buildDetailRow("NAME", user?.displayName ?? "Not set", _nameController, _isEditing),
                                _buildDetailRow("EMAIL", user?.email ?? "Not set", null, false),
                                _buildDetailRow("MOBILE", user?.mobile ?? "Not set", _mobileController, _isEditing),
                              ],
                            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
                            const SizedBox(height: 32),
                            _buildInfoCard(
                              "ACADEMIC_SCHEMA",
                              [
                                _buildDetailRow("COURSE", user?.course ?? "Not set", _courseController, _isEditing),
                                _buildDetailRow("BRANCH", user?.branch ?? "Not set", _branchController, _isEditing),
                                _buildDropdownRow("YEAR_OF_STUDY", user?.year ?? "Not set", _isEditing),
                                _buildDetailRow("INTEREST_FIELD", user?.interestField ?? "Not set", _interestController, _isEditing),
                              ],
                            ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
                            const SizedBox(height: 40),

                            if (_isEditing)
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => setState(() => _isEditing = false),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 20),
                                        side: const BorderSide(color: AppTheme.borderSubtle),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                      ),
                                      child: const Text("CANCEL", style: TextStyle(color: AppTheme.textDim)),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _saveProfile,
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 20),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                      ),
                                      child: _isLoading 
                                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                        : const Text("SAVE_CHANGES"),
                                    ),
                                  ),
                                ],
                              ).animate().fadeIn()
                            else
                              OutlinedButton.icon(
                                onPressed: _showPasswordDialog,
                                icon: const Icon(Icons.lock_open, size: 18),
                                label: const Text("RESET_ACCESS_TOKEN"),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  minimumSize: const Size(double.infinity, 50),
                                  side: const BorderSide(color: AppTheme.borderSubtle),
                                  foregroundColor: AppTheme.accentPurple,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                ),
                              ).animate().fadeIn(delay: 700.ms),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.borderSubtle, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.terminal, size: 18, color: AppTheme.primaryNeon),
              const SizedBox(width: 12),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const Divider(height: 48),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, TextEditingController? controller, bool editing) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelLarge?.copyWith(fontSize: 10, color: AppTheme.textDim)),
          const SizedBox(height: 12),
          if (editing && controller != null)
            TextFormField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              validator: (v) => v == null || v.isEmpty ? "Required" : null,
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.darkBg.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: AppTheme.borderSubtle.withOpacity(0.5)),
              ),
              child: Text(value, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
            ),
        ],
      ),
    );
  }

  Widget _buildDropdownRow(String label, String value, bool editing) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelLarge?.copyWith(fontSize: 10, color: AppTheme.textDim)),
          const SizedBox(height: 12),
          if (editing)
            DropdownButtonFormField<String>(
              value: _selectedYear,
              dropdownColor: AppTheme.darkSurface,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
              onChanged: (v) => setState(() => _selectedYear = v),
              validator: (v) => v == null ? "Required" : null,
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.darkBg.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: AppTheme.borderSubtle.withOpacity(0.5)),
              ),
              child: Text(value, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
            ),
        ],
      ),
    );
  }
}


