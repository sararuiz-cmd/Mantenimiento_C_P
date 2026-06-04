/* ============================================================
   Proyecto: Base de datos para gestión de mantenimiento
    SCHEMAS:
   - Seguridad: roles, usuarios y técnicos.
   - Infraestructura: edificios, aulas y laboratorios.
   - Inventario: modelos, equipos y repuestos.
   - Mantenimiento: órdenes de trabajo y detalle de repuestos usados.
   ============================================================ */

USE master;
GO

IF EXISTS (SELECT 1 FROM sys.databases WHERE name = N'BD_Mantenimiento_Laboratorios')
BEGIN
    DROP DATABASE BD_Mantenimiento_Laboratorios;
END;
GO

CREATE DATABASE BD_Mantenimiento_Laboratorios;
GO

USE BD_Mantenimiento_Laboratorios;
GO
/* ============================================================
   CREACIÓN DE SCHEMAS
   ============================================================ */
CREATE SCHEMA Seguridad;
GO
CREATE SCHEMA Infraestructura;
GO
CREATE SCHEMA Inventario;
GO
CREATE SCHEMA Mantenimiento;
GO


/* ============================================================
   SCHEMA: Seguridad
   Módulo relacionado: SM01 Gestión de usuarios, roles y técnicos
   ============================================================ */
CREATE TABLE Seguridad.Roles (
    id_rol CHAR(4) NOT NULL,
    nombre_rol NVARCHAR(30) NOT NULL,
    descripcion_rol NVARCHAR(150) NULL,
    created_at DATETIME NOT NULL CONSTRAINT DF_Roles_created_at DEFAULT GETDATE(),
    updated_at DATETIME NULL,
    deleted_at DATETIME NULL,

    CONSTRAINT PK_Roles PRIMARY KEY (id_rol),
    CONSTRAINT UQ_Roles_nombre_rol UNIQUE (nombre_rol),
    CONSTRAINT CK_Roles_id_formato CHECK (id_rol LIKE 'R[0-9][0-9][0-9]')
);
GO

CREATE TABLE Seguridad.Usuarios (
    id_usuario CHAR(4) NOT NULL,
    nombre NVARCHAR(50) NOT NULL,
    apellido NVARCHAR(50) NOT NULL,
    correo NVARCHAR(100) NOT NULL,
    telefono VARCHAR(15) NOT NULL,
    contrasena_hash NVARCHAR(255) NOT NULL,
    id_rol CHAR(4) NOT NULL,
    estado_usuario NVARCHAR(20) NOT NULL CONSTRAINT DF_Usuarios_estado_usuario DEFAULT N'Activo',
    created_at DATETIME NOT NULL CONSTRAINT DF_Usuarios_created_at DEFAULT GETDATE(),
    updated_at DATETIME NULL,
    deleted_at DATETIME NULL,

    CONSTRAINT PK_Usuarios PRIMARY KEY (id_usuario),
    CONSTRAINT UQ_Usuarios_correo UNIQUE (correo),
    CONSTRAINT CK_Usuarios_id_formato CHECK (id_usuario LIKE 'U[0-9][0-9][0-9]'),
    CONSTRAINT CK_Usuarios_correo CHECK (correo LIKE '%_@_%._%'),
    CONSTRAINT CK_Usuarios_telefono CHECK (telefono LIKE '[0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]'),
    CONSTRAINT CK_Usuarios_estado_usuario CHECK (estado_usuario IN (N'Activo', N'Inactivo')),
    CONSTRAINT FK_Usuarios_Roles FOREIGN KEY (id_rol)
        REFERENCES Seguridad.Roles(id_rol)
        ON DELETE NO ACTION
        ON UPDATE CASCADE
);
GO

