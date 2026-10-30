CREATE DATABASE IF NOT EXISTS munoz_costazos_db;
USE munoz_costazos_db;

DROP TABLE IF EXISTS GASTO;
DROP TABLE IF EXISTS DETALLE_PEDIDO;
DROP TABLE IF EXISTS CLIENTE_PROMOCION;
DROP TABLE IF EXISTS PEDIDO;
DROP TABLE IF EXISTS PROMOCION;
DROP TABLE IF EXISTS PRODUCTO;
DROP TABLE IF EXISTS CLIENTE;

CREATE TABLE CLIENTE (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    dni VARCHAR(20) NOT NULL UNIQUE,
    localidad VARCHAR(100),
    telefono VARCHAR(30),
    es_socio BOOLEAN DEFAULT FALSE
);

CREATE TABLE PRODUCTO (
    id_producto INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    categoria VARCHAR(50) NOT NULL,
    estacion VARCHAR(30),
    precio_unitario DECIMAL(10, 2) NOT NULL,
    imagen_url VARCHAR(255) DEFAULT 'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=800&q=80',
    disponible_hoy BOOLEAN DEFAULT TRUE
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

INSERT INTO CLIENTE (nombre, apellido, dni, localidad, telefono, es_socio) VALUES
('Carlos', 'Muñoz', '35123456', 'Bahía Blanca', '2914567890', TRUE),
('Roberto', 'Costazo', '28987654', 'Olavarría', '2284123456', FALSE);

INSERT INTO PRODUCTO (nombre, categoria, estacion, precio_unitario, imagen_url, disponible_hoy) VALUES
('Milanesa Napoli con Papas', 'Plato Principal', 'Anual', 5000.00, 'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=800&q=80', TRUE),
('Pasta Casera con Tuco', 'Plato Principal', 'Anual', 4500.00, 'https://images.unsplash.com/photo-1621996346565-e3d5d6281313?auto=format&fit=crop&w=800&q=80', TRUE),
('Guiso de Lentejas', 'Plato Principal', 'Invierno', 4800.00, 'https://images.unsplash.com/photo-1547592180-85f173990554?auto=format&fit=crop&w=800&q=80', FALSE);

CREATE OR REPLACE VIEW vista_clientes_descuento_20 AS
SELECT 
    c.id_cliente,
    c.nombre,
    c.apellido,
    c.dni,
    COUNT(DISTINCT DATE(p.fecha_hora)) AS dias_con_pedidos,
    IF(COUNT(DISTINCT DATE(p.fecha_hora)) >= 4, 20.00, 0.00) AS porcentaje_descuento_aplicable
FROM CLIENTE c
JOIN PEDIDO p ON c.id_cliente = p.id_cliente
WHERE c.es_socio = TRUE AND p.estado != 'Cancelado'
GROUP BY c.id_cliente, c.nombre, c.apellido, c.dni
HAVING dias_con_pedidos >= 4;