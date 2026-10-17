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
}
