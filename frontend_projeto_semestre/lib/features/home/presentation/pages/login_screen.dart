import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; 
import '../../../home/presentation/pages/home_page.dart'; 
import '../../../../core/config/app_config.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _fazerLogin() async {

    // 1. Valida se os campos estão preenchidos
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
    
      final url = Uri.parse('http://127.0.0.1:8000/auth/login'); 
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text,
          'password': _passwordController.text,
        }),
      );

      // 3. Verifica a resposta da API
      if (response.statusCode == 200) {
       
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      } else if (response.statusCode == 401) {

        // 4. Tratamento do Erro 401
        _mostrarErro('E-mail ou palavra-passe incorretos.');
      } else {
        _mostrarErro('Erro no servidor. Tente novamente mais tarde.');
      }
    } catch (e) {
      _mostrarErro('Falha na ligação ao servidor.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logotipo / Título
                  Icon(Icons.lock_person_outlined, size: 80, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 24),
                  Text(
                    'Automatize',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 48),

                  // Campo E-mail
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value != null && value.isEmpty ? 'Preencha o e-mail' : null,
                  ),
                  const SizedBox(height: 16),

                  // Campo Palavra-passe
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Palavra-passe',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (value) => value != null && value.isEmpty ? 'Preencha a palavra-passe' : null,
                  ),
                  const SizedBox(height: 32),

                  // Botão de Login
                  SizedBox(
                    height: 50,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _fazerLogin,
                      child: _isLoading
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Entrar', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}