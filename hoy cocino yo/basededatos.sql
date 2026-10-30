CREATE DATABASE IF NOT EXISTS munoz_costazos_db;
USE munoz_costazos_db;

DROP TABLE IF EXISTS GASTO;
DROP TABLE IF EXISTS DETALLE_PEDIDO;
DROP TABLE IF EXISTS CLIENTE_PROMOCION;
DROP TABLE IF EXISTS PEDIDO;
DROP TABLE IF EXISTS PROMOCION;
DROP TABLE IF EXISTS CALENDARIO_MENU;
DROP TABLE IF EXISTS PRODUCTO;
DROP TABLE IF EXISTS CLIENTE;

CREATE TABLE CLIENTE (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    dni VARCHAR(20) NOT NULL UNIQUE,
    email VARCHAR(120) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    rol VARCHAR(20) NOT NULL DEFAULT 'cliente',
    localidad VARCHAR(100),
    telefono VARCHAR(30),
    es_socio BOOLEAN DEFAULT FALSE
);

CREATE TABLE PRODUCTO (
    id_producto INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT NULL,
    categoria VARCHAR(50) NOT NULL,
    estacion VARCHAR(30),
    precio_unitario DECIMAL(10, 2) NOT NULL,
    imagen_url VARCHAR(255) DEFAULT 'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=800&q=80',
    stock INT NOT NULL DEFAULT 0,
    disponible_hoy BOOLEAN DEFAULT TRUE
);

CREATE TABLE CALENDARIO_MENU (
    id_calendario INT AUTO_INCREMENT PRIMARY KEY,
    fecha DATE NOT NULL,
    id_producto INT NOT NULL,
    notas VARCHAR(255),
    FOREIGN KEY (id_producto) REFERENCES PRODUCTO(id_producto) ON DELETE CASCADE,
    UNIQUE(fecha, id_producto)
);

CREATE TABLE PROMOCION (
    id_promocion INT AUTO_INCREMENT PRIMARY KEY,
    descripcion VARCHAR(255) NOT NULL,
    porcentaje_descuento DECIMAL(5, 2) NOT NULL
);

CREATE TABLE CLIENTE_PROMOCION (
    id_cliente_promocion INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT NOT NULL,
    id_promocion INT NOT NULL,
    fecha_asignacion DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_cliente) REFERENCES CLIENTE(id_cliente) ON DELETE CASCADE,
    FOREIGN KEY (id_promocion) REFERENCES PROMOCION(id_promocion) ON DELETE CASCADE
);

CREATE TABLE PEDIDO (
    id_pedido INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT NOT NULL,
    fecha_hora DATETIME DEFAULT CURRENT_TIMESTAMP,
    tipo_menu VARCHAR(50) NOT NULL,
    referencia_ubicacion TEXT,
    telefono_contacto VARCHAR(30) NOT NULL,
    forma_pago VARCHAR(50) NOT NULL,
    estado VARCHAR(30) DEFAULT 'Pendiente',
    monto_total DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (id_cliente) REFERENCES CLIENTE(id_cliente) ON DELETE CASCADE
);

CREATE TABLE DETALLE_PEDIDO (
    id_detalle INT AUTO_INCREMENT PRIMARY KEY,
    id_pedido INT NOT NULL,
    id_producto INT NOT NULL,
    id_promocion INT NULL,
    cantidad INT NOT NULL,
    subtotal DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (id_pedido) REFERENCES PEDIDO(id_pedido) ON DELETE CASCADE,
    FOREIGN KEY (id_producto) REFERENCES PRODUCTO(id_producto) ON DELETE RESTRICT,
    FOREIGN KEY (id_promocion) REFERENCES PROMOCION(id_promocion) ON DELETE SET NULL
);

CREATE TABLE GASTO (
    id_gasto INT AUTO_INCREMENT PRIMARY KEY,
    id_producto INT NULL,
    id_pedido INT NULL,
    fecha DATE NOT NULL,
    concepto VARCHAR(150),
    tipo_gasto VARCHAR(50) NOT NULL,
    monto DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (id_producto) REFERENCES PRODUCTO(id_producto) ON DELETE SET NULL,
    FOREIGN KEY (id_pedido) REFERENCES PEDIDO(id_pedido) ON DELETE SET NULL
);

INSERT INTO CLIENTE (nombre, apellido, dni, email, password, rol, localidad, telefono, es_socio) VALUES
('Administrador', 'General', '00000000', 'admin@derechupete.com', 'admin123', 'admin', 'Bahía Blanca', '2914753494', TRUE),
('Josuke', 'Higashikata', '35123456', 'josuke@morioh.com', '123456', 'cliente', 'Bahía Blanca', '2914567890', TRUE),
('Yasuho', 'Hirose', '28987654', 'yasuho@morioh.com', '123456', 'cliente', 'Olavarría', '2284123456', FALSE);

INSERT INTO PRODUCTO (nombre, descripcion, categoria, estacion, precio_unitario, imagen_url, stock, disponible_hoy) VALUES
('Milanesa con Puré', 'Tierna milanesa de carne vacuna acompañada de cremoso puré de papas casero.', 'Plato Principal', 'Anual', 5000.00, 'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=800&q=80', 20, TRUE),
('Pollo con Ensalada', 'Pechuga de pollo a la plancha condimentada con finas hierbas y ensalada fresca.', 'Plato Principal', 'Anual', 4800.00, 'https://images.unsplash.com/photo-1532550907401-a500c9a57435?auto=format&fit=crop&w=800&q=80', 17, TRUE),
('Ensalada de Frutas', 'Mezcla natural de frutas de estación troceadas.', 'Postre', 'Anual', 1500.00, 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=800&q=80', 15, TRUE),
('Gelatina', 'Refrescante gelatina sabor frutilla.', 'Postre', 'Anual', 1000.00, 'https://images.unsplash.com/photo-1551024709-8f23befc6f87?auto=format&fit=crop&w=800&q=80', 12, TRUE),
('Gaseosa 500ml', 'Bebida refrescante individual.', 'Bebida', 'Anual', 1200.00, 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?auto=format&fit=crop&w=800&q=80', 30, TRUE);