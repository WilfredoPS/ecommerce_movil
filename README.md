E-commerce movil

DESARROLLO DE UN SISTEMA MÓVIL FULL STACK ORIENTADA A LA GESTIÓN DE E-COMMERCE

Diseñar y desarrollar un sistema móvil Full Stack con arquitectura híbrida offline-first, utilizando Flutter para el frontend móvil y Supabase (PostgreSQL + Auth + API REST) como backend cloud, con el propósito de optimizar la gestión de e-commerce en tiendas deportivas mediante la centralización de inventarios, trazabilidad de transacciones, control automatizado de stock y mejora en la disponibilidad y seguridad de la información.

## Objetivo general

Diseñar y desarrollar un sistema móvil Full Stack con arquitectura híbrida basada en Flutter y Supabase, con el propósito de optimizar la gestión de e-commerce en tiendas deportivas mediante la centralización de inventarios, la trazabilidad de transacciones y la mejora en la disponibilidad y seguridad de la información
## Objetivos específicos (medibles)

Diseñar una arquitectura híbrida escalable que permita integrar operación offline y sincronización en la nube, con el propósito de garantizar disponibilidad y centralización de datos.
Desarrollar la aplicación móvil utilizando Flutter para proporcionar una interfaz intuitiva que facilite la gestión de productos, pedidos e inventarios.
Implementar un backend en Supabase con base de datos PostgreSQL para asegurar almacenamiento estructurado, integridad referencial y acceso multiusuario.
Diseñar y estructurar el modelo de datos relacional que permita mantener consistencia y trazabilidad de transacciones comerciales.
Incorporar mecanismos de autenticación y control de acceso basados en roles para proteger la información y restringir operaciones sensibles.
Implementar un mecanismo de sincronización entre la base de datos local y la base de datos en la nube para garantizar respaldo y coherencia de datos.
Evaluar el funcionamiento del sistema mediante pruebas funcionales que validen  rendimiento, seguridad y cumplimiento de requerimientos.

## Alcance
1. Autenticación y Control de Acceso
2. Registro y Gestión de Productos Deportivos
3. Catálogo Digital de Productos
4. Carrito de Compras
5. Registro y Gestión de Clientes
6. Gestión de Pedidos
7. Control Automático de Stock
8. Reportes Básicos

### 📊 Stack Tecnológico

- **Flutter**: Framework principal
- **Isar**: Base de datos local (offline-first)
- **Supabase**: Backend y sincronización
- **Provider**: State management
- **Material Design 3**: UI moderna
- **Control de versiones: Git + GitHub

## Arquitectura (resumen simple)
Usuario → App Flutter → Supabase API → PostgreSQL
                ↓
           SQLite (offline)

## Endpoints core (priorizados)

https://your-project.supabase.co/rest/v1/
Authorization: Bearer <JWT>
apikey: <public-anon-key>


Autentificación 
| Método | Endpoint                             | Descripción   |
| ------ | ------------------------------------ | ------------- |
| POST   | `/auth/v1/token?grant_type=password` | Login         |
| POST   | `/auth/v1/signup`                    | Registro      |
| POST   | `/auth/v1/logout`                    | Cerrar sesión |

Productos

| Método | Endpoint                | Descripción         |
| ------ | ----------------------- | ------------------- |
| GET    | `/productos`            | Listar productos    |
| GET    | `/productos?id=eq.{id}` | Obtener producto    |
| POST   | `/productos`            | Crear producto      |
| PATCH  | `/productos?id=eq.{id}` | Actualizar producto |
| DELETE | `/productos?id=eq.{id}` | Eliminar producto   |

Pedidos
| Método | Endpoint              | Descripción    |
| ------ | --------------------- | -------------- |
| GET    | `/pedidos`            | Listar pedidos |
| POST   | `/pedidos`            | Crear pedido   |
| PATCH  | `/pedidos?id=eq.{id}` | Cambiar estado |

Clientes

| Método | Endpoint               | Descripción        |
| ------ | ---------------------- | ------------------ |
| GET    | `/usuarios`            | Listar clientes    |
| POST   | `/usuarios`            | Registrar cliente  |
| PATCH  | `/usuarios?id=eq.{id}` | Actualizar cliente |

Reportes 
| Método | Endpoint                         | Descripción        |
| ------ | -------------------------------- | ------------------ |
| GET    | `/pedidos?select=total,fecha`    | Ventas por período |
| GET    | `/productos?select=nombre,stock` | Inventario actual  |








## Licencia

Propietario - Todos los derechos reservados

## Soporte

Para soporte o consultas, contactar al equipo de desarrollo.
