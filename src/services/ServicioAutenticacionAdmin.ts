export class ServicioAutenticacionAdmin {
  private readonly correoAdministrador = 'avil3scruz@gmail.com'
  private readonly contrasenaAdministrador = 'sima2026'

  autenticar(correo: string, contrasena: string): boolean {
    return correo.trim().toLowerCase() === this.correoAdministrador && contrasena === this.contrasenaAdministrador
  }
}