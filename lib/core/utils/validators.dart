/// Validadores de formulário
class Validators {
  Validators._();

  /// Valida email
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email é obrigatório';
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
    );
    
    if (!emailRegex.hasMatch(value)) {
      return 'Email inválido';
    }
    
    return null;
  }

  /// Valida senha
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Senha é obrigatória';
    }
    
    if (value.length < 6) {
      return 'Senha deve ter no mínimo 6 caracteres';
    }
    
    return null;
  }

  /// Valida confirmação de senha
  static String? confirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Confirmação de senha é obrigatória';
    }
    
    if (value != password) {
      return 'Senhas não conferem';
    }
    
    return null;
  }

  /// Valida nome
  static String? name(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nome é obrigatório';
    }
    
    if (value.length < 3) {
      return 'Nome deve ter no mínimo 3 caracteres';
    }
    
    return null;
  }

  /// Valida username
  static String? username(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username é obrigatório';
    }
    
    if (value.length < 3) {
      return 'Username deve ter no mínimo 3 caracteres';
    }
    
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegex.hasMatch(value)) {
      return 'Username pode conter apenas letras, números e _';
    }
    
    return null;
  }

  /// Valida telefone
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Telefone é obrigatório';
    }
    
    final phone = value.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (phone.length != 11) {
      return 'Telefone inválido';
    }
    
    return null;
  }

  /// Valida campo obrigatório
  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Campo'} é obrigatório';
    }
    return null;
  }
}
