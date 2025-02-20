class AppConfig {
  // Image related settings
  static const maxImagesPerWork = 10;
  static const maxImageSize = 20 * 1024 * 1024; // 20MB
  static const maxImageWidth = 4096;
  static const maxImageHeight = 4096;
  static const thumbnailSize = 200;
  static const supportedImageFormats = ['jpg', 'jpeg', 'png'];

  static var dataPath="data";
}