/// Contrato del repositorio de perfil.
abstract class ProfileRepository {
  Future<void> deleteAccount(String userId);
}
