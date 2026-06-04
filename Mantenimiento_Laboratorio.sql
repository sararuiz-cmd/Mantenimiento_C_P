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
   Mínimo solicitado: 10 registros por tabla.
   ============================================================ */
INSERT INTO Seguridad.Roles (id_rol, nombre_rol, descripcion_rol) VALUES
('R001', N'Administrador', N'Usuario con permisos de gestión general'),
('R002', N'Técnico', N'Usuario encargado de atender órdenes de mantenimiento'),
('R003', N'Responsable', N'Usuario encargado de un laboratorio'),
('R004', N'Reportante', N'Usuario que puede reportar fallas'),
('R005', N'Encargado almacén', N'Usuario encargado de controlar repuestos'),
('R006', N'Gerencia', N'Usuario que consulta informes y costos'),
('R007', N'Supervisor', N'Usuario que supervisa mantenimiento'),
('R008', N'Auditor', N'Usuario que revisa trazabilidad de datos'),
('R009', N'Coordinador', N'Usuario que coordina laboratorios'),
('R010', N'Auxiliar', N'Usuario con apoyo operativo');
GO

INSERT INTO Seguridad.Usuarios (id_usuario, nombre, apellido, correo, telefono, contrasena_hash, id_rol, estado_usuario) VALUES
('U001', N'Sara', N'Ruiz', N'sara@gmail.com', '8888-1111', N'hash_001', 'R001', N'Activo'),
('U002', N'Jorge', N'Delgado', N'jorge@gmail.com', '7777-2222', N'hash_002', 'R002', N'Activo'),
('U003', N'Enrique', N'Arana', N'enrique@gmail.com', '8666-3333', N'hash_003', 'R003', N'Activo'),
('U004', N'Jhesly', N'Castillo', N'jhesly@gmail.com', '8555-4444', N'hash_004', 'R004', N'Activo'),
('U005', N'Carlos', N'Méndez', N'carlos@gmail.com', '8444-5555', N'hash_005', 'R002', N'Activo'),
('U006', N'Valeria', N'López', N'valeria@gmail.com', '8333-6666', N'hash_006', 'R002', N'Activo'),
('U007', N'Mario', N'Pérez', N'mario@gmail.com', '8222-7777', N'hash_007', 'R002', N'Activo'),
('U008', N'Ana', N'García', N'ana@gmail.com', '8111-8888', N'hash_008', 'R002', N'Activo'),
('U009', N'Luis', N'Ramírez', N'luis@gmail.com', '8999-9999', N'hash_009', 'R002', N'Activo'),
('U010', N'Karla', N'Torres', N'karla@gmail.com', '8777-1212', N'hash_010', 'R002', N'Activo'),
('U011', N'Diego', N'Vargas', N'diego@gmail.com', '8666-2323', N'hash_011', 'R002', N'Activo'),
('U012', N'Lucía', N'Navarro', N'lucia@gmail.com', '8555-3434', N'hash_012', 'R002', N'Activo'),
('U013', N'Pedro', N'Morales', N'pedro@gmail.com', '8444-4545', N'hash_013', 'R002', N'Activo'),
('U014', N'Rosa', N'Herrera', N'rosa@gmail.com', '8333-5656', N'hash_014', 'R005', N'Activo'),
('U015', N'Gabriel', N'Castro', N'gabriel@gmail.com', '8222-6767', N'hash_015', 'R006', N'Activo');
GO

INSERT INTO Seguridad.Tecnicos (id_tecnico, id_usuario, especialidad, disponibilidad, estado_tecnico) VALUES
('T001', 'U002', N'Hardware', N'Disponible', N'Activo'),
('T002', 'U005', N'Redes', N'Ocupado', N'Activo'),
('T003', 'U006', N'Software', N'Disponible', N'Activo'),
('T004', 'U007', N'Impresoras', N'Disponible', N'Activo'),
('T005', 'U008', N'Electrónica', N'No disponible', N'Activo'),
('T006', 'U009', N'Climatización', N'Disponible', N'Activo'),
('T007', 'U010', N'Equipos de medición', N'Ocupado', N'Activo'),
('T008', 'U011', N'Cableado estructurado', N'Disponible', N'Activo'),
('T009', 'U012', N'Mantenimiento preventivo', N'Disponible', N'Activo'),
('T010', 'U013', N'Soporte general', N'Disponible', N'Activo');
GO

INSERT INTO Infraestructura.Edificios (id_edificio, nombre_edificio, cantidad_pisos) VALUES
('ED001', N'Edificio A', 2),
('ED002', N'Edificio B', 1),
('ED003', N'Edificio C', 3),
('ED004', N'Edificio D', 3),
('ED005', N'Edificio E', 4),
('ED006', N'Edificio F', 2),
('ED007', N'Edificio G', 5),
('ED008', N'Edificio H', 3),
('ED009', N'Edificio I', 2),
('ED010', N'Edificio J', 4);
GO

