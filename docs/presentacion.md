## Sistema de Inventario - Documento de Presentación

Autor: [Tu nombre]

Fecha: [AAAA-MM-DD]

Versión: 1.0


## Resumen ejecutivo

Breve descripción del sistema, objetivo y alcance. Destacar que es “offline-first” con sincronización a la nube (Supabase).


## Objetivos

- Centralizar la gestión de productos, ventas, compras y transferencias
- Operación sin conexión y sincronización confiable
- Control de acceso por roles


## Alcance

- Módulos incluidos en esta versión
- Plataformas objetivo: Android, iOS, Web, Desktop (Windows/macOS/Linux)


## Arquitectura y stack

- App: Flutter (Dart), Material Design 3
- Estado: Riverpod
- Persistencia local: Drift + SQLite
- Backend/BaaS: Supabase (PostgreSQL, Auth)
- Sincronización: servicios de sync y RLS (JWT) en Supabase


## Módulos y funcionalidades

- Autenticación y roles
- Dashboard
- Productos (ABM, filtros)
- Ventas (POS, métodos de pago, totales)
- Inventario (por ubicación, alertas de stock)
- Reportes (visión general)
- Administración: almacenes, tiendas, empleados
- Compras y transferencias


## Seguridad (resumen 3.1 a 3.4)

- 3.1 Gestión de usuarios (A07): User ID con formato `AAA-0000`, ABM, bajas lógicas, activación/desactivación
- 3.2 Contraseñas (A07): Política de complejidad, bloqueo 5 intentos/15min, MFA vía Supabase, hash SHA-256 con sal para modo offline
- 3.3 Roles (A01): Matriz de permisos por rol; granularidad ampliable
- 3.4 Criptografía (A02): TLS en tránsito con Supabase; recomendaciones de cifrado en reposo


## Capturas del sistema

Coloca las imágenes en `docs/capturas/` con la siguiente nomenclatura y reemplaza el texto “Pie de figura” por una breve descripción.

1. Login  
![Login](capturas/01-login.png)  
Pie de figura: Pantalla de autenticación

2. Dashboard  
![Dashboard](capturas/02-dashboard.png)  
Pie de figura: Resumen de ventas del día y accesos rápidos

3. Productos (lista)  
![Productos](capturas/03-productos.png)  
Pie de figura: Listado de productos con búsqueda y filtros

4. Productos (formulario)  
![Productos - Formulario](capturas/03b-producto-form.png)  
Pie de figura: Alta/edición de producto

5. Ventas (flujo)  
![Ventas](capturas/04-ventas.png)  
Pie de figura: Registro de una venta con ítems

6. Inventario  
![Inventario](capturas/05-inventario.png)  
Pie de figura: Stock por ubicación con alertas

7. Reportes  
![Reportes](capturas/06-reportes.png)  
Pie de figura: Vista general de reportes

8. Empleados  
![Empleados](capturas/07-empleados.png)  
Pie de figura: ABM de usuarios/empleados

9. Almacenes  
![Almacenes](capturas/08-almacenes.png)  
Pie de figura: Listado de almacenes

10. Tiendas  
![Tiendas](capturas/09-tiendas.png)  
Pie de figura: Listado de tiendas

11. Compras  
![Compras](capturas/10-compras.png)  
Pie de figura: Registro/consulta de compras

12. Transferencias  
![Transferencias](capturas/11-transferencias.png)  
Pie de figura: Transferencias entre ubicaciones


## Flujos clave

- Flujo de venta: Selección de cliente → agregación de productos → totales → confirmación → descuento de inventario
- Flujo de compra: Registro de compra → destino (almacén/tienda) → impacto en inventario
- Flujo de transferencia: Origen/destino → cantidades → recepción


## Operación Offline-First y sincronización

- Base local (Drift/SQLite) y cola de cambios

- Auto-sync al detectar conectividad con Supabase

- Resolución básica por timestamps


## Conclusiones

Valor aportado, próximos pasos y mejoras planificadas.


## Anexos

- Matriz de roles y permisos (resumen)
- Política de contraseñas (reglas vigentes)
- Esquema SQL de Supabase (referencia: `supabase_schema.sql`)


---

### Exportar a DOCX o PDF (opcional, requiere pandoc instalado)

DOCX:

```bash
pandoc docs/presentacion.md -o docs/presentacion.docx
```

PDF (si tienes LaTeX):

```bash
pandoc docs/presentacion.md -o docs/presentacion.pdf
```




