class AppSettings {
  const AppSettings({
    this.darkMode = false,
    this.messageNotifications = true,
    this.tradeNotifications = true,
    this.groupNotifications = true,
    this.searchAlerts = true,
    this.profileVisible = true,
    this.locationVisible = true,
    this.onlineOnly = false,
    this.womenOnly = false,
  });

  final bool darkMode;
  final bool messageNotifications;
  final bool tradeNotifications;
  final bool groupNotifications;
  final bool searchAlerts;
  final bool profileVisible;
  final bool locationVisible;
  final bool onlineOnly;
  final bool womenOnly;

  AppSettings copyWith({
    bool? darkMode,
    bool? messageNotifications,
    bool? tradeNotifications,
    bool? groupNotifications,
    bool? searchAlerts,
    bool? profileVisible,
    bool? locationVisible,
    bool? onlineOnly,
    bool? womenOnly,
  }) => AppSettings(
    darkMode: darkMode ?? this.darkMode,
    messageNotifications: messageNotifications ?? this.messageNotifications,
    tradeNotifications: tradeNotifications ?? this.tradeNotifications,
    groupNotifications: groupNotifications ?? this.groupNotifications,
    searchAlerts: searchAlerts ?? this.searchAlerts,
    profileVisible: profileVisible ?? this.profileVisible,
    locationVisible: locationVisible ?? this.locationVisible,
    onlineOnly: onlineOnly ?? this.onlineOnly,
    womenOnly: womenOnly ?? this.womenOnly,
  );
}
