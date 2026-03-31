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
      'Your documents stay on your device. No data ever leaves.';
  static const String privacyDescription = 
      'CiteCoach works completely offline. Your documents never leave your device.';
  static const String privacyFeature1Title = 'Fully Offline';
  static const String privacyFeature1Desc = 'No internet required after initial setup';
  static const String privacyFeature2Title = 'On-Device AI';
  static const String privacyFeature2Desc = 'All processing happens locally on your phone';
  static const String privacyFeature3Title = 'No Cloud Upload';
  static const String privacyFeature3Desc = 'Your PDFs are never sent to any server';
  
  // Setup Flow - Model Setup Screen
  static const String modelSetupTitle = 'One-Time Setup';
  static const String modelSetupSubtitle = 
      'Download the AI model to enable intelligent Q&A';
  static const String modelSetupDescription =
      'Download the offline AI engine (2.4GB) to enable Q&A. This is a one-time setup.';
  static const String modelName = 'Gemma 2 2B';
  static const String modelDescription = 'Advanced AI optimized for document understanding';
  static const String modelSize = '1.6 GB';
  static const String modelNetwork = 'Wi-Fi only';
  static const String modelTime = '~5-8 minutes';
  static const String downloadSizeLabel = 'Download Size';
  static const String storageNeededLabel = 'Storage Needed';
  static const String requirementsTitle = 'Requirements';
  static const String requirement1 = 'Wi-Fi connection recommended';
  static const String requirement2 = 'At least 3GB free storage';
  static const String requirement3 = 'Keep app open during download';
  
  // Setup Flow - Download Screen
  static const String downloadNowButton = 'Download Now';
  static const String downloadNow = 'Download Now';
  static const String downloadLater = 'Download Later';
  static const String skipForNowButton = 'Skip for Now';
  static const String downloading = 'Downloading...';
  static const String downloadingTitle = 'Downloading AI Model';
  static const String downloadingSubtitle = 
      'This may take a few minutes depending on your connection';
  static const String downloadingDescription = 
      "This may take a few minutes. You can leave the app—we'll continue in the background.";
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
  static const String setupCompleteTitle = 'All Set!';
  static const String setupCompleteSubtitle = 
      'CiteCoach is now fully configured for offline use';
  static const String setupCompleteDescription = 
      'CiteCoach is now fully offline. Import a PDF to start getting evidence-based answers.';
  static const String getStarted = 'Get Started';
  static const String startUsingApp = 'Start Using CiteCoach';
  static const String capability1Title = 'Read PDFs Anywhere';
  static const String capability1Desc = 'Open and annotate documents offline';
  static const String capability2Title = 'Ask Questions';
  static const String capability2Desc = 'Get AI answers with page citations';
  static const String capability3Title = 'Voice Interaction';
  static const String capability3Desc = 'Ask questions by voice, hear answers aloud';
  
  // Library
  static const String libraryTitle = 'Library';
  static const String noDocumentsTitle = 'No Documents Yet';
  static const String noDocumentsDescription = 
      'Import a document to start asking questions and getting evidence-based answers with citations';
  static const String importPdf = '+ Import Document';
  static const String importAnotherPdf = '+ Import Document';
  static const String supportedFormats = 'PDF, Word, EPUB, TXT, Images';
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
      'Download the offline engine (1.5GB) to start asking questions and getting evidence-based answers.';
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
