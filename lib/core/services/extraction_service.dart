// import 'dart:io';
// import 'package:archive/archive.dart' as archive;
// import 'package:quickzip/core/models/zip_file.dart';
// import 'package:quickzip/core/utils/password_generator.dart';
// import '../utils/file_utils.dart';

// class ExtractionService {
//   static Future<void> extractFile(FileModel file, {String? password}) async {
//     try {
//       final bytes = await File(file.path).readAsBytes();
//       final decodedArchive = archive.ZipDecoder().decodeBytes(
//         bytes,
//         password: password ??
//             (PasswordGenerator.isTomitoFile(file.name)
//                 ? PasswordGenerator.generatePassword(file.name)
//                 : null),
//       );

//       final extractPath = await FileUtils.getExtractedFilesPath();
//       final destinationPath = '$extractPath/${file.name}';

//       await FileUtils.createDirectoryIfNotExists(destinationPath);

//       for (final archiveFile in decodedArchive) {
//         final filePath = '$destinationPath/${archiveFile.name}';
//         if (archiveFile.isFile) {
//           final data = archiveFile.content as List<int>;
//           await File(filePath).create(recursive: true);
//           await File(filePath).writeAsBytes(data);
//         } else {
//           await Directory(filePath).create(recursive: true);
//         }
//       }
//     } catch (e) {
//       throw Exception('Failed to extract file: $e');
//     }
//   }
// }
