/* ============================================================
   Proyecto: Base de datos para gestión de mantenimiento
   Motor recomendado: Microsoft SQL Server
   Descripción:
   - Crea la base de datos.
   - Crea tablas con atributos, PK, FK, UNIQUE, CHECK y DEFAULT.
   - Respeta las entidades actuales: Roles, Usuarios, Tecnicos,
     Laboratorios, Edificio, Aula, Modelos, Equipos,
     Ordenes_de_Trabajo, Repuestos y Detalle_Orden_Repuesto.
   - No usa Locaciones, Marcas ni Fallas_Correctivas como tablas separadas.
   - Usa nombres de tablas con guion bajo cuando son compuestos.
   - Laboratorios.aula_id se define como UNIQUE: un aula tiene como máximo un laboratorio.
   ============================================================ */

USE master;
GO

IF DB_ID('BD_Mantenimiento_Laboratorios') IS NOT NULL
BEGIN
    ALTER DATABASE BD_Mantenimiento_Laboratorios SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE BD_Mantenimiento_Laboratorios;
END;
GO

CREATE DATABASE BD_Mantenimiento_Laboratorios;
GO

USE BD_Mantenimiento_Laboratorios;
GO

/* ============================================================
   1. TABLA: Roles
   Cardinalidad: Roles 1 ---- N Usuarios
   ============================================================ */
CREATE TABLE Roles (
    id_rol CHAR(4) NOT NULL,
    nombre_rol NVARCHAR(30) NOT NULL,
    descripcion_rol NVARCHAR(150) NULL,
    
    -- Auditoría
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME NULL,
    deleted_at DATETIME NULL,

    CONSTRAINT PK_Roles PRIMARY KEY (id_rol),
    CONSTRAINT UQ_Roles_nombre_rol UNIQUE (nombre_rol)
);
GO

/* ============================================================
   2. TABLA: Usuarios
   Cardinalidad: Usuarios N ---- 1 Roles
   ============================================================ */
CREATE TABLE Usuarios (
    id_usuario CHAR(4) NOT NULL,
    nombre NVARCHAR(50) NOT NULL,
    apellido NVARCHAR(50) NOT NULL,
    correo NVARCHAR(100) NOT NULL,
    telefono VARCHAR(15) NOT NULL,
    contrasena_hash NVARCHAR(255) NOT NULL,
    id_rol CHAR(4) NOT NULL,
    estado_usuario NVARCHAR(20) NOT NULL CONSTRAINT DF_Usuarios_estado DEFAULT 'Activo',
    
    -- Auditoría
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME NULL,
    deleted_at DATETIME NULL,

    CONSTRAINT PK_Usuarios PRIMARY KEY (id_usuario),
    CONSTRAINT UQ_Usuarios_correo UNIQUE (correo),
    CONSTRAINT UQ_Usuarios_Id_Rol UNIQUE (id_usuario, id_rol), -- Necesario para la FK compuesta en Técnicos
    CONSTRAINT FK_Usuarios_Roles FOREIGN KEY (id_rol)
        REFERENCES Roles(id_rol)
        ON UPDATE CASCADE
        ON DELETE NO ACTION,
    CONSTRAINT CK_Usuarios_estado CHECK (estado_usuario IN ('Activo', 'Inactivo')),
    CONSTRAINT CK_Usuarios_correo CHECK (correo LIKE '%_@_%._%'),
    CONSTRAINT CK_Usuarios_telefono CHECK (telefono LIKE '[0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]')
);
GO

/* ============================================================
   3. TABLA: Tecnicos
   Cardinalidad: Usuarios 1 ---- 0..1 Tecnicos
   Un usuario solo puede aparecer una vez como técnico.
   ============================================================ */
