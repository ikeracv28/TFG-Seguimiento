# Manual de Usuario — Nexus FCT
**Plataforma de gestión de prácticas académicas (FCT)**
Versión 1.0 — Mayo 2026

---

## Índice

1. [Introducción](#1-introducción)
2. [Acceso a la plataforma](#2-acceso-a-la-plataforma)
3. [Alumno](#3-alumno)
4. [Tutor de empresa](#4-tutor-de-empresa)
5. [Tutor de centro](#5-tutor-de-centro)
6. [Administrador](#6-administrador)
7. [Funcionalidades comunes](#7-funcionalidades-comunes)

---

## 1. Introducción

Nexus es una plataforma web para la gestión integral del ciclo de prácticas en empresa (FCT). Centraliza el seguimiento de horas, la validación de partes de trabajo, la comunicación entre alumno y tutores, y la gestión administrativa del centro.

### Roles del sistema

| Rol | Descripción |
|-----|-------------|
| **Alumno** | Estudiante en prácticas. Registra su actividad diaria o semanal. |
| **Tutor de empresa** | Responsable en la empresa. Valida o rechaza los partes del alumno. |
| **Tutor de centro** | Tutor del instituto. Supervisa el proceso, gestiona incidencias y da el visto bueno final. |
| **Administrador** | Gestiona usuarios, prácticas y empresas del sistema. |

### Flujo de validación de partes

```
Alumno registra parte
        ↓
  PENDIENTE EMPRESA
        ↓
Tutor empresa valida/rechaza
     ↓           ↓
PENDIENTE     RECHAZADO
  CENTRO    (incidencia automática)
     ↓
Tutor centro confirma
     ↓
 COMPLETADO
```

---

## 2. Acceso a la plataforma

### Inicio de sesión

1. Accede a la URL de la plataforma en el navegador.
2. Introduce tu **correo electrónico** y **contraseña**.
3. Pulsa **Iniciar sesión**.

La plataforma redirige automáticamente a la pantalla correspondiente a tu rol.

> Si introduces credenciales incorrectas, el sistema muestra un mensaje de error. No revela si el correo existe o no (seguridad contra enumeración de cuentas).

### Cierre de sesión

Pulsa el icono de usuario en la esquina superior de la barra lateral y selecciona **Cerrar sesión**. La sesión se invalida en el servidor (no basta con cerrar el navegador).

---

## 3. Alumno

### 3.1 Panel de inicio

Al iniciar sesión el alumno accede a su **Dashboard**, que muestra:

- **Resumen de práctica**: empresa, fechas de inicio y fin, tutores asignados.
- **Progreso de horas**: barra de progreso con horas totales validadas sobre las horas requeridas.
- **Partes pendientes**: número de partes sin validar por el tutor de empresa.
- **Últimas notificaciones**: acceso rápido a avisos recientes.

### 3.2 Registrar un parte de trabajo

1. En la barra lateral, selecciona **Seguimientos**.
2. Pulsa el botón **+ Nuevo parte** (esquina inferior derecha).
3. Aparece el diálogo de registro. Elige el tipo de parte:

**Parte diario**
- Selecciona la **fecha** del día trabajado (no se permiten fechas futuras).
- Ajusta las **horas** con los botones +/- (máximo 24 h).
- Escribe una **descripción** de las tareas realizadas (mínimo 10 caracteres).

**Parte semanal**
- Selecciona la **semana** (se guarda como el lunes de esa semana).
- Ajusta las **horas por día** con los botones +/- (máximo 12 h/día).
- Ajusta los **días trabajados** esa semana (1 a 5).
- El **total de la semana** se calcula automáticamente.
- Escribe la descripción de tareas.

4. Pulsa **Guardar parte**. El parte queda en estado **Pendiente empresa**.

> Puedes registrar varios partes pendientes de validación a la vez, sin necesidad de esperar a que el tutor de empresa valide el anterior.

### 3.3 Consultar el historial de partes

La pantalla de **Seguimientos** muestra todos tus partes en una tabla con:

| Columna | Descripción |
|---------|-------------|
| Fecha | Día exacto (diario) o rango de semana (semanal, ej. "Sem. 12–16 may") |
| Horas | Horas del parte. Los partes semanales muestran el sufijo `/sem` |
| Descripción | Resumen de las tareas declaradas |
| Estado | Pendiente empresa / Pendiente centro / Completado / Rechazado |

#### Estados de un parte

| Estado | Significado | Color |
|--------|-------------|-------|
| **Pendiente empresa** | Esperando validación del tutor de empresa | Naranja |
| **Pendiente centro** | Tutor de empresa validó, esperando al tutor de centro | Azul |
| **Completado** | Ambos tutores han validado. Horas contabilizadas | Verde |
| **Rechazado** | El tutor de empresa lo rechazó con un motivo | Rojo |

### 3.4 Consultar incidencias

En **Incidencias** puedes ver:
- Las incidencias abiertas asociadas a tu práctica.
- Las incidencias creadas automáticamente cuando un tutor de empresa rechaza un parte (tipo *Rechazo de parte*).
- Reportar una nueva incidencia: selecciona el **tipo** y escribe una **descripción**.

### 3.5 Consultar ausencias

En **Ausencias** aparecen los días de falta registrados por el tutor de centro, con fecha, justificación y si ha sido revisada.

### 3.6 Chat con el tutor de centro

En **Chat** puedes enviar mensajes en tiempo real a tu tutor de centro. Los mensajes se reciben instantáneamente gracias al protocolo WebSocket. Recibirás una notificación cuando el tutor te responda.

### 3.7 Perfil y foto

Pulsa tu **avatar** en la barra lateral para acceder al perfil:
- Ver tus datos personales.
- **Subir o cambiar tu foto de perfil** (formatos JPG/PNG, máximo 5 MB).

---

## 4. Tutor de empresa

### 4.1 Panel principal

Al iniciar sesión accedes a tu panel con dos pestañas en la barra lateral:

- **Partes pendientes** — lista de partes que esperan tu validación.
- **Chat con tutor de centro** — canal de comunicación directa con el tutor del instituto.

El panel de inicio muestra un resumen con el número de partes pendientes de revisión.

### 4.2 Validar un parte

En la pestaña **Partes pendientes** aparece una tarjeta por cada parte sin validar:

- **Nombre del alumno** y su foto de perfil.
- **Fecha o rango de semana** del parte.
- **Horas declaradas** (con sufijo `/sem` si es un parte semanal).
- **Descripción** de las tareas realizadas.

Para actuar sobre un parte tienes dos opciones:

**Aprobar el parte**
1. Pulsa el botón **Validar** (icono de marca de verificación verde).
2. El parte pasa a estado *Pendiente centro* y el tutor de centro recibe notificación.

**Rechazar el parte**
1. Pulsa el botón **Rechazar** (icono de X rojo).
2. Escribe el **motivo del rechazo** (obligatorio).
3. Confirma. El parte pasa a estado *Rechazado* y se crea una incidencia automática de tipo *Rechazo de parte*. El alumno es notificado.

### 4.3 Evaluar al alumno

Al finalizar las prácticas, el tutor de empresa puede cumplimentar la **evaluación final**:

1. Accede a la ficha del alumno desde el panel.
2. Pulsa **Evaluar alumno**.
3. Puntúa cada criterio con el deslizador (0–10). El color del deslizador indica el nivel: rojo (bajo), ámbar (medio), verde (alto).
4. La **nota global** se calcula automáticamente como media.
5. Pulsa **Guardar evaluación**.

### 4.4 Chat con el tutor de centro

En la pestaña **Chat** puedes enviar mensajes al tutor de centro en tiempo real (canal *Tutores*, independiente del canal alumno-tutor).

---

## 5. Tutor de centro

### 5.1 Navegación

El panel del tutor de centro tiene cinco secciones accesibles desde la barra lateral:

| Sección | Descripción |
|---------|-------------|
| **Dashboard** | Resumen global: alumnos activos, partes pendientes, incidencias abiertas |
| **Alumnos** | Lista de alumnos con acceso a la ficha individual de cada uno |
| **Partes** | Todos los partes en estado *Pendiente centro* para validar |
| **Incidencias** | Gestión de todas las incidencias activas |
| **Chat alumno** | Canal de comunicación con el alumno |
| **Chat tutores** | Canal de comunicación con el tutor de empresa |

### 5.2 Dashboard

Muestra cuatro tarjetas de resumen:
- Alumnos en prácticas activas.
- Partes pendientes de tu validación.
- Incidencias abiertas.
- Horas totales validadas este mes.

### 5.3 Ficha del alumno

Desde **Alumnos**, pulsa sobre cualquier alumno para abrir su ficha completa, que incluye:

- Datos de la práctica (empresa, fechas, tutores).
- Historial completo de partes con estados y horas.
- Listado de incidencias.
- Listado de ausencias.
- Evaluación final del tutor de empresa (si ya se ha cumplimentado).

#### Exportar expediente

Desde la ficha del alumno, en la barra superior:

- Botón **PDF** (rojo): genera un informe A4 multipágina con todos los datos del expediente FCT (datos práctica, seguimientos, incidencias, ausencias, evaluación). Se abre el diálogo de impresión del navegador.
- Botón **Excel** (verde): descarga un archivo `.xlsx` con cinco hojas (Información, Seguimientos, Incidencias, Ausencias, Evaluación) con formato de colores y anchos de columna.

### 5.4 Validar partes (vista Partes)

En la sección **Partes** aparece la tabla de partes en estado *Pendiente centro*:

- Muestra alumno, empresa, fecha (o rango semanal), horas y descripción.
- Pulsa **Validar** para completar el parte. El alumno recibe notificación y las horas se acumulan en su progreso.

### 5.5 Gestionar ausencias

Dentro de la ficha de un alumno puedes registrar ausencias:
1. Pulsa **Nueva ausencia**.
2. Selecciona la **fecha**.
3. Indica si está **justificada** y añade una descripción.
4. Guarda. El alumno puede consultar sus ausencias en su panel.

### 5.6 Gestionar incidencias

En la sección **Incidencias** puedes:
- Ver todas las incidencias abiertas con tipo, fecha y descripción.
- Pulsar sobre una incidencia para cambiar su estado: **Abierta → En gestión → Resuelta**.
- Las incidencias de tipo *Rechazo de parte* se crean automáticamente cuando el tutor de empresa rechaza un parte.

### 5.7 Chat

- **Chat alumno**: canal directo con el alumno en tiempo real.
- **Chat tutores**: canal privado con el tutor de empresa (el alumno no ve estos mensajes).

---

## 6. Administrador

### 6.1 Panel principal

El panel de administración tiene tres secciones:

| Sección | Descripción |
|---------|-------------|
| **Usuarios** | Gestión de todos los usuarios del sistema |
| **Prácticas** | Gestión de las asignaciones de prácticas |
| **Empresas** | Gestión del catálogo de empresas colaboradoras |

Cada sección incluye un buscador en tiempo real y estadísticas en las tarjetas superiores.

### 6.2 Gestión de usuarios

Muestra una tabla con todos los usuarios filtrable por nombre, email o rol.

- **Crear usuario**: pulsa **+ Nuevo usuario**, rellena nombre, apellidos, DNI, email, contraseña y rol.
- **Editar usuario**: pulsa el icono de lápiz en la fila del usuario.
- **Desactivar/activar**: cambia el estado activo del usuario sin eliminarlo.

### 6.3 Gestión de prácticas

Lista todas las prácticas con su estado (Activa / Finalizada / Pendiente).

- **Crear práctica**: asigna alumno, tutor de centro, tutor de empresa y empresa. El sistema genera un código único.
- **Editar práctica**: modifica cualquier campo de la asignación.
- **Ver detalle**: accede al resumen de horas y estado de la práctica.

Filtros disponibles: **Todas / En curso / Finalizadas / Pendientes**.

### 6.4 Gestión de empresas

Catálogo de empresas colaboradoras del centro.

- **Crear empresa**: nombre, CIF (único en el sistema), dirección, email de contacto y teléfono.
- **Editar empresa**: modifica los datos de contacto.
- **Eliminar empresa**: solo es posible si la empresa no tiene prácticas asignadas.

> El CIF debe ser único. El sistema rechaza duplicados con un mensaje de error descriptivo.

---

## 7. Funcionalidades comunes

### 7.1 Notificaciones

El icono de campana en la barra superior muestra el número de notificaciones no leídas. Las notificaciones se actualizan automáticamente cada 30 segundos.

| Evento | Quién recibe la notificación |
|--------|------------------------------|
| Tutor empresa valida un parte | Tutor de centro |
| Tutor empresa rechaza un parte | Alumno + tutor de centro |
| Tutor centro completa un parte | Alumno |
| Alumno envía mensaje en el chat | Tutor de centro |
| Tutor de centro o empresa envía mensaje | El otro participante del canal |

Pulsa sobre una notificación para marcarla como leída y acceder a la pantalla correspondiente.

### 7.2 Foto de perfil

Disponible para todos los roles. Desde el **Perfil** (avatar en la barra lateral):
1. Pulsa sobre la foto actual o el círculo con tus iniciales.
2. Selecciona una imagen desde tu dispositivo (JPG o PNG, máximo 5 MB).
3. La imagen se actualiza automáticamente en todos los paneles donde apareces (chat, lista de alumnos, tarjetas de partes).

### 7.3 Modo oscuro

La plataforma adapta automáticamente el tema claro u oscuro según la configuración del sistema operativo.

### 7.4 Adaptación a dispositivos

- **Escritorio / tablet** (más de 600 px): barra lateral fija con iconos y etiquetas.
- **Móvil** (menos de 600 px): navegación inferior con las secciones principales.

---

*Nexus FCT — CampusFP · Iker Acevedo Donate · 2026*
