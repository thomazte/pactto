final class ErroDominio implements Exception {
  const ErroDominio(this.codigo);

  final String codigo;

  @override
  String toString() => 'ErroDominio($codigo)';
}