CREATE TABLE Tecnicos (
    id_tecnico             CHAR(4)        NOT NULL,
    id_usuario             CHAR(4)        NOT NULL,
    id_rol                 CHAR(4)        NOT NULL DEFAULT 'R002',
    especialidad           NVARCHAR(50)   NOT NULL,
    disponibilidad         NVARCHAR(20)   NOT NULL DEFAULT 'Disponible',
    estado_tecnico         NVARCHAR(20)   NOT NULL DEFAULT 'Activo',
    created_at             DATETIME                DEFAULT GETDATE(),
    updated_at             DATETIME        NULL,
    deleted_at             DATETIME        NULL,

    -- RESTRICCIONES (PK, UQ, FK, CK)
    CONSTRAINT PK_Tecnicos 
        PRIMARY KEY (id_tecnico),
    CONSTRAINT UQ_Tecnicos_id_usuario 
        UNIQUE (id_usuario),
    CONSTRAINT CK_Tecnicos_SoloRolTecnico 
        CHECK (id_rol = 'R002'),
    CONSTRAINT FK_Tecnicos_Usuarios_Rol 
        FOREIGN KEY (id_usuario, id_rol) REFERENCES Usuarios(id_usuario, id_rol) 
        ON UPDATE CASCADE 
        ON DELETE NO ACTION,
    CONSTRAINT CK_Tecnicos_disponibilidad 
        CHECK (disponibilidad IN ('Disponible', 'Ocupado', 'No disponible')),
    CONSTRAINT CK_Tecnicos_estado 
        CHECK (estado_tecnico IN ('Activo', 'Inactivo'))
);
GO
/* ============================================================
   4. TABLA: Edificio
   Cardinalidad: Edificio 1 ---- N Aula
   ============================================================ */
CREATE TABLE Edificio (
    id_edificio            CHAR(5)        NOT NULL,
    nombre_edificio        NVARCHAR(50)   NOT NULL,
    amount_pisos           INT            NOT NULL,
    created_at             DATETIME                DEFAULT GETDATE(),
    updated_at             DATETIME        NULL,
    deleted_at             DATETIME        NULL,

    -- RESTRICCIONES (PK, CK)
    CONSTRAINT PK_Edificio 
        PRIMARY KEY (id_edificio),
    CONSTRAINT CK_Edificio_cantidad_pisos 
        CHECK (amount_pisos > 0)
);
GO
/* ============================================================
   5. TABLA: Aula
   Cardinalidad: Aula N ---- 1 Edificio
   ============================================================ */
CREATE TABLE Aula (
    aula_id                CHAR(6)        NOT NULL,
    referencia             NVARCHAR(100)  NOT NULL,
    estado_aula            NVARCHAR(20)   NOT NULL DEFAULT 'Activa',
    id_edificio            CHAR(5)        NOT NULL,
    piso                   INT            NOT NULL,
    created_at             DATETIME                DEFAULT GETDATE(),
    updated_at             DATETIME        NULL,
    deleted_at             DATETIME        NULL,

    -- RESTRICCIONES (PK, FK, CK)
    CONSTRAINT PK_Aula 
        PRIMARY KEY (aula_id),
    CONSTRAINT FK_Aula_Edificio 
        FOREIGN KEY (id_edificio) REFERENCES Edificio(id_edificio) 
        ON UPDATE CASCADE 
        ON DELETE NO ACTION,
    CONSTRAINT CK_Aula_estado 
        CHECK (estado_aula IN ('Activa', 'Inactiva')),
    CONSTRAINT CK_Aula_piso_positivo 
        CHECK (piso >= 0)
);
GO
/* ============================================================
   6. TABLA: Laboratorios
   Cardinalidad:
   - Usuarios 1 ---- N Laboratorios como responsables.
   - Aula 1 ---- 0..1 Laboratorios.
     Decisión aplicada: un aula tendrá como máximo un laboratorio.
   ============================================================ */
