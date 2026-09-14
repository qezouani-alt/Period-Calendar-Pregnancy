import 'package:flutter/foundation.dart';

/// General, stage-aware pregnancy education. Development and symptoms vary,
/// so this is written to support—not replace—individual antenatal care.
@immutable
class WeeklyPregnancyInformation {
  const WeeklyPregnancyInformation({
    required this.baby,
    required this.forMother,
    required this.careFocus,
  });

  final String baby;
  final String forMother;
  final String careFocus;
}

class PregnancyWeeklyInformation {
  const PregnancyWeeklyInformation._();

  static WeeklyPregnancyInformation forWeek(int week) {
    if (week <= 8) return _earlyDevelopment;
    if (week <= 12) return _firstTrimester;
    if (week <= 16) return _earlySecondTrimester;
    if (week <= 20) return _midSecondTrimester;
    if (week <= 24) return _laterSecondTrimester;
    if (week <= 28) return _thirdTrimesterApproaches;
    if (week <= 32) return _earlyThirdTrimester;
    if (week <= 36) return _lateThirdTrimester;
    if (week <= 40) return _fullTermApproaches;
    return _afterDueDate;
  }

  static const _earlyDevelopment = WeeklyPregnancyInformation(
    baby:
        'Early structures for the brain, spine, heart and other organs are developing. This is an important stage of rapid change.',
    forMother:
        'Tiredness, nausea, breast tenderness and frequent urination can happen in early pregnancy, but every pregnancy feels different.',
    careFocus:
        'Arrange antenatal care as soon as you can. Ask your clinician about recommended tests, supplements and medicines for you.',
  );

  static const _firstTrimester = WeeklyPregnancyInformation(
    baby:
        'The brain, limbs and internal organs continue developing. Eyelids remain closed, and cartilage in the limbs will gradually harden later.',
    forMother:
        'Nausea and fatigue can still be common. Small, regular meals, fluids and rest may help; tell your care team if symptoms are difficult to manage.',
    careFocus:
        'Early antenatal visits can include blood pressure, blood and urine checks, and discussions about screening based on local guidance.',
  );

  static const _earlySecondTrimester = WeeklyPregnancyInformation(
    baby:
        'Bones are becoming firmer and the body is growing. Skin is still thin at this stage, and the body’s features continue to develop.',
    forMother:
        'Some people notice more energy as the first trimester passes. Gentle activity can be helpful when your clinician says it is safe for you.',
    careFocus:
        'Keep scheduled visits and ask what screening or ultrasound timing is recommended where you live.',
  );

  static const _midSecondTrimester = WeeklyPregnancyInformation(
    baby:
        'Your baby continues to grow and develop. Some people begin to notice movement during this part of pregnancy, but timing varies widely.',
    forMother:
        'Your body is adapting as the uterus grows. Bring new pain, bleeding, dizziness or any concern to your maternity-care team promptly.',
    careFocus:
        'Ask about the next recommended checks and use appointments to discuss sleep, movement, nutrition and emotional wellbeing.',
  );

  static const _laterSecondTrimester = WeeklyPregnancyInformation(
    baby:
        'Growth continues and the lungs, brain and senses continue maturing. Movement patterns are individual and can change as your baby grows.',
    forMother:
        'It can help to notice what feels usual for you without comparing your pregnancy to someone else’s. Rest and ask for support when you need it.',
    careFocus:
        'Your care team may discuss routine screening and growth checks around this stage. Follow the plan they recommend for you.',
  );

  static const _thirdTrimesterApproaches = WeeklyPregnancyInformation(
    baby:
        'Your baby is growing steadily, while the lungs and brain continue to mature. There is still important development ahead.',
    forMother:
        'Changes in sleep, comfort and energy are common as pregnancy progresses. Seek advice for symptoms that are severe, persistent or worrying.',
    careFocus:
        'Continue regular care. Your clinician may plan tests such as blood-pressure, urine or glucose checks based on your needs and local guidance.',
  );

  static const _earlyThirdTrimester = WeeklyPregnancyInformation(
    baby:
        'Growth and organ maturation continue. Your baby’s brain and lungs are still developing as the body prepares for life after birth.',
    forMother:
        'You may feel more physical strain now. Make room for rest, food, fluids and support, and mention any new or worsening symptoms at once.',
    careFocus:
        'Ask your care team when and how they want you to contact them about changes in your baby’s movements or your own health.',
  );

  static const _lateThirdTrimester = WeeklyPregnancyInformation(
    baby:
        'Your baby continues to gain weight and mature. Position and growth are assessed by your care team as part of routine care when needed.',
    forMother:
        'It is a good time to prepare practical support and ask questions about birth, feeding and the first days after birth.',
    careFocus:
        'Keep every antenatal visit. Ask what labour signs and urgent warning signs mean you should call or go in right away.',
  );

  static const _fullTermApproaches = WeeklyPregnancyInformation(
    baby:
        'Your baby is continuing final growth and organ maturation. The due date is an estimate, not a deadline.',
    forMother:
        'Rest, eat and drink regularly, and lean on your support network. It is normal to have questions as birth gets closer.',
    careFocus:
        'Follow your personalised birth plan and contact instructions. Seek urgent care for bleeding, severe abdominal pain, severe headache, or any urgent concern.',
  );

  static const _afterDueDate = WeeklyPregnancyInformation(
    baby:
        'Pregnancy timing varies. Your care team can assess your baby’s wellbeing and discuss the safest next steps for you both.',
    forMother:
        'Staying in contact with your maternity-care team matters most now. Your concerns and preferences should be part of every conversation.',
    careFocus:
        'Follow the monitoring and birth plan given by your clinician, and contact them straight away if you have any concern.',
  );
}
