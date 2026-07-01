import '../models/user.dart';

/// Usuarios precargados para pruebas de autenticación y autorización
/// Esto simula la base de datos mientras el backend no está listo
class MockUsers {
  static final List<User> users = [
    // Administrador
    User(
      id: 1,
      nombre: 'Administrador del Sistema',
      empleadoId: 'ADMIN-001',
      rol: 'admin',
      turno: 'Matutino',
      activo: true,
    ),
    // Cocinero 1
    User(
      id: 2,
      nombre: 'Carlos Cocina',
      empleadoId: 'COC-001',
      rol: 'cocinero',
      turno: 'Matutino',
      activo: true,
    ),
    // Cocinero 2
    User(
      id: 3,
      nombre: 'María Martínez',
      empleadoId: 'COC-002',
      rol: 'cocinero',
      turno: 'Vespertino',
      activo: true,
    ),
    // Trabajador 1
    User(
      id: 4,
      nombre: 'Juan Pérez',
      empleadoId: 'TRAB-001',
      rol: 'trabajador',
      turno: 'Matutino',
      activo: true,
    ),
    // Trabajador 2
    User(
      id: 5,
      nombre: 'Ana García',
      empleadoId: 'TRAB-002',
      rol: 'trabajador',
      turno: 'Vespertino',
      activo: true,
    ),
    // Trabajador 3 (turno Nocturno)
    User(
      id: 6,
      nombre: 'Luis Ramírez',
      empleadoId: 'TRAB-003',
      rol: 'trabajador',
      turno: 'Nocturno',
      activo: true,
    ),
    // Usuario inactivo (para prueba de autorización)
    User(
      id: 7,
      nombre: 'Inactivo Prueba',
      empleadoId: 'INACT-001',
      rol: 'trabajador',
      turno: 'Matutino',
      activo: false,
    ),
  ];

  /// Mapeo de contraseñas por ID de empleado
  static final Map<String, String> _passwords = {
    'ADMIN-001': 'Admin123!',
    'COC-001': 'Cocinero123!',
    'COC-002': 'Maria123!',
    'TRAB-001': 'Trabajador123!',
    'TRAB-002': 'Ana123!',
    'TRAB-003': 'Luis123!',
    'INACT-001': 'Inactivo123!',
  };

  /// Busca un usuario por ID de empleado y contraseña
  static User? authenticate(String empleadoId, String password) {
    // Verificar si la contraseña coincide
    if (_passwords[empleadoId] != password) {
      return null;
    }

    // Buscar el usuario
    try {
      return users.firstWhere((user) => user.empleadoId == empleadoId);
    } catch (e) {
      return null;
    }
  }

  /// Obtiene un usuario por su ID
  static User? getUserById(int id) {
    try {
      return users.firstWhere((user) => user.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Obtiene usuarios por rol
  static List<User> getUsersByRole(String rol) {
    return users.where((user) => user.rol == rol && user.activo).toList();
  }
}