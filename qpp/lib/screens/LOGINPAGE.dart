import 'package:flutter/material.dart';
import 'package:qpp/screens/MyHomePage.dart';
import 'package:qpp/screens/data/local/db_helper.dart';
import 'package:qpp/screens/crossword_game_widget.dart';
class Loginpage extends StatefulWidget {
  const Loginpage({super.key});

  @override
  State<Loginpage> createState() => _LoginpageState();
}

class _LoginpageState extends State<Loginpage> {
  late final TextEditingController textDocId;
  late final TextEditingController textUserName;
  late final TextEditingController textEmail;
  late final TextEditingController textPassword;

  late final FocusNode focusUserName;
  late final FocusNode focusDocId;
  late final FocusNode focusEmail;
  late final FocusNode focusPassword;

  late final DBhelper dBhelper;
  bool _isPasswordVisible = false;

  @override
  
  void initState() {
    super.initState();
    textDocId = TextEditingController();
    textUserName = TextEditingController();
    textEmail = TextEditingController();
    textPassword = TextEditingController();

    focusUserName = FocusNode();
    focusDocId = FocusNode();
    focusEmail = FocusNode();
    focusPassword = FocusNode();

    dBhelper = DBhelper.getInstance();
  }

  @override
  void dispose() {
    textDocId.dispose();
    textUserName.dispose();
    textEmail.dispose();
    textPassword.dispose();

    focusUserName.dispose();
    focusDocId.dispose();
    focusEmail.dispose();
    focusPassword.dispose();
    super.dispose();
  }

  void _setLanguage(int languageId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WordSearchGamePage(language_id: languageId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    void set_language(int language_id){
    if (language_id==1){
      (context)=>const WordSearchGamePage(language_id: 1,);
    }
    else if (language_id==2){
      (context)=>const WordSearchGamePage(language_id: 2,);
    }
    
  }
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("Patient Login"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Please login the customer using your assigned doctor ID and credentials",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Language Selection Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => _setLanguage(1),
                    child: const Text('অসমীয়া'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () => _setLanguage(2),
                    child: const Text('ꯃꯅꯤꯄꯨꯔꯤ'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Username Field
              TextField(
                key: const ValueKey('username_field'),
                controller: textUserName,
                focusNode: focusUserName,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: "Username",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              

              // Email Field
              TextField(
                key: const ValueKey('email_field'),
                controller: textEmail,
                focusNode: focusEmail,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: "Email Address",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Password Field
              TextField(
                key: const ValueKey('password_field'),
                controller: textPassword,
                focusNode: focusPassword,
                obscureText: !_isPasswordVisible,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: "Password",
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Doctor ID Field
              TextField(
                key: const ValueKey('doc_id_field'),
                controller: textDocId,
                focusNode: focusDocId,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: "Doctor ID",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.medical_information_outlined),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: () async {
                  FocusManager.instance.primaryFocus?.unfocus();

                  final String username = textUserName.text.trim();
                  final String email = textEmail.text.trim();
                  final String password = textPassword.text.trim();
                  final String docIdStr = textDocId.text.trim();

                  final int? docId = int.tryParse(docIdStr);

                  // Validate all inputs
                  if (username.isEmpty ||
                      email.isEmpty ||
                      password.isEmpty ||
                      docId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please fill in all fields correctly."),
                      ),
                    );
                    return;
                  }

                  // Quick email format check
                  if (!email.contains('@') || !email.contains('.')) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please enter a valid email address."),
                      ),
                    );
                    return;
                  }

                  bool isSuccess = await dBhelper.add_user_entry(
                    D: username,
                    b: docId,
                  );

                  if (isSuccess && mounted) {
                    final String userEmail = email;
                    final String userPassword = password;

                    textUserName.clear();
                    textEmail.clear();
                    textPassword.clear();
                    textDocId.clear();

                    // Forward email & password to HomePage (and then to SyncHarnessScreen)
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HomePage(
                          userEmail: userEmail,
                          userPassword: userPassword,
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text("Submit"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}