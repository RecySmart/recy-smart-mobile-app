# ♻️ RecySmart

> Smart PET Recycling con IoT y Gamificación

RecySmart es una aplicación móvil innovadora desarrollada en Flutter que revoluciona la experiencia de reciclaje mediante inteligencia artificial, IoT y gamificación. Permite a los usuarios reciclar de manera inteligente, acceder a recompensas y ser parte de una comunidad comprometida con el medio ambiente.

## 🌟 Características Principales

- **🔐 Autenticación Segura** - Sistema de login y registro con almacenamiento seguro
- **🗺️ Mapa Interactivo** - Ubicación de contenedores inteligentes cercanos
- **📱 Escaneo QR** - Escanea códigos QR para iniciar sesiones de reciclaje
- **🎯 Gamificación** - Sistema de puntos, logros y tabla de posiciones
- **🏆 Recompensas** - Canjea puntos por cupones y ofertas
- **👤 Perfil de Usuario** - Gestión de perfil, historial de transacciones y logros
- **🔔 Notificaciones** - Alertas sobre actividades y recompensas
- **📊 Dashboard** - Datos en tiempo real sobre actividades de reciclaje

## 📋 Requisitos Previos

- **Flutter SDK**: >= 3.3.0
- **Dart**: >= 3.3.0
- **Android SDK** (para desarrollo en Android)
- **Xcode** (para desarrollo en iOS) - macOS requerido
- **Git**: Control de versiones

## 🚀 Instalación

### 1. Clonar el repositorio

```bash
git clone https://github.com/tu-usuario/RecySmart.git
cd RecySmart
```

### 2. Instalar dependencias

```bash
flutter pub get
```

### 3. Generar archivos necesarios (si es requerido)

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. Verificar la instalación

```bash
flutter doctor
```

## 🏃 Cómo Ejecutar

### Modo Debug

```bash
# Ejecutar en el dispositivo/emulador predeterminado
flutter run

# Ejecutar en un dispositivo específico
flutter run -d <device_id>

# Listar dispositivos disponibles
flutter devices
```

### Modo Release

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

### Modo Web (experimental)

```bash
flutter run -d chrome
```

## 🏗️ Estructura del Proyecto

```
lib/
├── main.dart                    # Punto de entrada
├── core/                        # Componentes compartidos
│   ├── constants/              # Constantes de la aplicación
│   ├── errors/                 # Manejo de errores
│   ├── network/                # Cliente HTTP (Dio)
│   ├── theme/                  # Temas y estilos
│   ├── utils/                  # Utilidades (router, inyección, almacenamiento)
│   └── widgets/                # Widgets reutilizables
└── features/                    # Características de la aplicación
    ├── auth/                   # Autenticación
    ├── home/                   # Página principal
    ├── map/                    # Mapas y ubicación de contenedores
    ├── recycling/              # Sesiones de reciclaje
    ├── rewards/                # Sistema de recompensas
    ├── profile/                # Perfil de usuario
    ├── leaderboard/            # Tabla de posiciones
    └── notifications/          # Sistema de notificaciones
```

## 🏛️ Arquitectura

El proyecto utiliza **Clean Architecture** con separación de capas:

```
Feature/
├── data/
│   ├── datasources/           # APIs y fuentes de datos
│   ├── models/                # Modelos de datos
│   └── repositories/          # Implementación de repositorios
├── domain/
│   ├── entities/              # Entidades de negocio
│   ├── repositories/          # Contratos de repositorios
│   └── usecases/              # Casos de uso
└── presentation/
    ├── bloc/                  # Gestión de estado (BLoC)
    ├── pages/                 # Pantallas
    └── widgets/               # Componentes UI específicos
```

## 📦 Dependencias Principales

| Paquete | Versión | Propósito |
|---------|---------|-----------|
| `flutter_bloc` | ^8.1.6 | Gestión de estado |
| `dio` | ^5.7.0 | Cliente HTTP |
| `go_router` | ^14.6.2 | Navegación |
| `flutter_secure_storage` | ^9.2.2 | Almacenamiento seguro |
| `mobile_scanner` | ^5.2.3 | Escaneo QR |
| `flutter_map` | ^7.0.2 | Mapas interactivos |
| `get_it` | ^8.0.2 | Inyección de dependencias |
| `dartz` | ^0.10.1 | Programación funcional |

## 🔧 Configuración de Desarrollo

### Configurar Variables de Entorno

Crea un archivo `.env` en la raíz del proyecto:

```env
API_BASE_URL=https://api.recysmart.com
API_TIMEOUT=30
```

### Configurar Git Hooks (opcional)

```bash
# Ejecutar análisis antes de cada commit
git config core.hooksPath hooks
```

## 🧪 Testing

### Ejecutar pruebas unitarias

```bash
flutter test
```

### Ejecutar pruebas con cobertura

```bash
flutter test --coverage
lcov --list coverage/lcov.info
```

### Pruebas específicas

```bash
flutter test test/features/auth/presentation/bloc/auth_bloc_test.dart
```

## 📊 Análisis de Código

```bash
# Ejecutar análisis estático
flutter analyze

# Con opciones adicionales
dart analyze lib/
```

## 🐛 Reportar Problemas

Si encuentras un bug, por favor crea un issue en GitHub con:

- Descripción clara del problema
- Pasos para reproducir
- Comportamiento esperado vs actual
- Versión de Flutter y Dart
- Dispositivo/emulador utilizado

## 🤝 Contribuir

Las contribuciones son bienvenidas. Para grandes cambios:

1. Fork el repositorio
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📝 Guía de Estilo

- Sigue la [guía de Dart](https://dart.dev/guides/language/effective-dart/style)
- Usa nombres descriptivos para variables y funciones
- Comenta código complejo
- Mantén las funciones pequeñas y enfocadas

## 📄 Licencia

Este proyecto está licenciado bajo la MIT License - ver el archivo `LICENSE` para más detalles.

## 👥 Autores

- **Cristopher Rondón Añaños** - Desarrollo inicial

## 🙏 Agradecimientos

- Flutter Community
- BLoC Pattern
- Clean Architecture

## 📚 Recursos Útiles

- [Documentación de Flutter](https://docs.flutter.dev/)
- [Bloc Library](https://bloclibrary.dev/)
- [Clean Architecture in Flutter](https://resocoder.com/flutter-clean-architecture)
- [Dart Language](https://dart.dev)

---

**RecySmart** - Reciclando inteligentemente, construyendo un futuro sostenible ♻️
