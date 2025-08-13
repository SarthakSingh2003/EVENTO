class AppConstants {
  // App Information
  static const String appName = 'Evento';
  static const String appVersion = '1.0.0';
  
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String eventsCollection = 'events';
  static const String ticketsCollection = 'tickets';
  
  // Event Categories
  static const List<String> eventCategories = [
    'Music',
    'Technology',
    'Business',
    'Education',
    'Sports',
    'Arts & Culture',
    'Food & Drink',
    'Health & Wellness',
    'Entertainment',
    'Other',
  ];
  
  // User Roles
  static const String roleOrganiser = 'organiser';
  static const String roleModerator = 'moderator';
  static const String roleAttendee = 'attendee';
  
  // Payment
  static const String currency = 'USD';
  static const double maxTicketPrice = 1000.0;
  static const int maxTicketsPerEvent = 10000;
  
  // Location
  static const double defaultLatitude = 40.7128; // New York
  static const double defaultLongitude = -74.0060;
  static const double defaultRadius = 50.0; // km
  
  // QR Code
  static const int qrCodeLength = 16;
  static const String qrCodePrefix = 'EVENTO';
  
  // Image
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageFormats = ['jpg', 'jpeg', 'png'];
  
  // Validation
  static const int minPasswordLength = 6;
  static const int maxTitleLength = 100;
  static const int maxDescriptionLength = 1000;
  static const int maxLocationLength = 200;
  
  // Time
  static const int reminderHoursBeforeEvent = 1;
  static const int maxEventDaysInFuture = 365;
  
  // UI
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double cardElevation = 2.0;
  
  // Animation
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration fastAnimationDuration = Duration(milliseconds: 150);
  static const Duration slowAnimationDuration = Duration(milliseconds: 500);
  
  // Error Messages
  static const String networkErrorMessage = 'Please check your internet connection and try again.';
  static const String generalErrorMessage = 'Something went wrong. Please try again.';
  static const String authErrorMessage = 'Authentication failed. Please check your credentials.';
  static const String permissionErrorMessage = 'Permission denied. Please grant the required permissions.';
  
  // Success Messages
  static const String eventCreatedMessage = 'Event created successfully!';
  static const String eventUpdatedMessage = 'Event updated successfully!';
  static const String ticketPurchasedMessage = 'Ticket purchased successfully!';
  static const String profileUpdatedMessage = 'Profile updated successfully!';
  
  // Placeholder Text
  static const String searchEventsPlaceholder = 'Search events...';
  static const String eventTitlePlaceholder = 'Enter event title';
  static const String eventDescriptionPlaceholder = 'Enter event description';
  static const String eventLocationPlaceholder = 'Enter event location';
  static const String emailPlaceholder = 'Enter your email';
  static const String passwordPlaceholder = 'Enter your password';
  static const String namePlaceholder = 'Enter your name';
  
  // Button Text
  static const String loginButtonText = 'Login';
  static const String signupButtonText = 'Sign Up';
  static const String createEventButtonText = 'Create Event';
  static const String updateEventButtonText = 'Update Event';
  static const String buyTicketButtonText = 'Buy Ticket';
  static const String scanQRButtonText = 'Scan QR Code';
  static const String saveButtonText = 'Save';
  static const String cancelButtonText = 'Cancel';
  static const String deleteButtonText = 'Delete';
  static const String confirmButtonText = 'Confirm';
  
  // Navigation Labels
  static const String homeLabel = 'Home';
  static const String eventsLabel = 'Events';
  static const String ticketsLabel = 'My Tickets';
  static const String profileLabel = 'Profile';
  static const String dashboardLabel = 'Dashboard';
  static const String scannerLabel = 'Scanner';
  
  // Tab Labels
  static const String upcomingEventsTab = 'Upcoming';
  static const String pastEventsTab = 'Past';
  static const String myEventsTab = 'My Events';
  static const String createEventTab = 'Create';
  
  // Status Messages
  static const String loadingMessage = 'Loading...';
  static const String noEventsMessage = 'No events found';
  static const String noTicketsMessage = 'No tickets found';
  static const String soldOutMessage = 'Sold Out';
  static const String freeMessage = 'Free';
  
  // Date Formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  
  // File Paths
  static const String assetsPath = 'assets';
  static const String imagesPath = 'assets/images';
  static const String iconsPath = 'assets/icons';
  static const String fontsPath = 'assets/fonts';
  
  // API Endpoints (for future use)
  static const String baseUrl = 'https://api.evento.com';
  static const String eventsEndpoint = '/events';
  static const String ticketsEndpoint = '/tickets';
  static const String usersEndpoint = '/users';
  
  // Storage Keys
  static const String userPrefsKey = 'user_preferences';
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language';
  static const String notificationsKey = 'notifications_enabled';
  
  // Notification Channels
  static const String eventChannelId = 'evento_events';
  static const String reminderChannelId = 'evento_reminders';
  static const String generalChannelId = 'evento_general';
  
  // Deep Link Schemes
  static const String deepLinkScheme = 'evento';
  static const String eventDeepLink = 'evento://event';
  static const String ticketDeepLink = 'evento://ticket';
  
  // Analytics Events (for future use)
  static const String eventViewedEvent = 'event_viewed';
  static const String ticketPurchasedEvent = 'ticket_purchased';
  static const String qrCodeScannedEvent = 'qr_code_scanned';
  static const String userRegisteredEvent = 'user_registered';
} 