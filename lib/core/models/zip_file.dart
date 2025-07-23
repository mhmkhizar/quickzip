class FileModel {
  final String name;
  final String path;
  final DateTime dateAdded;
  final bool isPasswordProtected;
  final bool isTomitoPlus;
  final String? password;

  FileModel({
    required this.name,
    required this.path,
    required this.dateAdded,
    this.isPasswordProtected = false,
    this.isTomitoPlus = false,
    this.password,
  });

  bool get requiresRewardedAd => isTomitoPlus;

  // Factory constructor for creating a FileModel from a path
  factory FileModel.fromPath(String path) {
    final name = path.split('/').last;
    final isTomitoPlus = name.endsWith('Tomito+');
    final isPasswordProtected =
        isTomitoPlus || path.contains('password'); // Example check

    return FileModel(
      name: name,
      path: path,
      dateAdded: DateTime.now(),
      isPasswordProtected: isPasswordProtected,
      isTomitoPlus: isTomitoPlus,
    );
  }

  bool get requiresPassword => isPasswordProtected && !isTomitoPlus;

  bool get autoFillPassword => isTomitoPlus && isPasswordProtected;
}
