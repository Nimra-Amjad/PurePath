import 'package:purepath/features/explore/models/intensity_level.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Habit library data
//
// Curated suggested habits sourced from the habit-tracker spreadsheet.
// Organized purely by [IntensityLevel] (beginner / intermediate / advanced) —
// habits no longer have a category, so the library is a single flat catalog
// the user browses by difficulty.
//
// GENERATED from habits_tracker.xlsx — edit the source sheet and regenerate
// rather than hand-editing if the catalog changes.
// ─────────────────────────────────────────────────────────────────────────────

const Map<IntensityLevel, List<String>> kHabitLibrary = {
  IntensityLevel.beginner: [
    // Fitness
    'Walk 10 minutes every day',
    'Do 5 push-ups every morning',
    'Stretch for 5 minutes before bed',
    'Take stairs instead of the elevator',
    'Follow a 10-min beginner YouTube workout',
    // Nutrition
    'Eat one serving of vegetables daily',
    'Reduce sugary drinks to one per day',
    'Cook at home at least 3x per week',
    'Eat breakfast every day',
    'Avoid eating after 9 PM',
    // Hydration
    'Drink one glass of water upon waking',
    'Carry a water bottle everywhere',
    'Drink at least 6 glasses of water daily',
    'Replace one sugary drink with water daily',
    'Set a water reminder on your phone',
    // Sleep
    'Set a consistent bedtime every night',
    'Avoid screens 30 minutes before bed',
    'Aim for 7 hours of sleep per night',
    'Keep your bedroom cool and dark',
    'Avoid caffeine after 3 PM',
    // Mindfulness
    'Take 3 deep breaths whenever you feel stressed',
    'Try a 5-minute guided meditation daily',
    'Write one thing you are grateful for each day',
    'Spend 5 minutes in silence each morning',
    'Focus fully on one task at a time',
    // Mental Health
    'Call or text a friend or family member daily',
    'Name and acknowledge your emotions each day',
    'Take a 10-minute walk in nature',
    'Limit news consumption to 15 minutes per day',
    'Write in a journal 3 times per week',
    // Learning
    'Read for 10 minutes every day',
    'Watch one educational video per week',
    'Learn one new word or concept per day',
    'Listen to a podcast during your commute',
    'Take one free online course per month',
    // Finance
    'Track all your expenses for one full week',
    'Create a simple monthly budget',
    'Set up automatic savings of any amount',
    'Cancel one unused subscription',
    'Read one personal finance article per week',
    // Self-Care
    'Do one thing you genuinely enjoy each day',
    'Get outside for fresh air every single day',
    'Say no to one unnecessary commitment this week',
    'Follow a simple morning skincare routine',
    'Go to bed at a reasonable time consistently',
    // Creativity
    'Doodle or sketch freely for 5 minutes daily',
    'Free-write in a journal for 10 minutes',
    'Try one new recipe every week',
    'Take a photo of something beautiful each day',
    'Listen to a new genre of music every week',
    // Social
    'Text or call a friend or family member daily',
    'Have one meaningful conversation every day',
    'Join one social group club or class',
    'Schedule a weekly catch-up call with someone you care about',
    'Send a kind message to someone unexpectedly',
    // Career
    'Update your resume or LinkedIn profile',
    'Set one professional goal for this month',
    'Learn one new work-relevant skill per week',
    'Ask your manager for feedback once a month',
    'Read industry news for 10 minutes every day',
    // Spirituality
    'Spend 5 minutes in quiet reflection every day',
    'Read one inspiring quote or passage daily',
    'Write down 3 things you are grateful for each morning',
    'Spend intentional time in nature once a week',
    'Perform one random act of kindness daily',
    // Digital Detox
    'No phone during any meals',
    'Set a 2-hour daily limit on social media apps',
    'Keep your phone outside the bedroom at night',
    'Take a 1-hour break from all screens daily',
    'Turn off all non-essential push notifications',
    // Home
    'Make your bed every single morning',
    'Do 10 minutes of tidying before bed each night',
    'Wash dishes right after every meal',
    'Take out the trash on a set day each week',
    'Declutter one small area or drawer per week',
  ],
  IntensityLevel.intermediate: [
    // Fitness
    'Work out 4 times per week for 30 minutes',
    'Reach 10,000 steps daily',
    'Follow a structured 8-week training plan',
    'Add strength training 2x per week',
    'Track workouts in a fitness journal',
    // Nutrition
    'Meal prep every Sunday',
    'Eat 5 servings of fruits and veggies daily',
    'Limit processed foods to 2x per week',
    'Track calories 3x per week',
    'Learn one new healthy recipe per week',
    // Hydration
    'Drink 8 glasses (2 liters) of water daily',
    'Track daily water intake with an app',
    'Add electrolytes after every workout',
    'Reduce caffeine to 2 cups per day',
    'Drink a glass of water before each meal',
    // Sleep
    'Keep the same sleep/wake time 7 days a week',
    'Use a sleep tracking app to monitor quality',
    'Do 10 minutes of light stretching before bed',
    'Avoid large meals 2 hours before sleep',
    'Journal before bed to clear your mind',
    // Mindfulness
    'Meditate for 10–15 minutes daily',
    'Practice a body scan meditation once a week',
    'Journal your thoughts and feelings for 10 minutes daily',
    'Start mornings device-free for the first 30 minutes',
    'Practice mindful eating at one meal per day',
    // Mental Health
    'Schedule a therapy or counseling session monthly',
    'Practice daily positive self-talk affirmations',
    'Set healthy boundaries with others consistently',
    'Engage in a hobby you love at least 2x per week',
    'Use one stress management technique every day',
    // Learning
    'Read one book per month',
    'Take a structured online course every quarter',
    'Practice a new skill for 20 minutes every day',
    'Write a weekly summary of what you have learned',
    'Join a study group or book club',
    // Finance
    'Build a 3-month emergency fund',
    'Review your budget and spending every month',
    'Start contributing to a retirement account',
    'Pay off one small debt this month',
    'Track your net worth every quarter',
    // Self-Care
    'Block weekly \'me time\' in your calendar',
    'Get a massage or spa treatment monthly',
    'Spend time on a beloved hobby 3x per week',
    'Set clear work-life boundaries and stick to them',
    'Do a half-day digital detox once a week',
    // Creativity
    'Dedicate 30 minutes to a creative project daily',
    'Take an art or craft class once a month',
    'Start a creative blog or social media page',
    'Collaborate on a creative project with someone else',
    'Experiment with a new creative medium each quarter',
    // Social
    'Host a dinner or casual gathering once a month',
    'Volunteer in your community every month',
    'Intentionally connect with one new person per week',
    'Practice active listening in every conversation',
    'Reconnect with one old friend every month',
    // Career
    'Network with one new professional every month',
    'Take a professional development course each quarter',
    'Find and meet with a mentor in your field',
    'Lead or own a project or initiative at work',
    'Document your professional achievements every week',
    // Spirituality
    'Establish a daily prayer or meditation practice',
    'Study spiritual texts or teachings every week',
    'Practice forgiveness toward yourself and others daily',
    'Connect with a spiritual community regularly',
    'Keep a spiritual growth journal',
    // Digital Detox
    'Do one full Sunday digital detox per month',
    'Delete social media apps for one week every quarter',
    'Set strict app time limits using your phone settings',
    'Have tech-free mornings until 9 AM every day',
    'Replace 30 minutes of screen time with reading a book',
    // Home
    'Deep clean one room thoroughly every week',
    'Organize your kitchen and meal prep every Sunday',
    'Do laundry on a fixed day each week',
    'Donate or discard unused items every month',
    'Create and follow a weekly cleaning checklist',
  ],
  IntensityLevel.advanced: [
    // Fitness
    'Train 5–6 days per week with periodization',
    'Complete a monthly fitness challenge',
    'Include HIIT sessions 2x per week',
    'Track macros alongside workouts',
    'Compete in a fitness event or race quarterly',
    // Nutrition
    'Follow a structured macro-based nutrition plan',
    'Track macros and micros daily',
    'Eat whole unprocessed foods 90% of the time',
    'Experiment with meal timing or intermittent fasting',
    'Consult a registered dietitian quarterly',
    // Hydration
    'Drink 3–4 liters of water daily',
    'Optimize hydration timing around workouts',
    'Use a structured electrolyte protocol',
    'Eliminate sugary drinks completely',
    'Monitor urine color to maintain optimal hydration',
    // Sleep
    'Use blackout curtains and white noise for deep sleep',
    'Track sleep cycles and wake at the optimal phase',
    'Use morning sunlight to regulate your circadian rhythm',
    'Eliminate alcohol for improved sleep quality',
    'Aim for 8–9 hours with 90%+ sleep efficiency',
    // Mindfulness
    'Meditate 20–30 minutes daily without interruption',
    'Attend a mindfulness retreat once a year',
    'Practice loving-kindness meditation every week',
    'Integrate mindfulness into all daily activities',
    'Teach mindfulness techniques to friends or family',
    // Mental Health
    'Attend regular therapy or coaching sessions',
    'Apply cognitive behavioral techniques in daily life',
    'Build and nurture a strong support network',
    'Complete a weekly mental health self-check-in',
    'Volunteer or help others regularly to build purpose',
    // Learning
    'Read two or more books per month',
    'Teach others what you learn to reinforce it',
    'Pursue a professional certification or degree',
    'Attend an industry conference or workshop quarterly',
    'Apply new skills to real-world projects every week',
    // Finance
    'Max out retirement account contributions each year',
    'Diversify your investment portfolio',
    'Rebalance your portfolio every quarter',
    'Build at least one additional income stream',
    'Meet with a financial advisor annually',
    // Self-Care
    'Design a non-negotiable daily self-care routine',
    'Take a solo retreat or personal vacation annually',
    'Work with a life coach once a quarter',
    'Practice radical self-acceptance every single day',
    'Audit your life for energy drains every quarter',
    // Creativity
    'Complete a major creative project every month',
    'Share your creative work publicly and consistently',
    'Seek honest feedback and iterate on your work',
    'Monetize a creative skill or side project',
    'Mentor someone else in their creative journey',
    // Social
    'Build and maintain a diverse supportive network',
    'Take a leadership role in a community organization',
    'Mentor someone younger or less experienced',
    'Plan and host regular meaningful social events',
    'Practice deep and vulnerable conversations with close friends',
    // Career
    'Build and execute a 5-year career roadmap',
    'Speak at events or publish thought leadership content',
    'Build a strong personal brand online and offline',
    'Negotiate salary title or scope of work annually',
    'Actively mentor and develop junior colleagues',
    // Spirituality
    'Attend a silent retreat or deep spiritual program',
    'Develop and live by a personal spiritual philosophy',
    'Practice non-attachment to outcomes every day',
    'Facilitate or lead spiritual discussions for others',
    'Integrate your core spiritual values into every decision',
    // Digital Detox
    'Implement a 24-hour digital detox every single week',
    'Reduce total daily screen time to under 2 hours',
    'Take extended multi-week breaks from social media',
    'Practice deep focused work with zero digital distractions',
    'Use analog tools like paper and pen for planning',
    // Home
    'Maintain a clean and organized home as a daily standard',
    'Follow detailed seasonal deep-cleaning schedules',
    'Apply minimalism principles to actively reduce clutter',
    'Automate home tasks with smart tools where possible',
    'Conduct a full home organization audit every quarter',
  ],
};