CREATE TABLE Seguridad.Tecnicos (
    id_tecnico CHAR(4) NOT NULL,
    id_usuario CHAR(4) NOT NULL,
    especialidad NVARCHAR(50) NOT NULL,
    disponibilidad NVARCHAR(20) NOT NULL CONSTRAINT DF_Tecnicos_disponibilidad DEFAULT N'Disponible',
    estado_tecnico NVARCHAR(20) NOT NULL CONSTRAINT DF_Tecnicos_estado_tecnico DEFAULT N'Activo',
    created_at DATETIME NOT NULL CONSTRAINT DF_Tecnicos_created_at DEFAULT GETDATE(),
    updated_at DATETIME NULL,
    deleted_at DATETIME NULL,

    CONSTRAINT PK_Tecnicos PRIMARY KEY (id_tecnico),
    CONSTRAINT UQ_Tecnicos_id_usuario UNIQUE (id_usuario),
    CONSTRAINT CK_Tecnicos_id_formato CHECK (id_tecnico LIKE 'T[0-9][0-9][0-9]'),
    CONSTRAINT CK_Tecnicos_disponibilidad CHECK (disponibilidad IN (N'Disponible', N'Ocupado', N'No disponible')),
    CONSTRAINT CK_Tecnicos_estado_tecnico CHECK (estado_tecnico IN (N'Activo', N'Inactivo')),
    CONSTRAINT FK_Tecnicos_Usuarios FOREIGN KEY (id_usuario)
        REFERENCES Seguridad.Usuarios(id_usuario)
        ON DELETE NO ACTION
        ON UPDATE CASCADE
);
GO

/* ============================================================
   SCHEMA: Infraestructura
   Módulo relacionado: SM02 Gestión de laboratorios, edificios y aulas
   ============================================================ */
CREATE TABLE Infraestructura.Edificios (
    id_edificio CHAR(6) NOT NULL,
    nombre_edificio NVARCHAR(50) NOT NULL,
    cantidad_pisos INT NOT NULL,
    created_at DATETIME NOT NULL CONSTRAINT DF_Edificios_created_at DEFAULT GETDATE(),
    updated_at DATETIME NULL,
    deleted_at DATETIME NULL,

    CONSTRAINT PK_Edificios PRIMARY KEY (id_edificio),
    CONSTRAINT UQ_Edificios_nombre_edificio UNIQUE (nombre_edificio),
    CONSTRAINT CK_Edificios_cantidad_pisos CHECK (cantidad_pisos > 0)
);
GO

CREATE TABLE Infraestructura.Aulas (
    aula_id VARCHAR(20) NOT NULL,
    referencia NVARCHAR(100) NULL,
    estado_aula NVARCHAR(20) NOT NULL CONSTRAINT DF_Aulas_estado_aula DEFAULT N'Activa',
    id_edificio CHAR(6) NOT NULL,
    piso INT NOT NULL,
    created_at DATETIME NOT NULL CONSTRAINT DF_Aulas_created_at DEFAULT GETDATE(),
    updated_at DATETIME NULL,
    deleted_at DATETIME NULL,

    CONSTRAINT PK_Aulas PRIMARY KEY (aula_id),
    CONSTRAINT UQ_Aulas_edificio_piso_referencia UNIQUE (id_edificio, piso, referencia),
    CONSTRAINT CK_Aulas_estado_aula CHECK (estado_aula IN (N'Activa', N'Inactiva')),
    CONSTRAINT CK_Aulas_piso CHECK (piso > 0),
    CONSTRAINT FK_Aulas_Edificios FOREIGN KEY (id_edificio)
        REFERENCES Infraestructura.Edificios(id_edificio)
        ON DELETE NO ACTION
        ON UPDATE CASCADE
);
GO

