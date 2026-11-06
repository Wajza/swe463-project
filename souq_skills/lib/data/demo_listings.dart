import '../models/skill_listing.dart';

// Temporary sample listings. The team will supply repository data later.
const demoListings = [
  SkillListing(
    id: 'demo-brand-design',
    title: 'Brand design basics',
    owner: 'Lama Alharbi',
    category: 'Creative & Design',
    offers: 'Brand design',
    wants: 'Excel dashboards',
    distance: '1.8',
    rating: 4.9,
    description: 'Learn how to shape a clear, memorable brand—from '
        'moodboard to first logo concepts.',
    location: 'Al Malqa, Riyadh',
    availability: 'Weeknights after 6 PM',
    idealTrade: '2 sessions · 60 minutes each',
    isVerified: true,
    reviewCount: 27,
    completedTrades: 43,
  ),
  SkillListing(
    id: 'demo-arabic',
    title: 'Conversational Arabic',
    owner: 'Noura S.',
    category: 'Languages',
    offers: 'Arabic',
    wants: 'Photography',
    distance: '4.1',
    rating: 4.8,
    description: 'Build confidence in everyday Arabic conversations '
        'through practical speaking sessions.',
    location: 'Jeddah',
    availability: 'To be agreed with the member',
    idealTrade: 'Discuss sessions in chat',
  ),
];