INSERT INTO Infraestructura.Aulas (aula_id, referencia, estado_aula, id_edificio, piso) VALUES
('AUL001', N'Aula 102, frente a coordinación', N'Activa', 'ED001', 2),
('AUL002', N'Aula 102, cerca de recepción', N'Activa', 'ED002', 1),
('AUL003', N'Aula 103, pasillo principal', N'Activa', 'ED003', 1),
('AUL004', N'Área 301, junto a bodega', N'Inactiva', 'ED004', 3),
('AUL005', N'Aula 201, ala norte', N'Activa', 'ED005', 2),
('AUL006', N'Aula 101, entrada principal', N'Activa', 'ED006', 1),
('AUL007', N'Aula 401, zona de prácticas', N'Activa', 'ED007', 4),
('AUL008', N'Aula 202, segunda planta', N'Activa', 'ED008', 2),
('AUL009', N'Aula 105, pasillo sur', N'Activa', 'ED009', 1),
('AUL010', N'Aula 302, laboratorio auxiliar', N'Activa', 'ED010', 3);
GO

INSERT INTO Infraestructura.Laboratorios (id_laboratorio, nombre_laboratorio, descripcion, id_responsable, estado_laboratorio, aula_id) VALUES
('L001', N'Laboratorio de Redes', N'Prácticas de redes y conectividad', 'U003', N'Activo', 'AUL001'),
('L002', N'Laboratorio de Programación', N'Prácticas de programación', 'U001', N'Activo', 'AUL002'),
('L003', N'Laboratorio de Hardware', N'Revisión y práctica con equipos', 'U003', N'Activo', 'AUL003'),
('L004', N'Laboratorio de Electrónica', N'Prácticas de circuitos', 'U001', N'Inactivo', 'AUL004'),
('L005', N'Laboratorio de Física', N'Prácticas con instrumentos de medición', 'U003', N'Activo', 'AUL005'),
('L006', N'Laboratorio de Química', N'Prácticas con equipos de análisis', 'U001', N'Activo', 'AUL006'),
('L007', N'Laboratorio de Automatización', N'Prácticas de control y sensores', 'U003', N'Activo', 'AUL007'),
('L008', N'Laboratorio de Robótica', N'Prácticas con robots educativos', 'U001', N'Activo', 'AUL008'),
('L009', N'Laboratorio de Base de Datos', N'Prácticas de gestores de bases de datos', 'U003', N'Activo', 'AUL009'),
('L010', N'Laboratorio de Soporte Técnico', N'Área de diagnóstico y reparación', 'U001', N'Activo', 'AUL010');
GO

INSERT INTO Inventario.Modelos (id_modelo, nombre_modelo, marca) VALUES
('MOD001', N'ProBook 440', N'HP'),
('MOD002', N'L3150', N'Epson'),
('MOD003', N'OptiPlex 3080', N'Dell'),
('MOD004', N'ThinkCentre M70', N'Lenovo'),
('MOD005', N'Catalyst 2960', N'Cisco'),
('MOD006', N'Arduino Uno R3', N'Arduino'),
('MOD007', N'Raspberry Pi 4', N'Raspberry'),
('MOD008', N'LaserJet Pro M404', N'HP'),
('MOD009', N'Inspiron 15', N'Dell'),
('MOD010', N'IdeaCentre 3', N'Lenovo');
GO

INSERT INTO Inventario.Equipos (id_equipo, aula_id, numero_serie, id_modelo, criticidad, fecha_adquisicion, estado_equipo, fecha_fuera_servicio) VALUES
('EQ001', 'AUL001', N'HP12345', 'MOD001', N'Alta', '2024-02-10', N'Activo', NULL),
('EQ002', 'AUL002', N'EP98765', 'MOD002', N'Media', '2024-03-15', N'Activo', NULL),
('EQ003', 'AUL003', N'DL45678', 'MOD003', N'Alta', '2024-04-20', N'Fuera de servicio', '2026-05-21'),
('EQ004', 'AUL004', N'LN78901', 'MOD004', N'Baja', '2024-05-05', N'Inactivo', NULL),
('EQ005', 'AUL005', N'CS2960-001', 'MOD005', N'Alta', '2024-06-11', N'Activo', NULL),
('EQ006', 'AUL006', N'ARD-UNO-006', 'MOD006', N'Media', '2024-07-18', N'Activo', NULL),
('EQ007', 'AUL007', N'RPI4-007', 'MOD007', N'Media', '2024-08-09', N'Activo', NULL),
('EQ008', 'AUL008', N'HP-LJ-008', 'MOD008', N'Baja', '2024-09-22', N'Activo', NULL),
('EQ009', 'AUL009', N'DELL-INS-009', 'MOD009', N'Alta', '2024-10-13', N'Activo', NULL),
('EQ010', 'AUL010', N'LEN-IC3-010', 'MOD010', N'Media', '2024-11-25', N'Activo', NULL);
GO

