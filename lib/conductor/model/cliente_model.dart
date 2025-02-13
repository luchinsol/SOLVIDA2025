class Cliente {
  final int id;
  final int usuario_id;
  final String nombre;
  final String apellidos;
  final String ruc;
  final DateTime fecha_nacimiento;
  final DateTime fecha_creacion_cuenta;
  final String sexo;
  final String dni;
  final String codigo;
  final double calificacion;
  final double saldo_beneficios;
  final String suscripcion;

  Cliente({
    required this.id,
    required this.usuario_id,
    required this.nombre,
    required this.apellidos,
    required this.ruc,
    required this.fecha_nacimiento,
    required this.fecha_creacion_cuenta,
    required this.sexo,
    required this.dni,
    required this.codigo,
    required dynamic calificacion,
    required dynamic saldo_beneficios,
    required this.suscripcion,
  })  : calificacion = (calificacion is int)
            ? calificacion.toDouble()
            : (calificacion as double),
        saldo_beneficios = (saldo_beneficios is int)
            ? saldo_beneficios.toDouble()
            : (saldo_beneficios as double);
}
