import 'package:flutter/foundation.dart';

@immutable
class PregnancyDailyAdvice {
  const PregnancyDailyAdvice({
    required this.title,
    required this.forMother,
    required this.forBaby,
    this.urgentNote,
  });

  final String title;
  final String forMother;
  final String forBaby;
  final String? urgentNote;
}

/// Educational daily prompts grounded in WHO antenatal-care themes.
/// They are intentionally general; personal advice belongs with the care team.
class DailyPregnancyAdvice {
  const DailyPregnancyAdvice();

  PregnancyDailyAdvice forDate(DateTime date) {
    final dayOfYear = date.difference(DateTime(date.year)).inDays;
    return _advice[dayOfYear % _advice.length];
  }

  static const _advice = <PregnancyDailyAdvice>[
    PregnancyDailyAdvice(
      title: 'Stay connected to your care',
      forMother:
          'Keep your antenatal visits and bring any questions or symptoms you have noticed. Your care team can personalise screening, medicines and supplements.',
      forBaby:
          'Routine antenatal care helps your team follow your baby’s growth and plan the right checks at the right time.',
    ),
    PregnancyDailyAdvice(
      title: 'Nourish both of you',
      forMother:
          'Choose regular meals with a variety of foods, including vegetables or fruit, beans or lentils, grains and protein when available. Drink water through the day.',
      forBaby:
          'Balanced nutrition supports your changing body and your baby’s development. Ask your clinician which prenatal supplement is right for you.',
    ),
    PregnancyDailyAdvice(
      title: 'Move gently, if it is safe for you',
      forMother:
          'If your clinician says activity is safe, choose comfortable movement such as an easy walk, stretching or a pregnancy-safe class. Rest if you feel unwell.',
      forBaby:
          'Keeping well and attending care helps support a healthy pregnancy. Your care team can adapt activity advice for your pregnancy.',
    ),
    PregnancyDailyAdvice(
      title: 'Care for your emotional wellbeing',
      forMother:
          'Make space for rest and talk to someone you trust about how you feel. Contact a health worker if sadness, anxiety, exhaustion or feeling unable to cope is persistent.',
      forBaby:
          'Support around you and timely care help create a safer, more supported pregnancy for you and your baby.',
    ),
    PregnancyDailyAdvice(
      title: 'Choose safer everyday habits',
      forMother:
          'Avoid tobacco, alcohol and recreational drugs. Check with a clinician or pharmacist before starting, stopping or changing any medicine or supplement.',
      forBaby:
          'Avoiding harmful substances and getting advice about medicines helps protect your baby during development.',
    ),
    PregnancyDailyAdvice(
      title: 'Prepare for the next milestone',
      forMother:
          'Write down questions for your next visit and keep your health records together. Ask about the screenings, vaccines and ultrasound timing recommended where you live.',
      forBaby:
          'Recommended checks help the care team understand how your pregnancy is progressing and discuss the next steps with you.',
    ),
    PregnancyDailyAdvice(
      title: 'Know when to seek help',
      forMother:
          'Listen to changes in how you feel. Do not wait for a scheduled visit if something worries you—contact your maternity service or local urgent-care service.',
      forBaby:
          'After you begin feeling regular movement, ask your care team what is normal for you and seek urgent advice if movement reduces or stops.',
      urgentNote:
          'Seek urgent care now for vaginal bleeding, severe or persistent headache, severe abdominal pain, high fever, sudden swelling or any urgent concern.',
    ),
  ];
}
