1. Documentación Técnica Inicial (README)
# Nombre del Proyecto
DESARROLLO DE UN SISTEMA MÓVIL FULL STACK ORIENTADA A LA GESTIÓN DE E-COMMERCE
## Descripción
Sistema móvil Full Stack con arquitectura híbrida offline-first, orientado a la gestión integral de e-commerce para tiendas deportivas.
Permite administrar:
Productos
Inventario
Pedidos
Clientes
Reportes
Autenticación con roles
Opera en modo offline (SQLite) y sincroniza con backend cloud en Supabase (PostgreSQL).
## Objetivo general
Diseñar y desarrollar un sistema móvil Full Stack con arquitectura híbrida basada en Flutter y Supabase, con el propósito de optimizar la gestión de e-commerce en tiendas deportivas mediante la centralización de inventarios, la trazabilidad de transacciones y la mejora en la disponibilidad y seguridad de la información
## Objetivos específicos (medibles)
Diseñar una arquitectura híbrida escalable que permita integrar operación offline y sincronización en la nube, con el propósito de garantizar disponibilidad y centralización de datos.
Desarrollar la aplicación móvil utilizando Flutter para proporcionar una interfaz intuitiva que facilite la gestión de productos, pedidos e inventarios.
Implementar un backend en Supabase con base de datos PostgreSQL para asegurar almacenamiento estructurado, integridad referencial y acceso multiusuario.
Diseñar y estructurar el modelo de datos relacional que permita mantener consistencia y trazabilidad de transacciones comerciales.
Incorporar mecanismos de autenticación y control de acceso basados en roles para proteger la información y restringir operaciones sensibles.
Implementar un mecanismo de sincronización entre la base de datos local y la base de datos en la nube para garantizar respaldo y coherencia de datos.
Evaluar el funcionamiento del sistema mediante pruebas funcionales que validen rendimiento, seguridad y cumplimiento de requerimientos.
## Alcance (qué incluye / qué NO incluye)
1.Autenticación y Control de Acceso
2.Registro y Gestión de Productos Deportivos
3.Catálogo Digital de Productos
4.Carrito de Compras
5.Registro y Gestión de Clientes
6.Gestión de Pedidos
7.Control Automático de Stock
8.Reportes Básicos

No Incluye
Pasarela de pagos
Facturación electrónica
Integración ERP
Microservicios
App iOS o Web
Seguridad avanzada (MFA, auditoría empresarial)

## Stack tecnológico

Capa	Tecnologia	Version	Proposito
Frontend Movil	Flutter + Dart	3.x	UI movil multiplataforma con arquitectura reactiva
Base de Datos Local	SQLite	3.x	Persistencia offline en dispositivo Android
Backend Cloud	Supabase	Latest	BaaS con PostgreSQL, Auth, API REST, Realtime, Storage
Base de Datos Cloud	PostgreSQL	15+	Almacenamiento relacional centralizado en la nube
Autenticacion	Supabase Auth (JWT)	v2	Login seguro con tokens JWT y control de roles
Arquitectura	Clean Architecture	-	Separacion de capas: UI, Logica de Negocio, Datos
Metodologia	Scrum (Agil)	-	Desarrollo iterativo e incremental por sprints
Plataforma Target	Android	12+	Dispositivos moviles Android de gama media-alta



## Arquitectura (resumen simple)
Usuario → App Flutter → Supabase API → PostgreSQL
↓
SQLite (offline)

Capa	Descripcion	Tecnologias
Presentacion (UI)	Interfaces Flutter: LoginScreen, CatalogoScreen, CarritoScreen, PedidosScreen, InventarioScreen, ReportesScreen	Flutter, Dart, Material Design
Logica de Negocio	Servicios: AuthService, InventarioService, VentasService, PedidosService, SyncManager, ReportesService	Dart, Providers/BLoC
Acceso a Datos	Repositorios: SupabaseRepository, LocalSQLiteRepository, AuthRepository, LocalCacheRepo	SQLite, Supabase Dart SDK
Backend Cloud	PostgreSQL + Auth + API REST automatica + Row Level Security + Storage	Supabase, PostgreSQL, PostgREST


## Endpoints core (priorizados)
Endpoint	Metodo	Descripcion	Auth Requerida
/auth/login	POST	Autenticación de usuario - retorna JWT	No
/auth/register	POST	Registro de nuevo usuario con rol	No
/productos	GET	Listar todos los productos activos del catalogo	Si (todos los roles)
/productos	POST	Crear nuevo producto deportivo	Si (Admin)
/productos/:id	PUT	Actualizar datos o stock de un producto	Si (Admin)
/productos/:id	DELETE	Eliminar producto del catalogo	Si (Admin)
/pedidos	POST	Crear nuevo pedido desde el carrito	Si (todos los roles)
/pedidos	GET	Listar pedidos (filtrado por rol del usuario)	Si
/pedidos/:id/estado	PATCH	Actualizar estado del pedido	Si (Admin/Vendedor)
/inventario	GET	Consultar inventario con alertas de bajo stock	Si (Admin/Vendedor)
/reportes/ventas	GET	Reporte de ventas por periodo	Si (Admin)
/sync	POST	Disparar sincronizacion SQLite -> Supabase	Si

