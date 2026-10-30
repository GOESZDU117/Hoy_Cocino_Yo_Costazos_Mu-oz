const API_URL = 'api.php';
let carrito = [];

async function cargarViandas(busqueda = '') {
  try {
    const res = await fetch(`${API_URL}?action=get_viandas&search=${encodeURIComponent(busqueda)}`);
    const resultado = await res.json();
    if (resultado.status === 'success') return resultado.data;
  } catch (error) {
    console.error(error);
  }
}

async function obtenerReportePedidos(fechaDesde, fechaHasta) {
  try {
    const res = await fetch(`${API_URL}?action=get_reporte_pedidos&fecha_desde=${fechaDesde}&fecha_hasta=${fechaHasta}`);
    const resultado = await res.json();
    if (resultado.status === 'success') return resultado;
  } catch (error) {
    console.error(error);
  }
}

async function guardarVianda(vianda) {
  try {
    const res = await fetch(`${API_URL}?action=save_vianda`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(vianda)
    });
    const resultado = await res.json();
    if (resultado.status === 'success') alert('¡Producto guardado correctamente!');
  } catch (error) {
    console.error(error);
  }
}

async function eliminarProducto(id) {
  try {
    await fetch(`${API_URL}?action=delete_vianda`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id: id })
    });
  } catch (error) {
    console.error(error);
  }
}

async function cambiarDisponibilidad(id, disponible) {
  try {
    await fetch(`${API_URL}?action=toggle_availability`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id: id, available: disponible })
    });
  } catch (error) {
    console.error(error);
  }
}

function exportarInforme() {
  window.print();
}

function agregarAlCarrito(producto) {
  if (producto.stock <= 0) {
    alert('Sin stock disponible.');
    return;
  }

  const enCarrito = carrito.find(item => item.id === producto.id);
  const cantidadActual = enCarrito ? enCarrito.cant : 0;

  if (cantidadActual + 1 > producto.stock) {
    alert(`El stock disponible es de ${producto.stock} unidades.`);
    return;
  }

  if (enCarrito) {
    enCarrito.cant++;
  } else {
    carrito.push({
      id: producto.id,
      name: producto.name,
      badge: producto.badge,
      price: producto.price,
      cant: 1
    });
  }
  actualizarCajaCarrito();
}

function agregarComboDirecto(plato, postre, bebida) {
  if (plato.stock <= 0 || postre.stock <= 0 || bebida.stock <= 0) {
    alert('Uno de los elementos no tiene stock suficiente.');
    return;
  }

  agregarAlCarrito(plato);
  agregarAlCarrito(postre);
  agregarAlCarrito(bebida);
}

function actualizarCajaCarrito() {
  const container = document.getElementById('cart-items-container');
  const cartBox = document.getElementById('cart-box');
  if (!container || !cartBox) return;

  if (carrito.length === 0) {
    cartBox.style.display = 'none';
    return;
  }

  cartBox.style.display = 'block';

  let tienePlato = false;
  let tienePostre = false;
  let tieneBebida = false;
  let subtotal = 0;
  let html = '';

  carrito.forEach((item, index) => {
    if (item.badge === 'Plato Principal') tienePlato = true;
    if (item.badge === 'Postre') tienePostre = true;
    if (item.badge === 'Bebida') tieneBebida = true;

    const itemSubtotal = item.price * item.cant;
    subtotal += itemSubtotal;

    html += `
      <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:8px; font-size:0.85rem;">
        <div>
          <strong>${item.name}</strong> (${item.cant}x)
          <br><small>$${item.price.toLocaleString('es-AR')} c/u</small>
        </div>
        <div>
          <strong>$${itemSubtotal.toLocaleString('es-AR')}</strong>
          <button onclick="eliminarDelCarrito(${index})" style="background:none; border:none; color:red; cursor:pointer; margin-left:5px;">&times;</button>
        </div>
      </div>
    `;
  });

  let descuento = (tienePlato && tienePostre && tieneBebida) ? (subtotal * 0.10) : 0;
  const totalFinal = subtotal - descuento;

  html += `<hr style="margin:10px 0; border:none; border-top:1px dashed var(--jojo-border);">`;

  if (tienePlato && tienePostre && tieneBebida) {
    html += `
      <div style="color: var(--jojo-pink-dark); font-weight:bold; font-size:0.85rem; margin-bottom:5px;">
        <i class="fa-solid fa-tags"></i> ¡Combo activado! 10% OFF (-$${descuento.toLocaleString('es-AR')})
      </div>
    `;
  }

  html += `
    <div class="form-group" style="margin-top:10px;">
      <label>Dirección de Entrega:</label>
      <input type="text" id="order-address" required placeholder="Ej. Alsina 123, Depto 2B" style="padding:0.5rem; font-size:0.85rem;">
    </div>

    <div class="form-group">
      <label>Método de Pago:</label>
      <select id="order-pay-method" style="padding:0.5rem; font-size:0.85rem;">
        <option value="Efectivo en Entrega">Efectivo al Entregar</option>
        <option value="Mercado Pago (Online)">Mercado Pago (Online)</option>
      </select>
    </div>

    <div style="display:flex; justify-content:space-between; font-size:1.1rem; font-weight:bold; margin-top:5px;">
      <span>Total a Pagar:</span>
      <span style="color:var(--jojo-pink-dark);">$${totalFinal.toLocaleString('es-AR')}</span>
    </div>
    <button class="btn-order" onclick="confirmarPedidoBD()" style="margin-top:10px;">Confirmar y Comprar</button>
  `;

  container.innerHTML = html;
}

