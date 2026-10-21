import 'package:flutter_test/flutter_test.dart';
import 'package:nexasoft_incidencias/model/incidencia.dart';
import 'package:nexasoft_incidencias/services/gestor_incidencias.dart';

void main() {
  group('Pruebas unitarias de corrección - Día 2', () {
    late GestorIncidencias gestor;

    setUp(() {
      gestor = GestorIncidencias();
      gestor.incidencias = [
        Incidencia(
          id: 'INC-101',
          titulo: 'Impresora del almacén no responde',
          descripcion: 'Documentos permanecen en cola.',
          cliente: 'Almacenes del Centro',
          categoria: 'Hardware',
          estado: 'Pendiente',
          fecha: '2026-09-28',
        ),
        Incidencia(
          id: 'INC-102',
          titulo: 'WiFi intermitente en recepción',
          descripcion: 'La red inalámbrica se desconecta de forma aleatoria.',
          cliente: 'Clínica del Prado',
          categoria: 'Redes',
          estado: 'En proceso',
          fecha: '2026-09-29',
        ),
        Incidencia(
          id: 'INC-106',
          titulo: 'Configuración de VPN',
          descripcion: 'El personal remoto no puede establecer túnel de conexión seguro.',
          cliente: 'Servicios del Norte',
          categoria: 'Redes',
          estado: 'En proceso',
          fecha: '2026-10-03',
        ),
      ];
    });

    test('BUG-002: Búsqueda insensible a mayúsculas/minúsculas', () {
      final resMin = gestor.buscar('wifi');
      expect(resMin.length, 1);
      expect(resMin.first.id, 'INC-102');

      final resMay = gestor.buscar('WIFI');
      expect(resMay.length, 1);
      expect(resMay.first.id, 'INC-102');
    });

    test('BUG-002: Búsqueda con espacios perimetrales (trim)', () {
      final res = gestor.buscar('   wifi   ');
      expect(res.length, 1);
      expect(res.first.id, 'INC-102');
    });

    test('BUG-002: Búsqueda dentro de la descripción', () {
      final res = gestor.buscar('túnel');
      expect(res.length, 1);
      expect(res.first.id, 'INC-106');
    });

    test('BUG-003: Conteo dinámico y consistente por estado', () {
      expect(gestor.contar('Pendiente'), 1);
      expect(gestor.contar('En proceso'), 2);
      expect(gestor.contar('Resuelta'), 0);

      // Simular cambio de estado en memoria
      gestor.incidencias[0].estado = 'Resuelta';

      // Verificar que el tablero refleja la actualización inmediatamente
      expect(gestor.contar('Pendiente'), 0);
      expect(gestor.contar('Resuelta'), 1);
    });
  });

  group('Pruebas unitarias de FEAT-001 - Día 3 (Prioridades)', () {
    test('Registros antiguos sin prioridad asignada usan Media por defecto', () {
      final inc = Incidencia.desdeJson({
        'id': 'INC-ANTIGUA',
        'titulo': 'Fallo heredado',
        'descripcion': 'Sin campo prioridad',
        'cliente': 'Cliente Histórico',
        'categoria': 'Software',
        'estado': 'Pendiente',
        'fecha': '2026-08-01',
      });
      expect(inc.prioridad, 'Media');
      expect(inc.toJson()['prioridad'], 'Media');
    });

    test('Valores no aprobados se normalizan automáticamente a Media', () {
      final inc = Incidencia(
        id: 'INC-INV',
        titulo: 'Prioridad inválida',
        descripcion: 'Probando valor fuera de catálogo',
        cliente: 'Cliente Test',
        categoria: 'Hardware',
        estado: 'Pendiente',
        fecha: '2026-10-19',
        prioridad: 'Urgente', // No está en [Baja, Media, Alta]
      );
      expect(inc.prioridad, 'Media');
    });

    test('Asignación explícita de prioridad Alta y Baja es respetada', () {
      final incAlta = Incidencia(
        id: 'INC-ALTA',
        titulo: 'Fallo crítico',
        descripcion: 'Servidor caído',
        cliente: 'Empresa Principal',
        categoria: 'Redes',
        estado: 'Pendiente',
        fecha: '2026-10-19',
        prioridad: 'Alta',
      );
      expect(incAlta.prioridad, 'Alta');
      expect(incAlta.toJson()['prioridad'], 'Alta');

      final incBaja = Incidencia(
        id: 'INC-BAJA',
        titulo: 'Limpieza de mouse',
        descripcion: 'Mantenimiento preventivo',
        cliente: 'Empresa Secundaria',
        categoria: 'Hardware',
        estado: 'Resuelta',
        fecha: '2026-10-19',
        prioridad: 'Baja',
      );
      expect(incBaja.prioridad, 'Baja');
      expect(incBaja.toJson()['prioridad'], 'Baja');
    });
  });

  group('Pruebas unitarias de FEAT-002 - Día 4 (Filtros combinables)', () {
    late GestorIncidencias gestor;

    setUp(() {
      gestor = GestorIncidencias();
      gestor.incidencias = [
        Incidencia(
          id: 'INC-201',
          titulo: 'Servidor web no responde',
          descripcion: 'Error 502 al cargar la pagina principal.',
          cliente: 'Financiera Real',
          categoria: 'Software',
          estado: 'Pendiente',
          fecha: '2026-10-20',
          prioridad: 'Alta',
        ),
        Incidencia(
          id: 'INC-202',
          titulo: 'WiFi intermitente en recepción',
          descripcion: 'Cortes en la red inalambrica.',
          cliente: 'Clinica del Prado',
          categoria: 'Redes',
          estado: 'En proceso',
          fecha: '2026-10-20',
          prioridad: 'Media',
        ),
        Incidencia(
          id: 'INC-203',
          titulo: 'Mouse con boton roto',
          descripcion: 'El click izquierdo no responde.',
          cliente: 'Almacenes Centro',
          categoria: 'Hardware',
          estado: 'Resuelta',
          fecha: '2026-10-20',
          prioridad: 'Baja',
        ),
        Incidencia(
          id: 'INC-204',
          titulo: 'Configuración de VPN',
          descripcion: 'No se puede establecer tunel seguro.',
          cliente: 'Servicios Norte',
          categoria: 'Redes',
          estado: 'Pendiente',
          fecha: '2026-10-20',
          prioridad: 'Alta',
        ),
      ];
    });

    test('Filtrar únicamente por estado', () {
      final pendientes = gestor.filtrar(estado: 'Pendiente');
      expect(pendientes.length, 2);
      expect(pendientes.map((x) => x.id), containsAll(['INC-201', 'INC-204']));

      final resueltas = gestor.filtrar(estado: 'Resuelta');
      expect(resueltas.length, 1);
      expect(resueltas.first.id, 'INC-203');
    });

    test('Filtrar únicamente por prioridad', () {
      final altas = gestor.filtrar(prioridad: 'Alta');
      expect(altas.length, 2);

      final medias = gestor.filtrar(prioridad: 'Media');
      expect(medias.length, 1);
      expect(medias.first.id, 'INC-202');
    });

    test('Filtrar combinando texto, estado y prioridad', () {
      // Buscar 'vpn', estado 'Pendiente' y prioridad 'Alta'
      final resultado = gestor.filtrar(
        texto: 'vpn',
        estado: 'Pendiente',
        prioridad: 'Alta',
      );
      expect(resultado.length, 1);
      expect(resultado.first.id, 'INC-204');
    });

    test('Combinación sin coincidencias devuelve lista vacía sin error', () {
      final resultado = gestor.filtrar(
        texto: 'mouse',
        estado: 'Pendiente',
        prioridad: 'Alta',
      );
      expect(resultado.isEmpty, isTrue);
    });

    test('Restablecer a Todos/Todas devuelve la lista completa', () {
      final resultado = gestor.filtrar(
        texto: '',
        estado: 'Todos',
        prioridad: 'Todas',
      );
      expect(resultado.length, 4);
    });
  });
}