INSERT INTO Inventario.Repuestos (id_repuesto, nombre_repuesto, categoria, unidad_medida, cantidad_disponible, stock_minimo, costo_unitario, estado) VALUES
('R001', N'Fuente de poder', N'Hardware', N'Unidad', 10, 2, 850.00, N'Activo'),
('R002', N'Cable HDMI', N'Accesorio', N'Unidad', 25, 5, 180.00, N'Activo'),
('R003', N'Pasta térmica', N'Insumo', N'Unidad', 15, 3, 120.00, N'Activo'),
('R004', N'Cable de red', N'Accesorio', N'Unidad', 30, 6, 90.00, N'Activo'),
('R005', N'Memoria RAM 8GB', N'Hardware', N'Unidad', 12, 3, 950.00, N'Activo'),
('R006', N'Disco SSD 480GB', N'Almacenamiento', N'Unidad', 8, 2, 1450.00, N'Activo'),
('R007', N'Teclado USB', N'Periférico', N'Unidad', 20, 5, 260.00, N'Activo'),
('R008', N'Mouse óptico', N'Periférico', N'Unidad', 22, 5, 150.00, N'Activo'),
('R009', N'Cartucho de tinta', N'Impresión', N'Unidad', 14, 4, 700.00, N'Activo'),
('R010', N'Batería CMOS', N'Hardware', N'Unidad', 18, 5, 80.00, N'Activo');
GO

INSERT INTO Mantenimiento.Ordenes_de_Trabajo (
    id_orden, id_equipo, id_tecnico, id_falla, tipo_mantenimiento, prioridad_orden,
    fecha_creacion, estado_orden, diagnostico, actividades_realizadas,
    resultado_final, fecha_cierre, id_usuario_reporta
) VALUES
('O001', 'EQ001', 'T001', 'F001', N'Correctivo', N'Alta', '2026-05-10', N'Cerrada', N'Fuente dañada', N'Revisión y cambio de fuente', N'Equipo reparado', '2026-05-12', 'U004'),
('O002', 'EQ002', 'T002', 'F002', N'Correctivo', N'Media', '2026-05-11', N'En proceso', N'Pendiente de revisión', N'Diagnóstico inicial', N'Pendiente', NULL, 'U004'),
('O003', 'EQ003', 'T003', NULL, N'Preventivo', N'Media', '2026-05-13', N'Programada', N'Pendiente de revisión', N'Limpieza programada', N'Pendiente', NULL, 'U001'),
('O004', 'EQ004', 'T004', 'F004', N'Correctivo', N'Baja', '2026-05-14', N'Cerrada', N'Cable dañado', N'Cambio de cable', N'Equipo funcional', '2026-05-15', 'U003'),
('O005', 'EQ005', 'T005', NULL, N'Preventivo', N'Alta', '2026-05-16', N'Programada', N'Revisión preventiva planificada', N'Pendiente', N'Pendiente', NULL, 'U014'),
('O006', 'EQ006', 'T006', 'F006', N'Correctivo', N'Media', '2026-05-17', N'En proceso', N'Falla intermitente de encendido', N'Pruebas iniciales', N'Pendiente', NULL, 'U004'),
('O007', 'EQ007', 'T007', NULL, N'Preventivo', N'Baja', '2026-05-18', N'Cerrada', N'Mantenimiento preventivo completado', N'Limpieza y actualización básica', N'Equipo operativo', '2026-05-19', 'U003'),
('O008', 'EQ008', 'T008', 'F008', N'Correctivo', N'Media', '2026-05-20', N'Cerrada', N'Atasco de impresión', N'Limpieza de rodillos y cambio de cartucho', N'Impresora funcional', '2026-05-21', 'U014'),
('O009', 'EQ009', 'T009', NULL, N'Preventivo', N'Media', '2026-05-22', N'Programada', N'Revisión de rendimiento planificada', N'Pendiente', N'Pendiente', NULL, 'U001'),
('O010', 'EQ010', 'T010', 'F010', N'Correctivo', N'Alta', '2026-05-23', N'Cerrada', N'Disco con errores', N'Cambio de SSD y pruebas', N'Equipo reparado', '2026-05-24', 'U004');
GO

INSERT INTO Mantenimiento.Detalle_Orden_Repuesto (id_orden, id_repuesto, cantidad_usada) VALUES
('O001', 'R001', 1),
('O001', 'R003', 1),
('O002', 'R002', 1),
('O004', 'R004', 2),
('O006', 'R010', 1),
('O007', 'R003', 1),
('O008', 'R009', 1),
('O008', 'R004', 1),
('O010', 'R006', 1),
('O010', 'R005', 1);
GO
