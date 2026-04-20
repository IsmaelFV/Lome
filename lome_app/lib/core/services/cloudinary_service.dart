import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/env.dart';

/// Servicio de subida de imagenes a Cloudinary.
///
/// Usa unsigned uploads con un upload preset configurado en Cloudinary.
class CloudinaryService {
  CloudinaryService._();

  static String get _uploadUrl =>
      'https://api.cloudinary.com/v1_1/${Env.cloudinaryCloudName}/image/upload';

  /// Sube una imagen y devuelve la URL publica.
  static Future<String> uploadImage({
    required Uint8List bytes,
    required String folder,
    String? publicId,
  }) async {
    final uri = Uri.parse(_uploadUrl);
    final request = http.MultipartRequest('POST', uri);

    request.fields['upload_preset'] = Env.cloudinaryUploadPreset;
    request.fields['folder'] = folder;
    if (publicId != null) {
      request.fields['public_id'] = publicId;
    }

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: '${publicId ?? DateTime.now().millisecondsSinceEpoch}.jpg',
      ),
    );

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw Exception('Error al subir imagen: $body');
    }

    final json = jsonDecode(body) as Map<String, dynamic>;
    return json['secure_url'] as String;
  }

  /// Genera una URL optimizada con transformaciones de Cloudinary.
  static String optimizedUrl(
    String originalUrl, {
    int width = 400,
    int height = 400,
    String crop = 'fill',
    String quality = 'auto',
    String format = 'auto',
  }) {
    // Cloudinary URL pattern: .../upload/v123/folder/image.jpg
    // Insert transformations after /upload/
    return originalUrl.replaceFirst(
      '/upload/',
      '/upload/w_$width,h_$height,c_$crop,q_$quality,f_$format/',
    );
  }
}
