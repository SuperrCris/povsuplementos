# Configuración de Proyecto - POV Suplementos

## Variables de Entorno Sensibles

Para el desarrollo local, crea un archivo `.env` en la raíz del proyecto con las siguientes variables:

```
# Configuración de administrador por defecto (CAMBIAR EN PRODUCCIÓN)
DEFAULT_ADMIN_PASSWORD=admin123

# URLs de Firebase (ejemplo)
FIREBASE_URL=https://tu-proyecto.firebaseio.com
FIREBASE_STORAGE_BUCKET=tu-proyecto.firebasestorage.app
```

## Configuración de Firebase

1. Coloca tu archivo `google-services.json` en `android/app/`
2. Coloca tu archivo `GoogleService-Info.plist` en `ios/Runner/`
3. Estos archivos están excluidos del control de versiones por seguridad

## Notas de Seguridad

- ⚠️ **IMPORTANTE**: Cambiar la contraseña por defecto antes de deployment
- 🔒 Los archivos de configuración de Firebase contienen claves privadas
- 🚫 Nunca commitear contraseñas o claves API hardcodeadas