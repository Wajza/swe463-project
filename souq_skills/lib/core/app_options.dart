/// Fixed choices offered by the app's forms.
class AppOptions {
  const AppOptions._();

  static const defaultCity = 'Riyadh';
  static const cities = [
    'Riyadh',
    'Jeddah',
    'Dammam',
    'Khobar',
    'Makkah',
    'Madinah',
  ];
  static const deliveryMethods = ['Online', 'In person'];
  static const memberReportReasons = [
    'Harassment',
    'Spam or scam',
    'Fake profile',
    'Inappropriate content',
    'Other',
  ];
  static const tradeIssueReasons = [
    'Member did not attend',
    'Skill was not as described',
    'Unsafe behaviour',
    'Other',
  ];
  static const supportSubjects = ['Account', 'Trades', 'Wallet', 'Other'];
}