function eliminarDelCarrito(index) {
  carrito.splice(index, 1);
  actualizarCajaCarrito();
}

async function confirmarPedidoBD() {
  if (carrito.length === 0) return;

  const direccion = document.getElementById('order-address').value;
  const formaPago = document.getElementById('order-pay-method').value;

  if (!direccion.trim()) {
    alert('Por favor ingrese la dirección de entrega para realizar el envío.');
    return;
  }

  const userRaw = localStorage.getItem('currentUser');
  let idCliente = 1;

  if (userRaw) {
    const u = JSON.parse(userRaw);
    if (u.id_cliente) idCliente = u.id_cliente;
  }

  let subtotal = 0;
  let tienePlato = false, tienePostre = false, tieneBebida = false;

  const itemsPayload = carrito.map(item => {
    if (item.badge === 'Plato Principal') tienePlato = true;
    if (item.badge === 'Postre') tienePostre = true;
    if (item.badge === 'Bebida') tieneBebida = true;

    const itemSubtotal = item.price * item.cant;
    subtotal += itemSubtotal;
    return { id: item.id, cant: item.cant, subtotal: itemSubtotal };
  });

  let descuento = (tienePlato && tienePostre && tieneBebida) ? (subtotal * 0.10) : 0;
  const totalFinal = subtotal - descuento;

  if (formaPago.includes('Mercado Pago')) {
    alert('Redirigiendo a la pasarela oficial de Mercado Pago (https://api.mercadopago.com)... Pago aprobado.');
  }

  const payload = {
    id_cliente: idCliente,
    tipo_menu: (tienePlato && tienePostre && tieneBebida) ? 'Combo Completo (10% OFF)' : 'Pedido Individual',
    direccion: direccion,
    forma_pago: formaPago,
    monto_total: totalFinal,
    items: itemsPayload
  };

  const res = await fetch(`${API_URL}?action=crear_pedido`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload)
  });

  const data = await res.json();
  if (data.status === 'success') {
    alert('¡Pedido registrado con éxito! El local ya tiene la dirección registrada.');
    carrito = [];
    actualizarCajaCarrito();
    if (typeof renderCliente === 'function') renderCliente();
    if (typeof checkActiveUser === 'function') checkActiveUser();
  }
}

async function cambiarEstadoPedidoAdmin(id_pedido, nuevoEstado) {
  const res = await fetch(`${API_URL}?action=update_estado_pedido`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ id_pedido: id_pedido, estado: nuevoEstado })
  });

  const data = await res.json();
  if (data.status === 'success') {
    if (typeof consultarPedidosPeriodo === 'function') consultarPedidosPeriodo();
  }
}

async function renderFullMonthCalendar() {
  const container = document.getElementById('calendar-grid-container');
  if (!container) return;
  
  container.innerHTML = '<p style="grid-column: 1 / -1; padding:1rem; text-align:center;">Cargando calendario...</p>';

  const now = new Date();
  const year = now.getFullYear();
  const month = now.getMonth();
  
  const firstDay = new Date(year, month, 1).getDay();
  const daysInMonth = new Date(year, month + 1, 0).getDate();

  const daysOfWeek = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
  let html = daysOfWeek.map(d => `<div class="calendar-day-head">${d}</div>`).join('');

  for (let i = 0; i < firstDay; i++) {
    html += `<div class="calendar-day-cell" style="opacity:0.3;"></div>`;
  }

  for (let day = 1; day <= daysInMonth; day++) {
    html += `
      <div class="calendar-day-cell" id="cell-day-${day}">
        <span class="num">${day}</span>
        <div class="empty-msg">Cargando...</div>
      </div>
    `;
  }

  container.innerHTML = html;

  for (let day = 1; day <= daysInMonth; day++) {
    const fechaStr = `${year}-${String(month + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
    
    fetch(`api.php?action=get_calendario&fecha=${fechaStr}`)
      .then(res => res.json())
      .then(data => {
        const cell = document.getElementById(`cell-day-${day}`);
        if (!cell) return;

        if (data.data && data.data.length > 0) {
          cell.innerHTML = `
            <span class="num">${day}</span>
            <div class="menu-title">${data.data[0].nombre}</div>
          `;
        } else {
          cell.innerHTML = `
            <span class="num">${day}</span>
            <div class="empty-msg">Aún no está decidido el menú de este día, ¡pero pronto estará disponible!</div>
          `;
        }
      })
      .catch(() => {
        const cell = document.getElementById(`cell-day-${day}`);
        if (cell) {
          cell.innerHTML = `
            <span class="num">${day}</span>
            <div class="empty-msg">Aún no está decidido el menú de este día, ¡pero pronto estará disponible!</div>
          `;
        }
      });
  }
}