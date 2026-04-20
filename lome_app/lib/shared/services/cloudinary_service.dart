import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../core/config/env.dart';
import '../../../core/errors/exceptions.dart';

/// Resultado de una subida exitosa a Cloudinary.
class CloudinaryUploadResult {
  /// URL segura (HTTPS) de la imagen.
  final String secureUrl;

  /// ID público del recurso (para transformaciones / borrado).
  final String publicId;

  /// Ancho en píxeles.
  final int width;

  /// Alto en píxeles.
  final int height;

  const CloudinaryUploadResult({
    required this.secureUrl,
    required this.publicId,
    required this.width,
    required this.height,
  });
}

/// Servicio para subir imágenes a Cloudinary.
///
/// Usa la **Upload API sin firma** (unsigned) con un upload preset
/// configurado en el dashboard de Cloudinary. Esto permite subir
/// directamente desde el cliente sin exponer credenciales.
///
/// ### Configuración en Cloudinary Dashboard
///
/// 1. Ir a **Settings → Upload → Upload Presets**.
/// 2. Crear un preset nuevo con modo **Unsigned**.
/// 3. Configurar:
///    - **Folder**: `lome/avatars` (organización)
///    - **Transformations** (eager): `c_fill,w_400,h_400,g_face,q_auto,f_auto`
///      (recorte cuadrado 400×400 centrado en el rostro, calidad y formato automáticos).
///    - **Allowed formats**: `jpg,png,webp`
///    - **Max file size**: 5 MB
/// 4. Copiar el **Upload Preset Name** y el **Cloud Name**.
/// 5. Inyectar ambos valores vía `--dart-define`:
///    ```
///    --dart-define=CLOUDINARY_CLOUD_NAME=tu_cloud
///    --dart-define=CLOUDINARY_UPLOAD_PRESET=tu_preset
///    ```
///
/// ### Flujo completo
///
/// ```
///   Usuario                 Flutter               Cloudinary         Supabase DB
///     │                       │                       │                  │
///     │  Elige imagen         │                       │                  │
///     │  (image_picker)       │                       │                  │
///     ├─────────────────────► │                       │                  │
///     │                       │  POST /upload         │                  │
///     │                       │  (multipart, bytes)   │                  │
///     │                       ├─────────────────────► │                  │
///     │                       │                       │                  │
///     │                       │  200 OK               │                  │
///     │                       │  { secure_url, ... }  │                  │
///     │                       │ ◄─────────────────────┤                  │
///     │                       │                       │                  │
///     │                       │  UPDATE profiles      │                  │
///     │                       │  SET avatar_url = URL │                  │
///     │                       ├──────────────────────────────────────► │
///     │                       │                       │                  │
///     │  Imagen actualizada   │                       │                  │
///     │ ◄─────────────────────┤                       │                  │
/// ```
class CloudinaryService {
  final http.Client _httpClient;

  CloudinaryService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  /// URL base del endpoint de Upload API para el cloud configurado.
  String get _uploadUrl =>
      'https://api.cloudinary.com/v1_1/${Env.cloudinaryCloudName}/image/upload';

  /// Sube una imagen representada como bytes.
  ///
  /// [imageBytes]: Los bytes de la imagen seleccionada.
  /// [fileName]: Nombre del archivo (para el Content-Disposition).
  /// [folder]: Carpeta dentro de Cloudinary (por defecto `lome/avatars`).
  ///
  /// Devuelve un [CloudinaryUploadResult] con la URL segura.
  ///
  /// Lanza [ServerException] si la subida falla.
  Future<CloudinaryUploadResult> uploadImage({
    required Uint8List imageBytes,
    required String fileName,
    String folder = 'lome/avatars',
  }) async {
    try {
      final uri = Uri.parse(_uploadUrl);

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = Env.cloudinaryUploadPreset
        ..fields['folder'] = folder
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            imageBytes,
            filename: fileName,
          ),
        );

      final streamedResponse = await _httpClient.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final errorMsg =
            (body['error'] as Map<String, dynamic>?)?['message'] ??
                'Error al subir la imagen';
        throw ServerException(
          message: errorMsg.toString(),
          statusCode: response.statusCode,
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      return CloudinaryUploadResult(
        secureUrl: data['secure_url'] as String,
        publicId: data['public_id'] as String,
        width: data['width'] as int,
        height: data['height'] as int,
      );
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'Error al subir la imagen: $e',
      );
    }
  }

  /// Genera una URL de transformación para un avatar cuadrado optimizado.
  ///
  /// Aplica: recorte cuadrado centrado en el rostro, calidad y formato auto.
  static String avatarUrl(String secureUrl, {int size = 200}) {
    // Cloudinary URL transformation:
    // .../upload/c_fill,w_200,h_200,g_face,q_auto,f_auto/...
    return secureUrl.replaceFirst(
      '/upload/',
      '/upload/c_fill,w_$size,h_$size,g_face,q_auto,f_auto/',
    );
  }

  void dispose() {
    _httpClient.close();
  }
}
