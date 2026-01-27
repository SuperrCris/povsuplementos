# POV Suplementos - Sistema POS

Sistema de Point of Sale (Punto de Venta) para suplementos desarrollado en Flutter.

## 🚀 Características

- 📱 Aplicación multiplataforma (Android, iOS, Web, Desktop)
- 👥 Sistema de autenticación y gestión de usuarios
- 🛍️ Carrito de compras y procesamiento de ventas
- 📊 Inventario y gestión de productos
- 💳 Múltiples métodos de pago
- 📈 Reportes y análisis de ventas
- 🔄 Sincronización con Firebase

## 🛠️ Tecnologías

- **Flutter** - Framework de desarrollo
- **Firebase** - Backend y base de datos
- **Dart** - Lenguaje de programación

## 📋 Requisitos Previos

- Flutter SDK (versión más reciente)
- Android Studio / VS Code
- Cuenta de Firebase configurada

## ⚙️ Configuración

1. **Clonar el repositorio:**
   ```bash
   git clone [URL_DEL_REPOSITORIO]
   cd pov_suplementos
   ```

2. **Instalar dependencias:**
   ```bash
   flutter pub get
   ```

3. **Configuración de Firebase:**
   - Sigue las instrucciones en `CONFIG_SEGURIDAD.md`
   - Coloca los archivos de configuración de Firebase en las carpetas correspondientes

4. **Ejecutar la aplicación:**
   ```bash
   flutter run
   ```

## 📂 Estructura del Proyecto

```
lib/
├── auth/          # Autenticación y gestión de sesiones
├── estructuras/   # Modelos de datos
├── funciones/     # Lógica de negocio
├── widgets/       # Componentes de UI
└── main.dart      # Punto de entrada
```

## 🔐 Seguridad

- ⚠️ **NO** incluir información sensible en el código
- 🔑 Configurar variables de entorno para credenciales
- 🛡️ Seguir las mejores prácticas de seguridad de Firebase

## 📞 Contacto

Para más información sobre este proyecto, contactar al desarrollador.

---
**Nota:** Este es un proyecto de desarrollo. Asegúrate de configurar adecuadamente todas las variables sensibles antes del deployment en producción.
