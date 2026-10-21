import 'package:flutter/material.dart';
import '../model/incidencia.dart';
import '../services/gestor_incidencias.dart';
import 'pantalla_detalle.dart';
import 'pantalla_nueva.dart';

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  final GestorIncidencias g = GestorIncidencias();
  final TextEditingController controlBusqueda = TextEditingController();
  bool cargando = true;
  String? error;
  String busqueda = '';
  String filtroEstado = 'Todos';
  String filtroPrioridad = 'Todas';

  @override
  void initState() {
    super.initState();
    cargar();
  }

  @override
  void dispose() {
    controlBusqueda.dispose();
    super.dispose();
  }

  void restablecerFiltros() {
    setState(() {
      busqueda = '';
      filtroEstado = 'Todos';
      filtroPrioridad = 'Todas';
      controlBusqueda.clear();
    });
  }

  Future<void> cargar() async {
    setState(() {
      cargando = true;
      error = null;
    });
    try {
      await g.iniciar();
    } catch (e) {
      error = 'No se pudieron cargar las incidencias: $e';
    }
    if (mounted) setState(() => cargando = false);
  }

  Color colorEstado(String estado) {
    if (estado == 'Resuelta') return const Color(0xFF147D64);
    if (estado == 'En proceso') return const Color(0xFFB56B13);
    return const Color(0xFFAC4052);
  }

  Color colorPrioridad(String prioridad) {
    if (prioridad == 'Alta') return const Color(0xFFAC4052);
    if (prioridad == 'Media') return const Color(0xFFB56B13);
    return const Color(0xFF174C83);
  }

  Widget resumen(String etiqueta, String valor, IconData icono) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icono, size: 19, color: const Color(0xFF174C83)),
              const SizedBox(height: 4),
              Text(valor, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text(etiqueta, textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> abrirDetalle(Incidencia item) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => PantallaDetalle(gestor: g, id: item.id)),
    );
    if (mounted) setState(() {});
  }

  Future<void> abrirFormulario() async {
    final guardado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PantallaNueva(gestor: g)),
    );
    if (guardado == true && mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incidencia registrada')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = g.filtrar(
      texto: busqueda,
      estado: filtroEstado,
      prioridad: filtroPrioridad,
    );
    final bool hayFiltrosActivos =
        busqueda.isNotEmpty || filtroEstado != 'Todos' || filtroPrioridad != 'Todas';

    return Scaffold(
      appBar: AppBar(
        title: const Text('NexaSoft | Incidencias'),
        actions: [
          IconButton(
            tooltip: 'Restablecer datos de demostración',
            onPressed: () async {
              final aceptar = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Restablecer demostración'),
                  content: const Text('Se descartarán los cambios locales y se cargarán las incidencias iniciales.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restablecer')),
                  ],
                ),
              );
              if (aceptar != true) return;
              try {
                await g.reiniciarDemo();
                if (mounted) setState(() {});
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al reiniciar: $e')));
                }
              }
            },
            icon: const Icon(Icons.restart_alt),
          ),
        ],
      ),
      floatingActionButton: cargando || error != null
          ? null
          : FloatingActionButton.extended(
              onPressed: abrirFormulario,
              label: const Text('Nueva incidencia'),
              icon: const Icon(Icons.add),
            ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: cargar, child: const Text('Reintentar')),
                  ]),
                ))
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 860),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
                          child: Row(children: [
                            resumen('Pendientes', '${g.contar('Pendiente')}', Icons.pending_actions),
                            resumen('En proceso', '${g.contar('En proceso')}', Icons.build_outlined),
                            resumen('Resueltas', '${g.contar('Resuelta')}', Icons.check_circle_outline),
                          ]),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 5),
                          child: TextField(
                            controller: controlBusqueda,
                            decoration: InputDecoration(
                              labelText: 'Buscar incidencias',
                              hintText: 'Ejemplo: WiFi, correo, pantalla',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: busqueda.isNotEmpty
                                  ? IconButton(
                                      tooltip: 'Limpiar búsqueda',
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        controlBusqueda.clear();
                                        setState(() => busqueda = '');
                                      },
                                    )
                                  : null,
                              border: const OutlineInputBorder(),
                            ),
                            onChanged: (texto) => setState(() => busqueda = texto),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: filtroEstado,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Filtro de estado',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'Todos', child: Text('Todos los estados')),
                                    DropdownMenuItem(value: 'Pendiente', child: Text('Pendiente')),
                                    DropdownMenuItem(value: 'En proceso', child: Text('En proceso')),
                                    DropdownMenuItem(value: 'Resuelta', child: Text('Resuelta')),
                                  ],
                                  onChanged: (v) => setState(() => filtroEstado = v ?? 'Todos'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: filtroPrioridad,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Filtro de prioridad',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'Todas', child: Text('Todas las prioridades')),
                                    DropdownMenuItem(value: 'Baja', child: Text('Baja')),
                                    DropdownMenuItem(value: 'Media', child: Text('Media')),
                                    DropdownMenuItem(value: 'Alta', child: Text('Alta')),
                                  ],
                                  onChanged: (v) => setState(() => filtroPrioridad = v ?? 'Todas'),
                                ),
                              ),
                              if (hayFiltrosActivos) ...[
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                  ),
                                  onPressed: restablecerFiltros,
                                  icon: const Icon(Icons.filter_alt_off, size: 18),
                                  label: const Text('Limpiar'),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${items.length} registros coincidentes',
                                  style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w500)),
                              if (hayFiltrosActivos)
                                TextButton(
                                  onPressed: restablecerFiltros,
                                  child: const Text('Restablecer todo'),
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: items.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.search_off, size: 54, color: Colors.black38),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'No se encontraron incidencias coincidentes.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                                        ),
                                        const SizedBox(height: 6),
                                        const Text(
                                          'Modifica los términos de búsqueda o restablece los filtros activos.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 13, color: Colors.black54),
                                        ),
                                        const SizedBox(height: 16),
                                        FilledButton.icon(
                                          onPressed: restablecerFiltros,
                                          icon: const Icon(Icons.refresh),
                                          label: const Text('Restablecer filtros'),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.only(left: 12, right: 12, bottom: 100),
                                  itemCount: items.length,
                                  itemBuilder: (context, i) {
                                    final item = items[i];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        title: Text(item.titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
                                        subtitle: Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('${item.id}  ·  ${item.cliente}'),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  Text(item.estado, style: TextStyle(
                                                    color: colorEstado(item.estado), fontWeight: FontWeight.bold,
                                                  )),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: colorPrioridad(item.prioridad).withOpacity(0.12),
                                                      borderRadius: BorderRadius.circular(4),
                                                      border: Border.all(color: colorPrioridad(item.prioridad).withOpacity(0.4)),
                                                    ),
                                                    child: Text(
                                                      'Prioridad: ${item.prioridad}',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                        color: colorPrioridad(item.prioridad),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        trailing: const Icon(Icons.chevron_right),
                                        onTap: () => abrirDetalle(item),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
