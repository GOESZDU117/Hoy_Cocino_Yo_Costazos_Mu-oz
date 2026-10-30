<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");

require_once "conexion.php";

$method = $_SERVER['REQUEST_METHOD'];
$action = isset($_GET['action']) ? $_GET['action'] : '';

if ($method === 'GET') {

    if ($action === 'get_viandas') {
        $search = isset($_GET['search']) ? $conn->real_escape_string($_GET['search']) : '';
        $sql = "SELECT id_producto AS id, nombre AS name, descripcion AS description, categoria AS badge, precio_unitario AS price, imagen_url AS img, stock, disponible_hoy AS available 
                FROM PRODUCTO 
                WHERE nombre LIKE '%$search%' OR categoria LIKE '%$search%'
                ORDER BY id_producto DESC";
        
        $result = $conn->query($sql);
        $viandas = [];
        while ($row = $result->fetch_assoc()) {
            $row['price'] = (float)$row['price'];
            $row['stock'] = (int)$row['stock'];
            $row['available'] = (bool)$row['available'];
            $viandas[] = $row;
        }
        echo json_encode(["status" => "success", "data" => $viandas]);
        exit;
    }

    if ($action === 'get_calendario') {
        $fecha = isset($_GET['fecha']) ? $conn->real_escape_string($_GET['fecha']) : date('Y-m-d');
        $sql = "SELECT cm.id_calendario, cm.fecha, cm.notas, p.id_producto, p.nombre, p.precio_unitario, p.imagen_url
                FROM CALENDARIO_MENU cm
                JOIN PRODUCTO p ON cm.id_producto = p.id_producto
                WHERE cm.fecha = '$fecha'
                ORDER BY cm.id_calendario DESC";

        $result = $conn->query($sql);
        $menu_fecha = [];
        while ($row = $result->fetch_assoc()) {
            $menu_fecha[] = $row;
        }
        echo json_encode(["status" => "success", "fecha" => $fecha, "data" => $menu_fecha]);
        exit;
    }

    if ($action === 'get_mis_pedidos') {
        $id_cliente = isset($_GET['id_cliente']) ? (int)$_GET['id_cliente'] : 0;
        $sql = "SELECT id_pedido, fecha_hora, tipo_menu, monto_total, forma_pago, referencia_ubicacion, estado 
                FROM PEDIDO 
                WHERE id_cliente = $id_cliente 
                ORDER BY fecha_hora DESC";

        $result = $conn->query($sql);
        $pedidos = [];
        while ($row = $result->fetch_assoc()) {
            $row['monto_total'] = (float)$row['monto_total'];
            $pedidos[] = $row;
        }
        echo json_encode(["status" => "success", "data" => $pedidos]);
        exit;
    }

    if ($action === 'get_reporte_pedidos') {
        $desde = isset($_GET['fecha_desde']) ? $conn->real_escape_string($_GET['fecha_desde']) : date('Y-m-01');
        $hasta = isset($_GET['fecha_hasta']) ? $conn->real_escape_string($_GET['fecha_hasta']) : date('Y-m-d');
        $hasta_full = $hasta . " 23:59:59";

        $sql = "SELECT p.id_pedido, p.fecha_hora, p.tipo_menu, p.monto_total, p.forma_pago, p.estado, p.referencia_ubicacion AS direccion,
                       c.nombre AS cliente_nombre, c.apellido AS cliente_apellido, c.telefono, c.email
                FROM PEDIDO p
                JOIN CLIENTE c ON p.id_cliente = c.id_cliente
                WHERE p.fecha_hora BETWEEN '$desde 00:00:00' AND '$hasta_full'
                ORDER BY p.fecha_hora DESC";

        $result = $conn->query($sql);
        $pedidos = [];
        $total_recaudado = 0;
        $total_menus = 0;

        while ($row = $result->fetch_assoc()) {
            $row['monto_total'] = (float)$row['monto_total'];
            $total_recaudado += $row['monto_total'];
            $total_menus++;
            $pedidos[] = $row;
        }

        echo json_encode([
            "status" => "success",
            "periodo" => ["desde" => $desde, "hasta" => $hasta],
            "resumen" => ["total_pedidos" => $total_menus, "total_recaudado" => $total_recaudado],
            "data" => $pedidos
        ]);
        exit;
    }
}

