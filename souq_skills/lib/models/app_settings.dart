class AppSettings {
  const AppSettings({
    this.darkMode = false,
    this.messageNotifications = true,
    this.tradeNotifications = true,
    this.groupNotifications = true,
    this.profileVisible = true,
    this.locationVisible = true,
  });

  final bool darkMode;
  final bool messageNotifications;
  final bool tradeNotifications;
  final bool groupNotifications;
  final bool profileVisible;
  final bool locationVisible;

  AppSettings copyWith({
    bool? darkMode,
    bool? messageNotifications,
    bool? tradeNotifications,
    bool? groupNotifications,
    bool? profileVisible,
    bool? locationVisible,
  }) => AppSettings(
    darkMode: darkMode ?? this.darkMode,
    messageNotifications: messageNotifications ?? this.messageNotifications,
    tradeNotifications: tradeNotifications ?? this.tradeNotifications,
    groupNotifications: groupNotifications ?? this.groupNotifications,
    profileVisible: profileVisible ?? this.profileVisible,
    locationVisible: locationVisible ?? this.locationVisible,
  );

  Map<String, dynamic> toJson() => {
    'darkMode': darkMode,
    'messageNotifications': messageNotifications,
    'tradeNotifications': tradeNotifications,
    'groupNotifications': groupNotifications,
    'profileVisible': profileVisible,
    'locationVisible': locationVisible,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    darkMode: json['darkMode'] as bool,
    messageNotifications: json['messageNotifications'] as bool,
    tradeNotifications: json['tradeNotifications'] as bool,
    groupNotifications: json['groupNotifications'] as bool,
    profileVisible: json['profileVisible'] as bool,
    locationVisible: json['locationVisible'] as bool,
  );
}