CREATE TABLE Laboratorios (
    id_laboratorio         CHAR(4)        NOT NULL,
    nombre_laboratorio     NVARCHAR(100)  NOT NULL,
    descripcion            NVARCHAR(255)   NULL,
    id_responsable         CHAR(4)        NOT NULL,
    estado_laboratorio     NVARCHAR(20)   NOT NULL DEFAULT 'Activo',
    aula_id                CHAR(6)        NOT NULL,
    created_at             DATETIME                DEFAULT GETDATE(),
    updated_at             DATETIME        NULL,
    deleted_at             DATETIME        NULL,

    -- RESTRICCIONES (PK, UQ, FK, CK)
    CONSTRAINT PK_Laboratorios 
        PRIMARY KEY (id_laboratorio),
    CONSTRAINT UQ_Laboratorios_aula_id 
        UNIQUE (aula_id),
    CONSTRAINT FK_Laboratorios_Usuarios 
        FOREIGN KEY (id_responsable) REFERENCES Usuarios(id_usuario) 
        ON UPDATE NO ACTION 
        ON DELETE NO ACTION,
    CONSTRAINT FK_Laboratorios_Aula 
        FOREIGN KEY (aula_id) REFERENCES Aula(aula_id) 
        ON UPDATE CASCADE 
        ON DELETE NO ACTION,
    CONSTRAINT CK_Laboratorios_estado 
        CHECK (estado_laboratorio IN ('Activo', 'Inactivo'))
);
GO
/* ============================================================
   7. TABLA: Modelos
   Marca está fusionada dentro de Modelos.
   Cardinalidad: Modelos 1 ---- N Equipos
   ============================================================ */
CREATE TABLE Modelos (
    id_modelo CHAR(6) NOT NULL,
    nombre_modelo NVARCHAR(100) NOT NULL,
    marca NVARCHAR(50) NOT NULL,
    
    -- Auditoría
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME NULL,
    deleted_at DATETIME NULL,

    CONSTRAINT PK_Modelos PRIMARY KEY (id_modelo)
);
GO
/* ============================================================
   8. TABLA: Equipos
   Cardinalidad:
   - Aula 1 ---- N Equipos.
   - Modelos 1 ---- N Equipos.
   ============================================================ */
CREATE TABLE Equipos (
    id_equipo CHAR(5) NOT NULL,
    aula_id CHAR(6) NOT NULL,
    numero_serie NVARCHAR(50) NOT NULL,
    id_modelo CHAR(6) NOT NULL,
    criticidad NVARCHAR(20) NOT NULL CONSTRAINT DF_Equipos_criticidad DEFAULT 'Media',
    fecha_adquisicion DATE NOT NULL,
    estado_equipo NVARCHAR(30) NOT NULL CONSTRAINT DF_Equipos_estado DEFAULT 'Activo',
    fecha_fuera_servicio DATE NULL,
    
    -- Auditoría
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME NULL,
    deleted_at DATETIME NULL,

    CONSTRAINT PK_Equipos PRIMARY KEY (id_equipo),
    CONSTRAINT UQ_Equipos_numero_serie UNIQUE (numero_serie),
    CONSTRAINT FK_Equipos_Aula FOREIGN KEY (aula_id)
        REFERENCES Aula(aula_id)
        ON UPDATE CASCADE
        ON DELETE NO ACTION,
    CONSTRAINT FK_Equipos_Modelos FOREIGN KEY (id_modelo)
        REFERENCES Modelos(id_modelo)
        ON UPDATE CASCADE
        ON DELETE NO ACTION,
    CONSTRAINT CK_Equipos_criticidad CHECK (criticidad IN ('Baja', 'Media', 'Alta')),
    CONSTRAINT CK_Equipos_estado CHECK (estado_equipo IN ('Activo', 'Inactivo', 'Fuera de servicio')),
    CONSTRAINT CK_Equipos_fecha_fuera_servicio CHECK (
        fecha_fuera_servicio IS NULL OR fecha_fuera_servicio >= fecha_adquisicion
    ),
    CONSTRAINT CK_Equipos_activo_sin_fecha_baja CHECK (
        estado_equipo <> 'Activo' OR fecha_fuera_servicio IS NULL
    )
);
GO

/* ============================================================
   9. TABLA: Ordenes_de_Trabajo
   Las fallas correctivas NO son una tabla separada.
   id_falla queda como atributo opcional dentro de la orden.

   Cardinalidad:
   - Equipos 1 ---- N Ordenes_de_Trabajo.
   - Tecnicos 1 ---- N Ordenes_de_Trabajo.
   - Usuarios 1 ---- N Ordenes_de_Trabajo como usuario reportante.
   ============================================================ */