## Cómo ejecutar el proyecto (local)
•Flutter SDK 3.x instalado y configurado (flutter doctor OK)
•Android Studio o VS Code con extensiones Flutter/Dart
•Cuenta en Supabase (supabase.com) con proyecto creado
•Dispositivo Android fisico o emulador (API 31+)
•Git instalado

## Variables de entorno
SUPABASE_URL: URL del proyecto en Supabase.
SUPABASE_ANON_KEY: Clave pública para acceso a la API.

2. Configuración Inical del Entorno de Desarrollo Backend
¿Qué hace el sistema que propone en su proyecto?
Automatiza la gestión comercial de tiendas deportivas mediante el control de inventarios, registro de ventas y seguimiento de clientes, permitiendo trabajar sin internet y sincronizar los datos al recuperar la conexión.
Que Tecnologías (stack), utilizara?
Utilizará Flutter para la interfaz móvil, SQLite para la persistencia local y Supabase (PostgreSQL) para la infraestructura en la nube y servicios de autenticación.

Que entidades principales tiene definidas (ejemplo: tablas SQL):
Tabla	Descripcion	Campos Clave	Relaciones
usuarios	Usuarios del sistema con roles diferenciados	id (UUID), email, nombre, rol (enum: admin/vendedor/cliente), activo	Sincronizada con auth.users de Supabase
categorías	Clasificación del catálogo deportivo	id, nombre, descripcion, activo	1:N con productos
productos	Catalogo completo de productos deportivos	id, nombre, categoria_id (FK), precio, stock, talla, color, descripcion, imagen_url, estado	N:1 categorias, 1:N detalle_pedidos, 1:N carrito
pedidos	Ciclo de vida de cada orden de compra	id, usuario_id (FK), fecha, total, estado (enum: pendiente/confirmado/entregado/cancelado)	N:1 usuarios, 1:N detalle_pedidos
detalle_pedidos	Items individuales de cada pedido (N:M)	id, pedido_id (FK), producto_id (FK), cantidad, precio_unitario (snapshot), subtotal (calculado)	N:1 pedidos, N:1 productos
carrito	Estado temporal del carrito antes de confirmar	id, usuario_id (FK), producto_id (FK), cantidad, fecha_agregado	N:1 usuarios, N:1 productos

 Cuál es el flujo principal del sistema que propone?
Tabla	Descripcion	Campos Clave	Relaciones
usuarios	Usuarios del sistema con roles diferenciados	id (UUID), email, nombre, rol (enum: admin/vendedor/cliente), activo	Sincronizada con auth.users de Supabase
categorías	Clasificación del catalogo deportivo	id, nombre, descripcion, activo	1:N con productos
productos	Catalogo completo de productos deportivos	id, nombre, categoria_id (FK), precio, stock, talla, color, descripcion, imagen_url, estado	N:1 categorías, 1:N detalle_pedidos, 1:N carrito
pedidos	Ciclo de vida de cada orden de compra	id, usuario_id (FK), fecha, total, estado (enum: pendiente/confirmado/entregado/cancelado)	N:1 usuarios, 1:N detalle_pedidos
detalle_pedidos	Items individuales de cada pedido (N:M)	id, pedido_id (FK), producto_id (FK), cantidad, precio_unitario (snapshot), subtotal (calculado)	N:1 pedidos, N:1 productos
carrito	Estado temporal del carrito antes de confirmar	id, usuario_id (FK), producto_id (FK), cantidad, fecha_agregado	N:1 usuarios, N:1 productos

3. Implementación Inicial del Backend
Configuración tentativa del Entorno de Desarrollo Backend, según los proyectos que están desarrollando. Debería incluir:
* Configuración de la aplicación (middlewares y rutas) * arranque del servidor
Configuración y Arranque: Uso de los clientes oficiales de Supabase para Flutter. La aplicación inicializa la conexión en el main() validando las variables de entorno.
Middlewares y Rutas: Implementación de guardias de ruta en el frontend para proteger módulos administrativos según el rol (Administrador/Vendedor) obtenido del token JWT.
Modelo y Acceso a Datos: Uso del patrón Repositorio para abstraer si el dato se lee de SQLite o de la API de Supabase.
Reglas de Negocio: Validación de stock suficiente antes de permitir la inserción del pedido en la base de datos

