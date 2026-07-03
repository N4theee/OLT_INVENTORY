class AppConstants {
  AppConstants._();

  static const String appName = 'OLT Inventory';
  static const String appVersion = '1.0.0';
  static const String churchName = "OUR LORD'S TEMPLE";
  static const String churchMinistryName = "OUR LORD'S TEMPLE MINISTRY";
  static const String churchLocation = 'AFB-CULIAT';
  static const String reportGeneratedBy = 'OLT Inventory App';

  // Replace with your Supabase project credentials.
  static const String supabaseUrl = 'https://fceziclpidheawsbepxd.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZjZXppY2xwaWRoZWF3c2JlcHhkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODIxMTkxMTEsImV4cCI6MjA5NzY5NTExMX0.LeO85adeZ-Fcp-Uoy9VpvziJYze3l_XCCOf6WJ2VV8E';

  static const String storageBucket = 'inventory-images';

  static const int pageSize = 20;
  static const int lowStockThreshold = 5;
  static const int recentItemsLimit = 10;
  static const int dashboardVisibleLogs = 5;
  static const double dashboardLogRowHeight = 56;
  static const double maxContentWidth = 1200;

  static const String statusGoodCondition = 'Good condition';
  static const String statusNeedsRepair = 'Needs repair';
  static const String statusDepreciated = 'Depreciated';

  static const List<String> statusOptions = [
    statusGoodCondition,
    statusNeedsRepair,
    statusDepreciated,
  ];

  static const String itemHolderPersonal = 'Personal';
  static const String itemHolderChurch = 'Church';
  static const String defaultItemHolder = itemHolderChurch;

  static const List<String> itemHolderOptions = [
    itemHolderPersonal,
    itemHolderChurch,
  ];

  static const String cedDepartmentName = 'CED';

  static const List<String> cedCategories = [
    'Dancers',
    'Musicians',
    'Sound System',
    'Sunday School',
    'Technical',
  ];

  static const List<String> logActions = [
    'Added',
    'Updated',
    'Deleted',
    'Restored',
    'Permanently Deleted',
  ];

  static const List<String> defaultDepartments = [
    'Pastors Department',
    'Board',
    "Men's Department",
    "Women's Department",
    'Youth Department',
    'CED',
    'Uncategorized',
  ];
}