if ($method === 'POST') {
    $input = json_decode(file_get_contents("php://input"), true);

    if ($action === 'login') {
        $email = $conn->real_escape_string($input['email']);
        $password = $input['password'];

        $sql = "SELECT id_cliente, nombre, apellido, dni, email, password, rol, es_socio FROM CLIENTE WHERE email = '$email'";
        $result = $conn->query($sql);

        if ($result->num_rows > 0) {
            $user = $result->fetch_assoc();
            if ($password === $user['password']) {
                unset($user['password']);
                $user['es_socio'] = (bool)$user['es_socio'];
                echo json_encode(["status" => "success", "user" => $user]);
            } else {
                echo json_encode(["status" => "error", "message" => "Contraseña incorrecta."]);
            }
        } else {
            echo json_encode(["status" => "error", "message" => "Correo no registrado."]);
        }
        exit;
    }

    if ($action === 'register') {
        $nombre = $conn->real_escape_string($input['nombre']);
        $apellido = $conn->real_escape_string($input['apellido']);
        $dni = $conn->real_escape_string($input['dni']);
        $email = $conn->real_escape_string($input['email']);
        $password = $conn->real_escape_string($input['password']);
        $localidad = $conn->real_escape_string($input['localidad']);
        $telefono = $conn->real_escape_string($input['telefono']);

        $sql = "INSERT INTO CLIENTE (nombre, apellido, dni, email, password, rol, localidad, telefono, es_socio) 
                VALUES ('$nombre', '$apellido', '$dni', '$email', '$password', 'cliente', '$localidad', '$telefono', TRUE)";

        if ($conn->query($sql)) {
            echo json_encode([
                "status" => "success", 
                "user" => [
                    "id_cliente" => $conn->insert_id,
                    "nombre" => $nombre,
                    "apellido" => $apellido,
                    "email" => $email,
                    "rol" => "cliente"
                ]
            ]);
        } else {
            echo json_encode(["status" => "error", "message" => "Error: DNI o Email ya registrados."]);
        }
        exit;
    }

    if ($action === 'crear_pedido') {
        $id_cliente = isset($input['id_cliente']) ? (int)$input['id_cliente'] : 1;
        $tipo_menu = $conn->real_escape_string($input['tipo_menu']);
        $direccion = $conn->real_escape_string($input['direccion']);
        $forma_pago = $conn->real_escape_string($input['forma_pago']);
        $monto_total = (float)$input['monto_total'];
        $items = $input['items'];

        $sql_pedido = "INSERT INTO PEDIDO (id_cliente, tipo_menu, referencia_ubicacion, telefono_contacto, forma_pago, estado, monto_total) 
                       VALUES ($id_cliente, '$tipo_menu', '$direccion', '2914753494', '$forma_pago', 'Pendiente', $monto_total)";
        
        if ($conn->query($sql_pedido)) {
            $id_pedido = $conn->insert_id;

            foreach ($items as $item) {
                $id_p = (int)$item['id'];
                $cant = (int)$item['cant'];
                $subt = (float)$item['subtotal'];

                $conn->query("INSERT INTO DETALLE_PEDIDO (id_pedido, id_producto, cantidad, subtotal) VALUES ($id_pedido, $id_p, $cant, $subt)");
                $conn->query("UPDATE PRODUCTO SET stock = GREATEST(0, stock - $cant) WHERE id_producto = $id_p");
            }

            echo json_encode(["status" => "success", "id_pedido" => $id_pedido]);
        } else {
            echo json_encode(["status" => "error", "message" => $conn->error]);
        }
        exit;
    }

    if ($action === 'update_estado_pedido') {
        $id_pedido = (int)$input['id_pedido'];
        $nuevo_estado = $conn->real_escape_string($input['estado']);

        $sql = "UPDATE PEDIDO SET estado = '$nuevo_estado' WHERE id_pedido = $id_pedido";
        if ($conn->query($sql)) {
            echo json_encode(["status" => "success"]);
        } else {
            echo json_encode(["status" => "error", "message" => $conn->error]);
        }
        exit;
    }

    if ($action === 'delete_cuenta') {
        $id_cliente = (int)$input['id_cliente'];
        $sql = "DELETE FROM CLIENTE WHERE id_cliente = $id_cliente";
        if ($conn->query($sql)) {
            echo json_encode(["status" => "success"]);
        } else {
            echo json_encode(["status" => "error", "message" => $conn->error]);
        }
        exit;
    }

    if ($action === 'save_calendario') {
        $fecha = $conn->real_escape_string($input['fecha']);
        $id_producto = (int)$input['id_producto'];
        $notas = $conn->real_escape_string($input['notas']);

        $sql = "INSERT INTO CALENDARIO_MENU (fecha, id_producto, notas) VALUES ('$fecha', $id_producto, '$notas')
                ON DUPLICATE KEY UPDATE notas='$notas'";

        if ($conn->query($sql)) {
            echo json_encode(["status" => "success", "message" => "Asignado al calendario"]);
        } else {
            echo json_encode(["status" => "error", "message" => $conn->error]);
        }
        exit;
    }

    if ($action === 'save_vianda') {
        $id = isset($input['id']) ? (int)$input['id'] : 0;
        $nombre = $conn->real_escape_string($input['name']);
        $descripcion = $conn->real_escape_string($input['description']);
        $categoria = $conn->real_escape_string($input['badge']);
        $precio = (float)$input['price'];
        $stock = (int)$input['stock'];
        $imagen = $conn->real_escape_string($input['img']);
        $disponible = $input['available'] ? 1 : 0;

        if ($id > 0) {
            $sql = "UPDATE PRODUCTO SET nombre='$nombre', descripcion='$descripcion', categoria='$categoria', precio_unitario=$precio, stock=$stock, imagen_url='$imagen', disponible_hoy=$disponible WHERE id_producto=$id";
        } else {
            $sql = "INSERT INTO PRODUCTO (nombre, descripcion, categoria, estacion, precio_unitario, stock, imagen_url, disponible_hoy) 
                    VALUES ('$nombre', '$descripcion', '$categoria', 'Anual', $precio, $stock, '$imagen', $disponible)";
        }

        if ($conn->query($sql)) {
            echo json_encode(["status" => "success", "message" => "Guardado correctamente"]);
        } else {
            echo json_encode(["status" => "error", "message" => $conn->error]);
        }
        exit;
    }

    if ($action === 'delete_vianda') {
        $id = (int)$input['id'];
        $sql = "DELETE FROM PRODUCTO WHERE id_producto = $id";
        if ($conn->query($sql)) {
            echo json_encode(["status" => "success"]);
        } else {
            echo json_encode(["status" => "error", "message" => $conn->error]);
        }
        exit;
    }

    if ($action === 'toggle_availability') {
        $id = (int)$input['id'];
        $status = $input['available'] ? 1 : 0;

        $sql = "UPDATE PRODUCTO SET disponible_hoy = $status WHERE id_producto = $id";
        if ($conn->query($sql)) {
            echo json_encode(["status" => "success"]);
        } else {
            echo json_encode(["status" => "error", "message" => $conn->error]);
        }
        exit;
    }
}

$conn->close();
?>