CREATE TABLE Infraestructura.Laboratorios (
    id_laboratorio CHAR(4) NOT NULL,
    nombre_laboratorio NVARCHAR(100) NOT NULL,
    descripcion NVARCHAR(255) NULL,
    id_responsable CHAR(4) NOT NULL,
    estado_laboratorio NVARCHAR(20) NOT NULL CONSTRAINT DF_Laboratorios_estado_laboratorio DEFAULT N'Activo',
    aula_id VARCHAR(20) NOT NULL,
    created_at DATETIME NOT NULL CONSTRAINT DF_Laboratorios_created_at DEFAULT GETDATE(),
    updated_at DATETIME NULL,
    deleted_at DATETIME NULL,

    CONSTRAINT PK_Laboratorios PRIMARY KEY (id_laboratorio),
    CONSTRAINT UQ_Laboratorios_nombre_laboratorio UNIQUE (nombre_laboratorio),
    CONSTRAINT UQ_Laboratorios_aula_id UNIQUE (aula_id),
    CONSTRAINT CK_Laboratorios_id_formato CHECK (id_laboratorio LIKE 'L[0-9][0-9][0-9]'),
    CONSTRAINT CK_Laboratorios_estado_laboratorio CHECK (estado_laboratorio IN (N'Activo', N'Inactivo')),
    CONSTRAINT FK_Laboratorios_Usuarios FOREIGN KEY (id_responsable)
        REFERENCES Seguridad.Usuarios(id_usuario)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    CONSTRAINT FK_Laboratorios_Aulas FOREIGN KEY (aula_id)
        REFERENCES Infraestructura.Aulas(aula_id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE
);
GO

/* ============================================================
   SCHEMA: Inventario
   Módulos relacionados: SM03 Gestión de equipos y SM07 Gestión de repuestos y costos
   ============================================================ */
CREATE TABLE Inventario.Modelos (
    id_modelo CHAR(6) NOT NULL,
    nombre_modelo NVARCHAR(100) NOT NULL,
    marca NVARCHAR(50) NOT NULL,
    created_at DATETIME NOT NULL CONSTRAINT DF_Modelos_created_at DEFAULT GETDATE(),
    updated_at DATETIME NULL,
    deleted_at DATETIME NULL,

    CONSTRAINT PK_Modelos PRIMARY KEY (id_modelo),
    CONSTRAINT UQ_Modelos_nombre_marca UNIQUE (nombre_modelo, marca),
    CONSTRAINT CK_Modelos_id_formato CHECK (id_modelo LIKE 'MOD[0-9][0-9][0-9]')
);
GO

CREATE TABLE Inventario.Equipos (
    id_equipo CHAR(5) NOT NULL,
    aula_id VARCHAR(20) NOT NULL,
    numero_serie NVARCHAR(50) NOT NULL,
    id_modelo CHAR(6) NOT NULL,
    criticidad NVARCHAR(20) NOT NULL CONSTRAINT DF_Equipos_criticidad DEFAULT N'Media',
    fecha_adquisicion DATE NOT NULL,
    estado_equipo NVARCHAR(30) NOT NULL CONSTRAINT DF_Equipos_estado_equipo DEFAULT N'Activo',
    fecha_fuera_servicio DATE NULL,
    created_at DATETIME NOT NULL CONSTRAINT DF_Equipos_created_at DEFAULT GETDATE(),
    updated_at DATETIME NULL,
    deleted_at DATETIME NULL,

    CONSTRAINT PK_Equipos PRIMARY KEY (id_equipo),
    CONSTRAINT UQ_Equipos_numero_serie UNIQUE (numero_serie),
    CONSTRAINT CK_Equipos_id_formato CHECK (id_equipo LIKE 'EQ[0-9][0-9][0-9]'),
    CONSTRAINT CK_Equipos_criticidad CHECK (criticidad IN (N'Baja', N'Media', N'Alta')),
    CONSTRAINT CK_Equipos_estado_equipo CHECK (estado_equipo IN (N'Activo', N'Inactivo', N'Fuera de servicio')),
    CONSTRAINT CK_Equipos_fecha_fuera_servicio CHECK (fecha_fuera_servicio IS NULL OR fecha_fuera_servicio >= fecha_adquisicion),
    CONSTRAINT CK_Equipos_activo_sin_fecha_fuera CHECK (estado_equipo <> N'Activo' OR fecha_fuera_servicio IS NULL),
    CONSTRAINT FK_Equipos_Aulas FOREIGN KEY (aula_id)
        REFERENCES Infraestructura.Aulas(aula_id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    CONSTRAINT FK_Equipos_Modelos FOREIGN KEY (id_modelo)
        REFERENCES Inventario.Modelos(id_modelo)
        ON DELETE NO ACTION
        ON UPDATE CASCADE
);
GO

CREATE TABLE Inventario.Repuestos (
    id_repuesto CHAR(4) NOT NULL,
    nombre_repuesto NVARCHAR(100) NOT NULL,
    categoria NVARCHAR(50) NOT NULL,
    unidad_medida NVARCHAR(30) NOT NULL CONSTRAINT DF_Repuestos_unidad_medida DEFAULT N'Unidad',
    cantidad_disponible INT NOT NULL CONSTRAINT DF_Repuestos_cantidad_disponible DEFAULT 0,
    stock_minimo INT NOT NULL CONSTRAINT DF_Repuestos_stock_minimo DEFAULT 0,
    costo_unitario DECIMAL(10,2) NOT NULL CONSTRAINT DF_Repuestos_costo_unitario DEFAULT 0.00,
    estado NVARCHAR(20) NOT NULL CONSTRAINT DF_Repuestos_estado DEFAULT N'Activo',
    created_at DATETIME NOT NULL CONSTRAINT DF_Repuestos_created_at DEFAULT GETDATE(),
    updated_at DATETIME NULL,
    deleted_at DATETIME NULL,

    CONSTRAINT PK_Repuestos PRIMARY KEY (id_repuesto),
    CONSTRAINT UQ_Repuestos_nombre_repuesto UNIQUE (nombre_repuesto),
    CONSTRAINT CK_Repuestos_id_formato CHECK (id_repuesto LIKE 'R[0-9][0-9][0-9]'),
    CONSTRAINT CK_Repuestos_cantidad_disponible CHECK (cantidad_disponible >= 0),
    CONSTRAINT CK_Repuestos_stock_minimo CHECK (stock_minimo >= 0),
    CONSTRAINT CK_Repuestos_costo_unitario CHECK (costo_unitario >= 0.00),
    CONSTRAINT CK_Repuestos_estado CHECK (estado IN (N'Activo', N'Inactivo'))
);
GO
/* ============================================================
   SCHEMA: Mantenimiento
   Módulos relacionados: SM05, SM06 y SM07
   ============================================================ */
CREATE TABLE Mantenimiento.Ordenes_de_Trabajo (
    id_orden CHAR(4) NOT NULL,
    id_equipo CHAR(5) NOT NULL,
    id_tecnico CHAR(4) NOT NULL,
    id_falla CHAR(4) NULL,
    tipo_mantenimiento NVARCHAR(20) NOT NULL,
    prioridad_orden NVARCHAR(20) NOT NULL CONSTRAINT DF_Ordenes_prioridad_orden DEFAULT N'Media',
    fecha_creacion DATE NOT NULL,
    estado_orden NVARCHAR(30) NOT NULL CONSTRAINT DF_Ordenes_estado_orden DEFAULT N'Programada',
    diagnostico NVARCHAR(255) NULL,
    actividades_realizadas NVARCHAR(255) NULL,
    resultado_final NVARCHAR(255) NULL,
    fecha_cierre DATE NULL,
    id_usuario_reporta CHAR(4) NOT NULL,
    created_at DATETIME NOT NULL CONSTRAINT DF_Ordenes_created_at DEFAULT GETDATE(),
    updated_at DATETIME NULL,
    deleted_at DATETIME NULL,

    CONSTRAINT PK_Ordenes_de_Trabajo PRIMARY KEY (id_orden),
    CONSTRAINT CK_Ordenes_id_formato CHECK (id_orden LIKE 'O[0-9][0-9][0-9]'),
    CONSTRAINT CK_Ordenes_tipo_mantenimiento CHECK (tipo_mantenimiento IN (N'Preventivo', N'Correctivo')),
    CONSTRAINT CK_Ordenes_prioridad_orden CHECK (prioridad_orden IN (N'Baja', N'Media', N'Alta')),
    CONSTRAINT CK_Ordenes_estado_orden CHECK (estado_orden IN (N'Programada', N'En proceso', N'Cerrada')),
    CONSTRAINT CK_Ordenes_fecha_cierre CHECK (fecha_cierre IS NULL OR fecha_cierre >= fecha_creacion),
    CONSTRAINT CK_Ordenes_falla_segun_tipo CHECK (
        (tipo_mantenimiento = N'Correctivo' AND id_falla IS NOT NULL)
        OR
        (tipo_mantenimiento = N'Preventivo' AND id_falla IS NULL)
    ),
    CONSTRAINT CK_Ordenes_cierre_obligatorio CHECK (
        (
            estado_orden = N'Cerrada'
            AND fecha_cierre IS NOT NULL
            AND diagnostico IS NOT NULL
            AND actividades_realizadas IS NOT NULL
            AND resultado_final IS NOT NULL
        )
        OR
        (
            estado_orden <> N'Cerrada'
            AND fecha_cierre IS NULL
        )
    ),
    CONSTRAINT FK_Ordenes_Equipos FOREIGN KEY (id_equipo)
        REFERENCES Inventario.Equipos(id_equipo)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    CONSTRAINT FK_Ordenes_Tecnicos FOREIGN KEY (id_tecnico)
        REFERENCES Seguridad.Tecnicos(id_tecnico)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,
    CONSTRAINT FK_Ordenes_Usuarios_Reporta FOREIGN KEY (id_usuario_reporta)
        REFERENCES Seguridad.Usuarios(id_usuario)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
);
GO

CREATE TABLE Mantenimiento.Detalle_Orden_Repuesto (
    id_orden CHAR(4) NOT NULL,
    id_repuesto CHAR(4) NOT NULL,
    cantidad_usada INT NOT NULL,
    created_at DATETIME NOT NULL CONSTRAINT DF_Detalle_created_at DEFAULT GETDATE(),
    updated_at DATETIME NULL,
    deleted_at DATETIME NULL,

    CONSTRAINT PK_Detalle_Orden_Repuesto PRIMARY KEY (id_orden, id_repuesto),
    CONSTRAINT CK_Detalle_cantidad_usada CHECK (cantidad_usada >= 1),
    CONSTRAINT FK_Detalle_Ordenes FOREIGN KEY (id_orden)
        REFERENCES Mantenimiento.Ordenes_de_Trabajo(id_orden)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT FK_Detalle_Repuestos FOREIGN KEY (id_repuesto)
        REFERENCES Inventario.Repuestos(id_repuesto)
        ON DELETE NO ACTION
        ON UPDATE CASCADE
);
GO

/* ============================================================
   INSERCIÓN DE DATOS SIMULADOS
   Fechas convertidas a formato ISO: YYYY-MM-DD
   ============================================================ */

INSERT INTO Roles (id_rol, nombre_rol, descripcion_rol) VALUES
('R001', 'Administrador', 'Usuario con permisos de gestión general'),
('R002', 'Técnico', 'Usuario encargado de atender órdenes de mantenimiento'),
('R003', 'Responsable', 'Usuario encargado de un laboratorio'),
('R004', 'Reportante', 'Usuario que puede reportar fallas');
GO

INSERT INTO Usuarios (id_usuario, nombre, apellido, correo, telefono, contrasena_hash, id_rol, estado_usuario) VALUES
('U001', 'Sara', 'Ruiz', 'sara@gmail.com', '8888-1111', 'hash_001', 'R001', 'Activo'),
('U002', 'Jorge', 'Delgado', 'jorge@gmail.com', '7777-2222', 'hash_002', 'R002', 'Activo'),
('U003', 'Enrique', 'Arana', 'enrique@gmail.com', '8666-3333', 'hash_003', 'R003', 'Activo'),
('U004', 'Jhesly', 'Castillo', 'jhesly@gmail.com', '8555-4444', 'hash_004', 'R004', 'Activo'),
('U005', 'Carlos', 'Méndez', 'carlos@gmail.com', '8444-5555', 'hash_005', 'R002', 'Activo'),
('U006', 'Valeria', 'López', 'valeria@gmail.com', '8333-6666', 'hash_006', 'R002', 'Activo'),
('U007', 'Mario', 'Pérez', 'mario@gmail.com', '8222-7777', 'hash_007', 'R002', 'Activo');
GO

INSERT INTO Tecnicos (id_tecnico, id_usuario, especialidad, disponibilidad, estado_tecnico) VALUES
('T001', 'U002', 'Hardware', 'Disponible', 'Activo'),
('T002', 'U005', 'Redes', 'Ocupado', 'Activo'),
('T003', 'U006', 'Software', 'Disponible', 'Activo'),
('T004', 'U007', 'Impresoras', 'Disponible', 'Activo');
GO

INSERT INTO Edificio (id_edificio, nombre_edificio, cantidad_pisos) VALUES
('ED001', 'Edificio A', 2),
('ED002', 'Edificio B', 1),
('ED003', 'Edificio C', 3),
('ED004', 'Edificio D', 3);
GO

INSERT INTO Aula (aula_id, referencia, estado_aula, id_edificio, piso) VALUES
('AUL001', 'Aula 102, frente a coordinación', 'Activa', 'ED001', 2),
('AUL002', 'Aula 102, cerca de recepción', 'Activa', 'ED002', 1),
('AUL003', 'Aula 103, pasillo principal', 'Activa', 'ED003', 1),
('AUL004', 'Área 301, junto a bodega', 'Inactiva', 'ED004', 3);
GO

INSERT INTO Laboratorios (id_laboratorio, nombre_laboratorio, descripcion, id_responsable, estado_laboratorio, aula_id) VALUES
('L001', 'Laboratorio de Redes', 'Prácticas de redes y conectividad', 'U003', 'Activo', 'AUL001'),
('L002', 'Laboratorio de Programación', 'Prácticas de programación', 'U001', 'Activo', 'AUL002'),
('L003', 'Laboratorio de Hardware', 'Revisión y práctica con equipos', 'U003', 'Activo', 'AUL003'),
('L004', 'Laboratorio de Electrónica', 'Prácticas de circuitos', 'U001', 'Inactivo', 'AUL004');
GO

INSERT INTO Modelos (id_modelo, nombre_modelo, marca) VALUES
('MOD001', 'ProBook 440', 'HP'),
('MOD002', 'L3150', 'Epson'),
('MOD003', 'OptiPlex 3080', 'Dell'),
('MOD004', 'ThinkCentre M70', 'Lenovo');
GO

INSERT INTO Equipos (id_equipo, aula_id, numero_serie, id_modelo, criticidad, fecha_adquisicion, estado_equipo, fecha_fuera_servicio) VALUES
('EQ001', 'AUL001', 'HP12345', 'MOD001', 'Alta', '2024-02-10', 'Activo', NULL),
('EQ002', 'AUL002', 'EP98765', 'MOD002', 'Media', '2024-03-15', 'Activo', NULL),
('EQ003', 'AUL003', 'DL45678', 'MOD003', 'Alta', '2024-04-20', 'Fuera de servicio', '2026-05-21'),
('EQ004', 'AUL004', 'LN78901', 'MOD004', 'Baja', '2024-05-05', 'Inactivo', NULL);
GO

INSERT INTO Ordenes_de_Trabajo (
    id_orden, id_equipo, id_tecnico, id_falla, tipo_mantenimiento, prioridad_orden,
    fecha_creacion, estado_orden, diagnostico, actividades_realizadas,
    resultado_final, fecha_cierre, id_usuario_reporta
) VALUES
('O001', 'EQ001', 'T001', 'F001', 'Correctivo', 'Alta', '2026-05-10', 'Cerrada', 'Fuente dañada', 'Revisión y cambio de fuente', 'Equipo reparado', '2026-05-12', 'U004'),
('O002', 'EQ002', 'T002', 'F002', 'Correctivo', 'Media', '2026-05-11', 'En proceso', 'Pendiente de revisión', 'Diagnóstico inicial', 'Pendiente', NULL, 'U004'),
('O003', 'EQ003', 'T003', NULL, 'Preventivo', 'Media', '2026-05-13', 'Programada', 'Pendiente de revisión', 'Limpieza programada', 'Pendiente', NULL, 'U001'),
('O004', 'EQ004', 'T004', 'F004', 'Correctivo', 'Baja', '2026-05-14', 'Cerrada', 'Cable dañado', 'Cambio de cable', 'Equipo funcional', '2026-05-15', 'U003');
GO

INSERT INTO Repuestos (id_repuesto, nombre_repuesto, categoria, unidad_medida, cantidad_disponible, stock_minimo, costo_unitario, estado) VALUES
('R001', 'Fuente de poder', 'Hardware', 'Unidad', 10, 2, 850.00, 'Activo'),
('R002', 'Cable HDMI', 'Accesorio', 'Unidad', 25, 5, 180.00, 'Activo'),
('R003', 'Pasta térmica', 'Insumo', 'Unidad', 15, 3, 120.00, 'Activo'),
('R004', 'Cable de red', 'Accesorio', 'Unidad', 30, 6, 90.00, 'Activo');
GO

INSERT INTO Detalle_Orden_Repuesto (id_orden, id_repuesto, cantidad_usada) VALUES
('O001', 'R001', 1),
('O001', 'R003', 1),
('O002', 'R002', 1),
('O004', 'R004', 2);
GO

/* ============================================================
   CONSULTAS DE VERIFICACIÓN DE RELACIONES
   ============================================================ 

-- Usuarios con su rol
SELECT u.id_usuario, u.nombre, u.apellido, r.nombre_rol, u.estado_usuario
FROM Usuarios u
INNER JOIN Roles r ON u.id_rol = r.id_rol;
GO

-- Equipos con aula, edificio y modelo/marca
SELECT e.id_equipo, e.numero_serie, a.referencia, ed.nombre_edificio, m.nombre_modelo, m.marca, e.estado_equipo
FROM Equipos e
INNER JOIN Aula a ON e.aula_id = a.aula_id
INNER JOIN Edificio ed ON a.id_edificio = ed.id_edificio
INNER JOIN Modelos m ON e.id_modelo = m.id_modelo;
GO

-- Órdenes con equipo, técnico y usuario reportante
SELECT o.id_orden, o.tipo_mantenimiento, o.estado_orden, eq.numero_serie,
       t.id_tecnico, uTec.nombre AS tecnico_nombre, uRep.nombre AS reporta_nombre
FROM Ordenes_de_Trabajo o
INNER JOIN Equipos eq ON o.id_equipo = eq.id_equipo
INNER JOIN Tecnicos t ON o.id_tecnico = t.id_tecnico
INNER JOIN Usuarios uTec ON t.id_usuario = uTec.id_usuario
INNER JOIN Usuarios uRep ON o.id_usuario_reporta = uRep.id_usuario;
GO

-- Repuestos utilizados por orden
SELECT d.id_orden, r.nombre_repuesto, d.cantidad_usada, r.costo_unitario,
       d.cantidad_usada * r.costo_unitario AS costo_total
FROM Detalle_Orden_Repuesto d
INNER JOIN Repuestos r ON d.id_repuesto = r.id_repuesto;
GO
*/