CREATE TABLE Ordenes_de_Trabajo (
    id_orden CHAR(4) NOT NULL,
    id_equipo CHAR(5) NOT NULL,
    id_tecnico CHAR(4) NOT NULL,
    id_falla CHAR(4) NULL,
    tipo_mantenimiento NVARCHAR(20) NOT NULL,
    prioridad_orden NVARCHAR(20) NOT NULL CONSTRAINT DF_Ordenes_prioridad DEFAULT 'Media',
    fecha_creacion DATE NOT NULL,
    estado_orden NVARCHAR(30) NOT NULL CONSTRAINT DF_Ordenes_estado DEFAULT 'Programada',
    diagnostico NVARCHAR(255) NULL,
    actividades_realizadas NVARCHAR(255) NULL,
    resultado_final NVARCHAR(255) NULL,
    fecha_cierre DATE NULL,
    id_usuario_reporta CHAR(4) NOT NULL,
    
    -- Auditoría
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME NULL,
    deleted_at DATETIME NULL,

    CONSTRAINT PK_Ordenes_de_Trabajo PRIMARY KEY (id_orden),
    CONSTRAINT FK_Ordenes_Equipos FOREIGN KEY (id_equipo)
        REFERENCES Equipos(id_equipo)
        ON UPDATE CASCADE
        ON DELETE NO ACTION,
    CONSTRAINT FK_Ordenes_Tecnicos FOREIGN KEY (id_tecnico)
        REFERENCES Tecnicos(id_tecnico)
        ON UPDATE CASCADE
        ON DELETE NO ACTION,
    CONSTRAINT FK_Ordenes_Usuarios_Reporta FOREIGN KEY (id_usuario_reporta)
        REFERENCES Usuarios(id_usuario)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT CK_Ordenes_tipo_mantenimiento CHECK (tipo_mantenimiento IN ('Preventivo', 'Correctivo')),
    CONSTRAINT CK_Ordenes_prioridad CHECK (prioridad_orden IN ('Baja', 'Media', 'Alta')),
    CONSTRAINT CK_Ordenes_estado CHECK (estado_orden IN ('Programada', 'En proceso', 'Cerrada')),
    CONSTRAINT CK_Ordenes_fecha_cierre CHECK (
        fecha_cierre IS NULL OR fecha_cierre >= fecha_creacion
    ),
    CONSTRAINT CK_Ordenes_falla_segun_tipo CHECK (
        (tipo_mantenimiento = 'Correctivo' AND id_falla IS NOT NULL)
        OR
        (tipo_mantenimiento = 'Preventivo' AND id_falla IS NULL)
    ),
    CONSTRAINT CK_Ordenes_cierre_obligatorio CHECK (
        (estado_orden = 'Cerrada' AND fecha_cierre IS NOT NULL AND diagnostico IS NOT NULL AND resultado_final IS NOT NULL)
        OR
        (estado_orden <> 'Cerrada' AND fecha_cierre IS NULL)
    )
);
GO

/* ============================================================
   10. TABLA: Repuestos
   Cardinalidad: Repuestos N ---- N Ordenes_de_Trabajo
   Se resuelve con Detalle_Orden_Repuesto.
   ============================================================ */
CREATE TABLE Repuestos (
    id_repuesto CHAR(4) NOT NULL,
    nombre_repuesto NVARCHAR(100) NOT NULL,
    categoria NVARCHAR(50) NOT NULL,
    unidad_medida NVARCHAR(30) NOT NULL CONSTRAINT DF_Repuestos_unidad DEFAULT 'Unidad',
    cantidad_disponible INT NOT NULL CONSTRAINT DF_Repuestos_cantidad DEFAULT 0,
    stock_minimo INT NOT NULL CONSTRAINT DF_Repuestos_stock_minimo DEFAULT 0,
    costo_unitario DECIMAL(10,2) NOT NULL CONSTRAINT DF_Repuestos_costo DEFAULT 0.00,
    estado NVARCHAR(20) NOT NULL CONSTRAINT DF_Repuestos_estado DEFAULT 'Activo',
    
    -- Auditoría
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME NULL,
    deleted_at DATETIME NULL,

    CONSTRAINT PK_Repuestos PRIMARY KEY (id_repuesto),
    CONSTRAINT CK_Repuestos_cantidad_no_negativa CHECK (cantidad_disponible >= 0),
    CONSTRAINT CK_Repuestos_stock_minimo CHECK (stock_minimo >= 0),
    CONSTRAINT CK_Repuestos_costo CHECK (costo_unitario >= 0.00),
    CONSTRAINT CK_Repuestos_estado CHECK (estado IN ('Activo', 'Inactivo'))
);
GO  
/* ============================================================
   11. TABLA: Detalle_Orden_Repuesto
   Cardinalidad:
   - Ordenes_de_Trabajo 1 ---- N Detalle_Orden_Repuesto.
   - Repuestos 1 ---- N Detalle_Orden_Repuesto.
   - Ordenes_de_Trabajo N ---- N Repuestos mediante esta tabla.
   PK compuesta: id_orden + id_repuesto.
   ============================================================ */