* definición de endpoints * lógica de cada endpoint * reglas de negocio * modelo o acceso a base de datos * conexión a la base de datos * autenticación y validaciones * lectura de variables de entorno
4. Definición de al menos 2 Endpoints (que serán considerados entregables)
Cada Endpoint deberia incluir:

ENDPOINT 1: Crear Pedido desde Carrito
 
Campo	Detalle
Ruta	POST /pedidos  (vía Supabase RPC: crear_pedido_completo)
Método HTTP	POST
Autenticación	JWT requerido (Bearer Token) - Roles: Admin, Vendedor, Cliente
Descripción	Crea un pedido completo desde los ítems del carrito del usuario autenticado, valida stock, registra detalle y descuenta inventario automáticamente via trigger PostgreSQL.
TAREA EP-01: Implementación del Endpoint Crear Pedido
Descripción:
Implementar el endpoint POST /pedidos que permita a un usuario autenticado confirmar su carrito y generar un pedido. El endpoint debe: (1) validar autenticación JWT, (2) verificar disponibilidad de stock para cada ítem, (3) crear el registro de pedido con snapshot de precios, (4) insertar detalle de pedidos, (5) activar el trigger de descuento de stock, y (6) limpiar el carrito del usuario. La implementación debe manejar errores de stock insuficiente y devolver respuestas HTTP correctas.
Resultado Esperado:
Al ejecutar POST /pedidos con un carrito valido: HTTP 201 con el objeto pedido creado incluyendo id, fecha, total y detalle. Al enviar ítems con stock insuficiente: HTTP 400 con mensaje descriptivo. El stock de los productos se descuenta automáticamente en la base de datos. El carrito del usuario queda vacío.
Producto / Resultado Evaluable:
PRODUCTO EVALUABLE: Endpoint funcional que supera los siguientes casos de prueba documentados: (1) Prueba de creación exitosa con stock suficiente - esperado HTTP 201, (2) Prueba de rechazo por stock insuficiente - esperado HTTP 400 con mensaje especifico, (3) Prueba de acceso sin autenticación - esperado HTTP 401, (4) Consulta de stock en base de datos post-pedido muestra descuento correcto. METRICA: 4/4 casos de prueba pasados + código documentado en repositorio Git.


ENDPOINT 2: Gestion de Productos Deportivos (CRUD)
 
Campo	Detalle
Ruta Base	/productos (Supabase PostgREST automático)
Metodos	GET (listar) | POST (crear) | PUT/:id (actualizar) | DELETE/:id (eliminar)
Autenticación	JWT requerido - GET: todos los roles | POST/PUT/DELETE: solo Admin
Descripción	CRUD completo para la gestión del catalogo de productos deportivos. Incluye validaciones de campos obligatorios, gestión de imágenes via Supabase Storage, actualización de stock y políticas RLS que restringen operaciones criticas al rol administrador.


TAREA EP-02: Implementacion del CRUD de Productos con Control de Acceso
Descripción:
Implementar el modulo completo de gestión de productos que incluya: (1) Endpoint GET /productos con filtrado por categoría y búsqueda por nombre, funcionando en modo offline-first (SQLite) con fallback a Supabase; (2) Endpoint POST /productos con validaciones de campos obligatorios, subida de imagen a Supabase Storage y restricción por rol Admin via RLS; (3) Endpoint PUT /productos/:id para actualización de datos y stock; (4) Endpoint DELETE /productos/:id con restricción de rol Admin. Todos los endpoints deben implementar manejo de errores, logging y sincronización con la base de datos local.
Resultado Esperado:
Al ejecutar GET /productos: Lista de productos activos con datos de categoría, funcionando tanto online (datos de Supabase) como offline (datos de SQLite). Al ejecutar POST /productos como Admin: HTTP 201 con el producto creado e imagen URL. Al ejecutar POST /productos como Vendedor/Cliente: HTTP 403. Al ejecutar DELETE como Admin: HTTP 204, producto eliminado de Supabase y SQLite. Validaciones retornan HTTP 400 con mensajes descriptivos.
Producto / Resultado Evaluable:
PRODUCTO EVALUABLE: Suite de pruebas que demuestre el correcto funcionamiento del CRUD: (1) GET retorna lista con >= 1 producto - HTTP 200, (2) POST con rol Admin crea producto - HTTP 201 con datos completos, (3) POST con rol Vendedor es rechazado - HTTP 403, (4) POST sin campos obligatorios - HTTP 400 con detalle del error, (5) DELETE con rol Admin elimina el producto - HTTP 204, (6) DELETE con rol Vendedor es rechazado - HTTP 403. ENTREGABLE: Código en repositorio Git + colección Postman/Thunder Client con los 6 casos de prueba documentados y capturas de pantalla de respuestas.
