class DocumentService {
  // Belgeden veya metinden Flutter kod parçalarını ayıklar
  String extractCodeFromContent(String fileContent) {
    if (fileContent.contains('```dart')) {
      final parts = fileContent.split('```dart');
      if (parts.length > 1) {
        return parts[1].split('```')[0].trim();
      }
    } else if (fileContent.contains('```')) {
      final parts = fileContent.split('```');
      if (parts.length > 1) {
        return parts[1].trim();
      }
    }
    return fileContent.trim();
  }
}