CREATE TABLE Detalle_Orden_Repuesto (
    id_orden CHAR(4) NOT NULL,
    id_repuesto CHAR(4) NOT NULL,
    cantidad_usada INT NOT NULL,
    
    -- Auditoría
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME NULL,
    deleted_at DATETIME NULL,

    CONSTRAINT PK_Detalle_Orden_Repuesto PRIMARY KEY (id_orden, id_repuesto),
    CONSTRAINT FK_Detalle_Orden FOREIGN KEY (id_orden)
        REFERENCES Ordenes_de_Trabajo(id_orden)
        ON UPDATE CASCADE
        ON DELETE NO ACTION,
    CONSTRAINT FK_Detalle_Repuesto FOREIGN KEY (id_repuesto)
        REFERENCES Repuestos(id_repuesto)
        ON UPDATE CASCADE
        ON DELETE NO ACTION,
    CONSTRAINT CK_Detalle_cantidad_usada CHECK (cantidad_usada >= 1)
);
GO
/* ============================================================
   TRIGGER 1: Valida que el usuario asignado como técnico tenga rol Técnico.
   En los datos simulados, R002 corresponde al rol Técnico.
   ============================================================ */
ALTER TABLE Usuarios 
ADD CONSTRAINT UQ_Usuarios_Id_Rol UNIQUE (id_usuario, id_rol);
GO

-- Nueva estructura de la tabla Tecnicos
CREATE TABLE Tecnicos (
    id_tecnico CHAR(4) NOT NULL,
    id_usuario CHAR(4) NOT NULL,
    id_rol CHAR(4) NOT NULL CONSTRAINT DF_Tecnicos_rol DEFAULT 'R002', -- Forzamos el rol
    especialidad NVARCHAR(50) NOT NULL,
    disponibilidad NVARCHAR(20) NOT NULL CONSTRAINT DF_Tecnicos_disponibilidad DEFAULT 'Disponible',
    estado_tecnico NVARCHAR(20) NOT NULL CONSTRAINT DF_Tecnicos_estado DEFAULT 'Activo',

    CONSTRAINT PK_Tecnicos PRIMARY KEY (id_tecnico),
    CONSTRAINT UQ_Tecnicos_id_usuario UNIQUE (id_usuario),
    
    CONSTRAINT CK_Tecnicos_SoloRolTecnico CHECK (id_rol = 'R002'),
    
    CONSTRAINT FK_Tecnicos_Usuarios_Rol FOREIGN KEY (id_usuario, id_rol)
        REFERENCES Usuarios(id_usuario, id_rol)
        ON UPDATE CASCADE
        ON DELETE NO ACTION,
        
    CONSTRAINT CK_Tecnicos_disponibilidad CHECK (disponibilidad IN ('Disponible', 'Ocupado', 'No disponible')),
    CONSTRAINT CK_Tecnicos_estado CHECK (estado_tecnico IN ('Activo', 'Inactivo'))
);
GO

/* ============================================================
   TRIGGER 2: Valida que el piso del aula no supere los pisos del edificio.
   ============================================================ */
/* ============================================================
   TABLA: Edificio
   Cardinalidad: Edificio 1 ---- N Aula
   ============================================================ */
