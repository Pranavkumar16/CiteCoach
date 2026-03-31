/// All user-facing strings in CiteCoach.
/// Centralized for easy localization in the future.
abstract final class AppStrings {
  // App Info
  static const String appName = 'CiteCoach';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Offline document intelligence';
  
  // Setup Flow - Privacy Screen
  static const String privacyTitle = '100% Offline & Private';
  static const String privacySubtitle =
      'CiteCoach works completely offline. Your documents never leave your device.';
  
  // Setup Flow - Model Setup Screen
  static const String modelSetupTitle = 'One-Time Setup';
  static const String modelSetupSubtitle =
      'Download the offline intelligence engine (1.5GB) to enable Q&A. This happens once.';
  static const String modelSize = '1.5 GB';
  static const String modelNetwork = 'Wi-Fi only';
  static const String modelTime = '~3-5 minutes';
  
  // Setup Flow - Download Screen
  static const String downloadNowButton = 'Download Now';
  static const String downloadLaterButton = 'Download Later';
  static const String downloading = 'Downloading...';
  static const String downloadingTitle = 'Downloading...';
  static const String downloadingSubtitle =
      "This may take a few minutes. You can leave the app\u2014we'll continue in the background.";
  static const String downloadInProgress = 'Download in Progress';
  static const String downloadPaused = 'Download Paused';
  static const String downloadError = 'Download Error';
  static const String storageUsed = 'Storage used';
  static const String pause = 'Pause';
  static const String pauseButton = 'Pause';
  static const String resume = 'Resume';
  static const String resumeButton = 'Resume';
  static const String paused = 'Paused';
  static const String ready = 'Ready';
  static const String retryButton = 'Retry Download';
  
  // Setup Flow - Complete Screen
  static const String setupCompleteTitle = "You're Ready!";
  static const String setupCompleteSubtitle =
      'CiteCoach is now fully offline. Import a PDF to start getting evidence-based answers.';
  static const String getStarted = 'Get Started';
  
  // Library
  static const String libraryTitle = 'Library';
  static const String noDocumentsTitle = 'No Documents Yet';
  static const String noDocumentsDescription =
      'Import a PDF to start asking questions and getting evidence-based answers';
  static const String importPdf = '+ Import PDF';
  static const String importAnotherPdf = '+ Import Another PDF';
  static const String supportedFormats = 'PDF';
  static const String chat = 'Chat';
  static const String read = 'Read';
  
  // Document Processing
  static const String processingTitle = 'Processing Document';
  static const String processingDescription = 'Preparing your document for intelligent Q&A...';
  static const String extractingText = 'Extracting text';
  static const String indexingForSearch = 'Indexing for search...';
  static const String finalizing = 'Finalizing';
  
  static const String documentReadyTitle = 'Document Ready!';
  static const String documentReadyDescription = 
      'You can now ask questions and get evidence-based answers with citations.';
  static const String startChatting = 'Start Chatting';
  static const String pages = 'Pages';
  static const String processed = 'Processed';
  
  // Chat
  static const String askQuestion = 'Ask a Question';
  static const String askQuestionDescription = 'Get evidence-based answers from this document';
  static const String askAnything = 'Ask anything...';
  static const String searchingDocument = 'Searching document...';
  static const String readAloud = 'Read aloud';
  
  // Voice
  static const String listening = 'Listening...';
  static const String searching = 'Searching...';
  static const String speaking = 'Speaking...';
  static const String cancel = 'Cancel';
  static const String stop = 'Stop';
  
  // PDF Reader
  static const String fromChatAnswer = 'From chat answer →';
  static const String pageOf = 'Page {current} of {total}';
  
  // Settings
  static const String settingsTitle = 'Settings';
  static const String offlineStatus = 'OFFLINE STATUS';
  static const String offlineMode = 'Offline Mode';
  static const String alwaysActive = 'Always active';
  static const String performance = 'PERFORMANCE';
  static const String lowPowerMode = 'Low-Power Mode';
  static const String modelInfo = 'Model Info';
  static const String voice = 'VOICE';
  static const String speechSpeed = 'Speech Speed';
  static const String normal = 'Normal (1.0x)';
  
  // Download Required (when user chose "Download Later")
  static const String downloadRequiredTitle = 'Download Required';
  static const String downloadRequiredDescription =
      'To chat with your documents, download the offline engine (1.5 GB). '
      'This is a one-time download and all processing will happen offline on your device.';
  static const String downloadRequiredNote =
      'You can still import and read PDFs. Chat will unlock after download.';
  static const String backToLibrary = 'Back to Library';
  
  // Errors
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorNoInternet = 'No internet connection. Please connect to Wi-Fi to download the model.';
  static const String errorPdfLoad = 'Could not load PDF. The file may be corrupted.';
  static const String errorProcessing = 'Error processing document. Please try again.';
  
  // Actions
  static const String continueButton = 'Continue';
  static const String retry = 'Retry';
  static const String delete = 'Delete';
  static const String confirm = 'Confirm';
  
  // Time/Date formats
  static const String addedToday = 'Added today';
  static const String addedYesterday = 'Added yesterday';
  
  // Accessibility
  static const String micButtonLabel = 'Voice input';
  static const String speakerButtonLabel = 'Read answer aloud';
  static const String citationLabel = 'Citation from page';
  static const String backButtonLabel = 'Go back';
  static const String settingsButtonLabel = 'Open settings';
}
