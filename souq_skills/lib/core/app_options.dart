/// Fixed choices offered by the app's selection controls.
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
  static const sessionLengths = [30, 45, 60, 90, 120];
  static const availabilities = [
    'Mornings',
    'Afternoons',
    'Weekday evenings',
    'Weekends',
    'Flexible',
  ];
  static const meetingPlaces = [
    'Public library',
    'Café',
    'Community centre',
    'University campus',
  ];
  static const ratingTags = [
    'Great teacher',
    'On time',
    'Friendly',
    'Well prepared',
    'Would trade again',
  ];
  static const quickReplies = [
    'Sounds good!',
    'When are you free?',
    'Can we reschedule?',
    'Thank you!',
  ];
  static const creditAmounts = [10, 20, 30, 50];
  static const complaintTopics = [
    'A trade',
    'A member',
    'My wallet',
    'My account',
    'Something else',
  ];
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
}