CREATE TABLE Edificio (
    id_edificio CHAR(5) NOT NULL,
    nombre_edificio NVARCHAR(50) NOT NULL,
    cantidad_pisos INT NOT NULL,

    CONSTRAINT PK_Edificio PRIMARY KEY (id_edificio),
    CONSTRAINT CK_Edificio_cantidad_pisos CHECK (cantidad_pisos > 0)
);
GO

/* ============================================================
   TABLA: Aula
   Cardinalidad: Aula N ---- 1 Edificio
   ============================================================ */
CREATE TABLE Aula (
    aula_id CHAR(6) NOT NULL,
    referencia NVARCHAR(100) NOT NULL,
    estado_aula NVARCHAR(20) NOT NULL CONSTRAINT DF_Aula_estado DEFAULT 'Activa',
    id_edificio CHAR(5) NOT NULL,
    piso INT NOT NULL,

    CONSTRAINT PK_Aula PRIMARY KEY (aula_id),
    CONSTRAINT FK_Aula_Edificio FOREIGN KEY (id_edificio)
        REFERENCES Edificio(id_edificio)
        ON UPDATE CASCADE
        ON DELETE NO ACTION,
    CONSTRAINT CK_Aula_estado CHECK (estado_aula IN ('Activa', 'Inactiva')),
    -- Control nativo simple: evita errores de dedo como números negativos
    CONSTRAINT CK_Aula_piso_positivo CHECK (piso >= 0) 
);
GO

/* ============================================================
   TRIGGER 3: Valida stock al registrar repuestos en una orden.
   Nota: solo valida que la cantidad usada no supere el stock disponible.
   No descuenta automáticamente para conservar los datos simulados originales.
   ============================================================ */
/* ============================================================
   TABLA: Repuestos
   ============================================================ */
CREATE TABLE Repuestos (
    id_repuesto CHAR(4) NOT NULL,
    nombre_repuesto NVARCHAR(100) NOT NULL,
    categoria NVARCHAR(50) NOT NULL,
    unidad_medida NVARCHAR(30) NOT NULL CONSTRAINT DF_Repuestos_unidad DEFAULT 'Unidad',
    cantidad_disponible INT NOT NULL CONSTRAINT DF_Repuestos_cantidad DEFAULT 0,
    stock_minimo INT NOT NULL CONSTRAINT DF_Repuestos_stock_minimo DEFAULT 0,
    costo_unitario DECIMAL(10,2) NOT NULL CONSTRAINT DF_Repuestos_costo DEFAULT 0.00,
    estado NVARCHAR(20) NOT NULL CONSTRAINT DF_Repuestos_estado DEFAULT 'Activo',

    CONSTRAINT PK_Repuestos PRIMARY KEY (id_repuesto),
    
    -- ¡ESTA ES LA CLAVE! Impide físicamente que el stock baje de cero
    CONSTRAINT CK_Repuestos_cantidad_no_negativa CHECK (cantidad_disponible >= 0),
    
    CONSTRAINT CK_Repuestos_stock_minimo CHECK (stock_minimo >= 0),
    CONSTRAINT CK_Repuestos_costo CHECK (costo_unitario >= 0.00),
    CONSTRAINT CK_Repuestos_estado CHECK (estado IN ('Activo', 'Inactivo'))
);
GO

/* ============================================================
  TABLA: Detalle_Orden_Repuesto
   ============================================================ */
CREATE TABLE Detalle_Orden_Repuesto (
    id_orden CHAR(4) NOT NULL,
    id_repuesto CHAR(4) NOT NULL,
    cantidad_usada INT NOT NULL,

    CONSTRAINT PK_Detalle_Orden_Repuesto PRIMARY KEY (id_orden, id_repuesto),
    CONSTRAINT FK_Detalle_Orden FOREIGN KEY (id_orden)
        REFERENCES Ordenes_de_Trabajo(id_orden)
        ON UPDATE CASCADE
        ON DELETE NO ACTION,
    CONSTRAINT FK_Detalle_Repuesto FOREIGN KEY (id_repuesto)
        REFERENCES Repuestos(id_repuesto)
        ON UPDATE CASCADE
        ON DELETE NO ACTION,
    CONSTRAINT CK_Detalle_cantidad_usada CHECK (cantidad_usada >= 1)
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