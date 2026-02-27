E-commerce movil

DESARROLLO DE UN SISTEMA MÓVIL FULL STACK ORIENTADA A LA GESTIÓN DE E-COMMERCE

Diseñar y desarrollar un sistema móvil Full Stack con arquitectura híbrida offline-first, utilizando Flutter para el frontend móvil y Supabase (PostgreSQL + Auth + API REST) como backend cloud, con el propósito de optimizar la gestión de e-commerce en tiendas deportivas mediante la centralización de inventarios, trazabilidad de transacciones, control automatizado de stock y mejora en la disponibilidad y seguridad de la información.

## Características Principales

### 🎯 Funcionalidades Implementadas

Backend: Implementación de base de datos en Supabase con tablas usuarios, productos, categorias, pedidos, detalle_pedidos y políticas RLS activas.
Frontend: Desarrollo de aplicación móvil en Flutter con navegación funcional entre Home, Productos, Ventas e Inventario.

Flujo 1: Autenticación completa (Registro/Login con Supabase Auth + JWT) y acceso diferenciado por rol (Administrador / Vendedor).
Flujo 2: Registro de venta completo → validación de stock → generación de pedido → actualización automática de inventario
Flujo 3: Registro de venta completo → validación de stock → generación de pedido → actualización automática de inventario
Extras / Mejoras: Validaciones de campos obligatorios, alertas visuales de stock bajo, manejo de errores y mensajes de confirmación en operaciones críticas
Sincronización básica offline-first: Registro de datos en SQLite y sincronización manual o automática cuando exista conectividad.

### 📊 Stack Tecnológico

- **Flutter**: Framework principal
- **Isar**: Base de datos local (offline-first)
- **Supabase**: Backend y sincronización
- **Provider**: State management
- **Material Design 3**: UI moderna

## Estructura del Proyecto

```
lib/
├── models/              # Modelos de datos Isar
│   ├── producto.dart
│   ├── almacen.dart
│   ├── tienda.dart
│   ├── empleado.dart
│   ├── inventario.dart
│   ├── compra.dart
│   ├── venta.dart
│   └── transferencia.dart
├── services/            # Lógica de negocio
│   ├── database_service.dart
│   ├── producto_service.dart
│   ├── almacen_service.dart
│   ├── tienda_service.dart
│   ├── empleado_service.dart
│   ├── inventario_service.dart
│   ├── compra_service.dart
│   ├── venta_service.dart
│   ├── transferencia_service.dart
│   ├── supabase_service.dart
│   ├── sync_service.dart
│   └── auth_service.dart
├── providers/           # State management
│   ├── auth_provider.dart
│   └── sync_provider.dart
├── screens/             # Pantallas de la app
│   ├── login_screen.dart
│   ├── home_screen.dart
│   ├── dashboard_screen.dart
│   ├── productos_screen.dart
│   ├── ventas_screen.dart
│   ├── inventario_screen.dart
│   └── ...
└── main.dart
```

## Instalación y Configuración

### 1. Prerrequisitos

- Flutter SDK 3.9.2 o superior
- Dart SDK
- Cuenta de Supabase (opcional para sincronización)

### 2. Instalar Dependencias

```bash
flutter pub get
```

### 3. Generar Código de Isar

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. Configurar Supabase (Opcional)

En `lib/main.dart`, descomenta y configura:

```dart
await SupabaseService().initialize(
  'TU_SUPABASE_URL',
  'TU_SUPABASE_ANON_KEY'
);
```

### 5. Ejecutar la Aplicación

```bash
flutter run
```

## Uso del Sistema

### Roles y Permisos

#### Administrador (`admin`)
- Acceso completo a todas las funcionalidades
- Gestión de productos, almacenes, tiendas y empleados
- Realizar compras, ventas y transferencias
- Ver reportes globales

#### Encargado de Tienda (`encargado_tienda`)
- Realizar ventas
- Solicitar transferencias
- Ver inventario de su tienda
- Ver reportes de su tienda

#### Encargado de Almacén (`encargado_almacen`)
- Realizar compras
- Gestionar transferencias
- Ver inventario de su almacén
- Ver reportes de su almacén

#### Vendedor (`vendedor`)
- Realizar ventas
- Ver inventario de su tienda

### Flujo de Trabajo Típico

1. **Login**: Ingresar con email y contraseña
2. **Dashboard**: Ver resumen de ventas del día
3. **Productos**: Gestionar catálogo de productos
4. **Compras**: Registrar compras a proveedores → Actualiza inventario automáticamente
5. **Ventas**: Realizar ventas → Descuenta inventario automáticamente
6. **Transferencias**: Mover productos entre ubicaciones
7. **Inventario**: Monitorear stock en tiempo real
8. **Sincronización**: Sync manual o automático con Supabase

## Base de Datos Supabase

### Estructura de Tablas (SQL)

