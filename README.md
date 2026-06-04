# 🛠️ Gestión de Mantenimiento de Equipos de Laboratorio

<div align="center">

**Base de datos relacional para controlar equipos, técnicos, órdenes de trabajo y repuestos en laboratorios académicos.**

<br>

![SQL Server](https://img.shields.io/badge/SQL%20Server-Base%20de%20Datos-red)
![Estado](https://img.shields.io/badge/Estado-En%20desarrollo-blue)
![Proyecto](https://img.shields.io/badge/Proyecto-Bases%20de%20Datos%20I-green)

</div>

---

## 📌 Descripción general

Este proyecto presenta el diseño e implementación de una base de datos para la **gestión de mantenimiento preventivo y correctivo de equipos de laboratorio**.

La propuesta busca centralizar la información relacionada con los equipos, técnicos, usuarios, laboratorios, repuestos y órdenes de trabajo, evitando registros duplicados y facilitando el seguimiento de cada mantenimiento realizado.

La base de datos permite consultar qué equipo fue atendido, qué técnico fue asignado, qué repuestos se utilizaron y cuál fue el resultado final de cada orden.

---

## 🎯 Objetivo del proyecto

Diseñar una base de datos organizada, clara y funcional que permita controlar el ciclo de mantenimiento de los equipos de laboratorio, desde el registro del equipo hasta la atención de órdenes de trabajo y el uso de repuestos.

El modelo está pensado para mejorar la trazabilidad, el orden de la información y la integridad de los datos mediante relaciones, constraints y schemas.

---

## 🧩 Módulos principales

La base de datos está dividida en módulos mediante **schemas**, lo que permite mantener una estructura más limpia y fácil de entender.

| Módulo          | Schema            | Descripción                                                               |
| --------------- | ----------------- | ------------------------------------------------------------------------- |
| Seguridad       | `Seguridad`       | Controla roles, usuarios y técnicos.                                      |
| Infraestructura | `Infraestructura` | Administra edificios, aulas y laboratorios.                               |
| Inventario      | `Inventario`      | Registra modelos y equipos de laboratorio.                                |
| Mantenimiento   | `Mantenimiento`   | Gestiona órdenes de trabajo, repuestos y detalle de repuestos utilizados. |

---

## 🗂️ Estructura de la base de datos

```text
BD_Gestion_Mantenimiento_Equipos
│
├── Seguridad
│   ├── Roles
│   ├── Usuarios
│   └── Tecnicos
│
├── Infraestructura
│   ├── Edificios
│   ├── Aulas
│   └── Laboratorios
│
├── Inventario
│   ├── Modelos
│   └── Equipos
│
└── Mantenimiento
    ├── Ordenes_de_Trabajo
    ├── Repuestos
    └── Detalle_Orden_Repuesto
```

---

## 🧱 Entidades del modelo

| Entidad                  | Función dentro de la base de datos                                   |
| ------------------------ | -------------------------------------------------------------------- |
| `Roles`                  | Define los tipos de usuarios que pueden existir.                     |
| `Usuarios`               | Almacena la información de las personas registradas.                 |
| `Tecnicos`               | Registra a los usuarios que cumplen funciones técnicas.              |
| `Edificios`              | Guarda los edificios donde se ubican las aulas.                      |
| `Aulas`                  | Representa las áreas físicas donde están los equipos o laboratorios. |
| `Laboratorios`           | Registra los laboratorios disponibles y su responsable.              |
| `Modelos`                | Guarda el modelo y marca de cada tipo de equipo.                     |
| `Equipos`                | Controla el inventario de equipos de laboratorio.                    |
| `Ordenes_de_Trabajo`     | Registra mantenimientos preventivos o correctivos.                   |
| `Repuestos`              | Administra el catálogo de repuestos disponibles.                     |
| `Detalle_Orden_Repuesto` | Relaciona órdenes de trabajo con los repuestos utilizados.           |

---

## 🔗 Relaciones principales

La base de datos mantiene relaciones entre las entidades para asegurar la integridad de la información.

Algunas relaciones importantes son:

* Un rol puede estar asignado a varios usuarios.
* Un usuario puede estar registrado como técnico.
* Un usuario puede ser responsable de uno o varios laboratorios.
* Un edificio puede tener varias aulas.
* Un aula puede contener varios equipos.
* Un modelo puede estar asociado a varios equipos.
* Un equipo puede tener varias órdenes de trabajo.
* Un técnico puede atender varias órdenes.
* Una orden puede utilizar varios repuestos.
* Un repuesto puede aparecer en distintas órdenes de trabajo.

---

## ✅ Validaciones implementadas

El script incluye restricciones para evitar datos incorrectos o inconsistentes.

Entre las validaciones aplicadas se encuentran:

| Tipo de validación | Aplicación                                                        |
| ------------------ | ----------------------------------------------------------------- |
| `PRIMARY KEY`      | Identificación única de cada registro.                            |
| `FOREIGN KEY`      | Relación entre tablas.                                            |
| `UNIQUE`           | Evita duplicidad en campos como correo y número de serie.         |
| `CHECK`            | Controla valores permitidos en estados, prioridades y cantidades. |
| `DEFAULT`          | Asigna valores iniciales en campos como estado o fechas.          |
| `NOT NULL`         | Evita campos obligatorios vacíos.                                 |

---

## 🕒 Auditoría de registros

Todas las tablas incluyen campos de auditoría para llevar control básico sobre los registros.

```sql
created_at
updated_at
deleted_at
```

Estos campos permiten saber cuándo se creó un registro, cuándo fue actualizado y si fue marcado como eliminado de forma lógica.

---

## 📊 Datos de prueba

El script incluye registros simulados para poder probar la base de datos desde el primer momento.

Cada tabla cuenta con al menos **10 filas de datos**, lo que permite verificar relaciones, consultas y restricciones sin tener que insertar información manualmente después de ejecutar el script.

---

## 📄 Archivo principal

El archivo principal del proyecto es:

```text
BD_Mantenimiento_Laboratorios_Final_Schemas.sql
```

Este archivo contiene:

* Creación de la base de datos.
* Creación de schemas.
* Creación de tablas.
* Definición de constraints.
* Inserción de datos de prueba.
* Consultas finales de verificación.

---

## 🚀 Cómo ejecutar el proyecto

1. Abrir **SQL Server Management Studio**.
2. Conectarse al servidor correspondiente.
3. Abrir el archivo `.sql` del proyecto.
4. Ejecutar el script completo una sola vez.
5. Revisar las tablas creadas.
6. Verificar los registros insertados y las relaciones entre entidades.

> Antes de ejecutar el script, se recomienda revisar si ya existe una base de datos con el mismo nombre, especialmente si contiene información importante.

---

## 🧪 Consultas de verificación sugeridas

```sql
SELECT * FROM Seguridad.Usuarios;
SELECT * FROM Seguridad.Tecnicos;
SELECT * FROM Infraestructura.Laboratorios;
SELECT * FROM Inventario.Equipos;
SELECT * FROM Mantenimiento.Ordenes_de_Trabajo;
SELECT * FROM Mantenimiento.Repuestos;
```

También se pueden realizar consultas con `JOIN` para revisar las relaciones entre equipos, técnicos y órdenes de trabajo.

---

## 🧠 Reglas consideradas en el diseño

Durante el desarrollo del modelo se tomaron en cuenta reglas de negocio como:

* Cada usuario debe tener un rol válido.
* Cada técnico debe estar asociado a un usuario existente.
* Cada equipo debe tener un número de serie único.
* Cada equipo debe pertenecer a un aula y a un modelo.
* Una orden debe estar asociada a un equipo y a un técnico.
* Una orden correctiva puede relacionarse con una falla reportada.
* Las cantidades de repuestos no pueden ser negativas.
* La cantidad usada de un repuesto debe ser mayor que cero.
* La fecha de cierre no puede ser menor que la fecha de creación.
* La fecha fuera de servicio no puede ser menor que la fecha de adquisición.

---

## 🧰 Tecnologías utilizadas

* SQL Server
* SQL Server Management Studio
* Lenguaje SQL
* Modelo relacional
* Schemas
* Constraints
* Datos simulados

---

## 👥 Autores

* Jorge Delgado
* Sara Ruiz
* Jhesly Castillo
* Enrique Arana

---

## 🏫 Información académica

**Asignatura:** Bases de Datos I
**Docente:** Msc. José Durán
**Universidad:** Universidad Americana
**Ubicación:** Managua, Nicaragua

---


<div align="center">

**Proyecto académico — Bases de Datos I**

</div>