```sql
-- Productos
CREATE TABLE productos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  codigo VARCHAR UNIQUE NOT NULL,
  nombre VARCHAR NOT NULL,
  descripcion TEXT,
  categoria VARCHAR NOT NULL,
  unidad_medida VARCHAR NOT NULL,
  precio_compra DECIMAL(10,2) NOT NULL,
  precio_venta DECIMAL(10,2) NOT NULL,
  stock_minimo INTEGER DEFAULT 0,
  eliminado BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Almacenes
CREATE TABLE almacenes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  codigo VARCHAR UNIQUE NOT NULL,
  nombre VARCHAR NOT NULL,
  direccion VARCHAR NOT NULL,
  telefono VARCHAR,
  responsable VARCHAR NOT NULL,
  activo BOOLEAN DEFAULT TRUE,
  eliminado BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tiendas
CREATE TABLE tiendas (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  codigo VARCHAR UNIQUE NOT NULL,
  nombre VARCHAR NOT NULL,
  direccion VARCHAR NOT NULL,
  telefono VARCHAR,
  responsable VARCHAR NOT NULL,
  activo BOOLEAN DEFAULT TRUE,
  eliminado BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Empleados
CREATE TABLE empleados (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  codigo VARCHAR UNIQUE NOT NULL,
  nombres VARCHAR NOT NULL,
  apellidos VARCHAR NOT NULL,
  email VARCHAR UNIQUE NOT NULL,
  telefono VARCHAR NOT NULL,
  rol VARCHAR NOT NULL,
  tienda_id VARCHAR,
  almacen_id VARCHAR,
  activo BOOLEAN DEFAULT TRUE,
  supabase_user_id UUID,
  eliminado BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Inventarios
CREATE TABLE inventarios (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  producto_id VARCHAR NOT NULL,
  ubicacion_tipo VARCHAR NOT NULL,
  ubicacion_id VARCHAR NOT NULL,
  cantidad DECIMAL(10,2) NOT NULL DEFAULT 0,
  ultima_actualizacion TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(producto_id, ubicacion_tipo, ubicacion_id)
);

-- Compras
CREATE TABLE compras (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  numero_compra VARCHAR UNIQUE NOT NULL,
  fecha_compra TIMESTAMPTZ NOT NULL,
  proveedor VARCHAR NOT NULL,
  numero_factura VARCHAR,
  destino_tipo VARCHAR NOT NULL,
  destino_id VARCHAR NOT NULL,
  empleado_id VARCHAR NOT NULL,
  subtotal DECIMAL(10,2) NOT NULL,
  impuesto DECIMAL(10,2) NOT NULL,
  total DECIMAL(10,2) NOT NULL,
  estado VARCHAR NOT NULL,
  observaciones TEXT,
  eliminado BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Detalle Compras
CREATE TABLE detalle_compras (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  compra_id UUID REFERENCES compras(id),
  producto_id VARCHAR NOT NULL,
  cantidad DECIMAL(10,2) NOT NULL,
  precio_unitario DECIMAL(10,2) NOT NULL,
  subtotal DECIMAL(10,2) NOT NULL
);

-- Ventas
CREATE TABLE ventas (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  numero_venta VARCHAR UNIQUE NOT NULL,
  fecha_venta TIMESTAMPTZ NOT NULL,
  tienda_id VARCHAR NOT NULL,
  empleado_id VARCHAR NOT NULL,
  cliente VARCHAR NOT NULL,
  cliente_documento VARCHAR,
  cliente_telefono VARCHAR,
  subtotal DECIMAL(10,2) NOT NULL,
  descuento DECIMAL(10,2) NOT NULL,
  impuesto DECIMAL(10,2) NOT NULL,
  total DECIMAL(10,2) NOT NULL,
  metodo_pago VARCHAR NOT NULL,
  estado VARCHAR NOT NULL,
  observaciones TEXT,
  eliminado BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Detalle Ventas
CREATE TABLE detalle_ventas (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  venta_id UUID REFERENCES ventas(id),
  producto_id VARCHAR NOT NULL,
  cantidad DECIMAL(10,2) NOT NULL,
  precio_unitario DECIMAL(10,2) NOT NULL,
  descuento DECIMAL(10,2) NOT NULL,
  subtotal DECIMAL(10,2) NOT NULL
);

-- Transferencias
CREATE TABLE transferencias (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  numero_transferencia VARCHAR UNIQUE NOT NULL,
  fecha_transferencia TIMESTAMPTZ NOT NULL,
  origen_tipo VARCHAR NOT NULL,
  origen_id VARCHAR NOT NULL,
  destino_tipo VARCHAR NOT NULL,
  destino_id VARCHAR NOT NULL,
  empleado_id VARCHAR NOT NULL,
  estado VARCHAR NOT NULL,
  fecha_recepcion TIMESTAMPTZ,
  empleado_recepcion_id VARCHAR,
  observaciones TEXT,
  eliminado BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Detalle Transferencias
CREATE TABLE detalle_transferencias (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  transferencia_id UUID REFERENCES transferencias(id),
  producto_id VARCHAR NOT NULL,
  cantidad_enviada DECIMAL(10,2) NOT NULL,
  cantidad_recibida DECIMAL(10,2) NOT NULL
);
```

## Características Offline-First

- **Base de datos local Isar**: Todos los datos se almacenan localmente
- **Funcionamiento sin conexión**: La app funciona completamente offline
- **Sincronización inteligente**: Al detectar conexión, sincroniza cambios con Supabase
- **Resolución de conflictos**: Timestamps para determinar versión más reciente
- **Queue de sincronización**: Cambios pendientes se sincronizan en orden

## 3) Seguridad y Cumplimiento

### 3.1 Gestión de usuarios — A07 Fallas de identificación
- **User ID (código de usuario)**: Se define como `Empleado.codigo` con formato `AAA-0000` (3 letras mayúsculas, guion, 4–6 dígitos). Ejemplos: `EMP-0001`, `ADM-1024`. La app valida este formato en el alta/edición.
- **ABM de Usuarios**: Módulo de empleados permite Altas, Bajas lógicas y Modificaciones (pantalla `Empleados`). Los usuarios se asocian a un rol y a una ubicación (tienda/almacén). Campo `supabase_user_id` enlaza la cuenta de autenticación en la nube.
- **Reglas**:
  - Códigos únicos y no reutilizados.
  - Bajas son lógicas (campo `eliminado`) para trazabilidad.
  - Activación/Desactivación controla acceso sin perder histórico.

### 3.2 Gestión de contraseñas — A07 Fallas de autenticación
- **Política de contraseñas** (en `lib/utils/password_policy.dart`):
  - Longitud mínima: 10 caracteres; máxima: 128.
  - Debe contener al menos: 1 mayúscula, 1 minúscula, 1 dígito, 1 símbolo.
  - Bloquea contraseñas comunes.
  - Vida útil sugerida: 90 días (exposición y helper para aviso).
- **Bloqueo por intentos fallidos** (en `AuthService.login`):
  - 5 intentos fallidos → bloqueo de 15 minutos.
  - Reinicio del contador al inicio de sesión exitoso.
- **Hash SHA-256 con sal (offline)**:
  - En registro se guarda localmente `salt + sha256(salt:password)` para permitir verificación offline.
  - La autenticación principal sigue delegada a Supabase (hash seguro en servidor y TLS en tránsito).
- **MFA**:
  - Soportado vía Supabase (OTP/Magic Link/TOTP). Recomendado habilitar MFA en el proyecto de Supabase para cuentas privilegiadas.
- **Almacenamiento**:
  - Las contraseñas no se almacenan localmente; autenticación delegada a Supabase Auth.

### 3.3 Gestión de roles — A01 Pérdida de control de acceso
- **Matriz de roles (resumen)**:

| Rol               | Permisos clave                                                                 |
|-------------------|---------------------------------------------------------------------------------|
| admin             | ver_dashboard, gestionar_productos/almacenes/tiendas/empleados, compras, ventas, transferencias, reportes, inventario_global |
| encargado_tienda  | ver_dashboard, ventas, solicitar_transferencias, inventario_tienda, reportes_tienda |
| encargado_almacen | ver_dashboard, compras, gestionar_transferencias, inventario_almacen, reportes_almacen |
| vendedor          | ventas, inventario_tienda                                                       |

- **ABM de roles y accesos**:
  - El sistema aplica permisos por rol en `AuthService.hasPermission`.
  - Granularidad por permiso nominal; ampliable para crear nuevos roles o modificar permisos existentes.
  - Los roles no usados pueden darse de baja quitándolos de asignaciones y removiéndolos de la matriz.

### 3.4 Criptografía — A02 Fallas criptográficas
- **En tránsito**: Todo el tráfico con Supabase usa TLS (`https`). Requiere URL `https://` para inicializar.
- **En reposo (nube)**: Datos en Postgres gestionado por Supabase (cifrado administrado por el proveedor). Tokens JWT emitidos por Supabase.
- **Cliente local**: Base de datos local SQLite vía Drift. Para datos altamente sensibles se recomienda habilitar una solución con cifrado a nivel de base (p.ej. SQLCipher) o cifrar campos sensibles a nivel de aplicación.
- **Gestión de claves/secrets**: Evitar incrustar llaves en el código distribuible. Use variables de entorno/servicios seguros para `anon key` y URL en despliegues productivos.

## Próximas Funcionalidades

- [ ] Reportes avanzados con gráficos
- [ ] Exportación de datos a Excel/PDF
- [ ] Gestión completa de almacenes y tiendas
- [ ] Gestión completa de empleados
- [ ] Gestión completa de compras
- [ ] Gestión completa de transferencias
- [ ] Códigos de barras/QR
- [ ] Notificaciones push
- [ ] Backup automático
- [ ] Multi-idioma

## Desarrollo

### Generar Modelos Isar

Después de modificar los modelos, ejecutar:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Limpiar Build

```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

## Licencia

Propietario - Todos los derechos reservados

## Soporte

Para soporte o consultas, contactar al equipo de desarrollo.
