import 'health_mode_service.dart';

class WellbeingAdvice {
  const WellbeingAdvice({
    required this.title,
    required this.message,
    required this.source,
    this.careNote,
  });
  final String title;
  final String message;
  final String source;
  final String? careNote;
}

class WellbeingAdviceService {
  const WellbeingAdviceService();

  WellbeingAdvice forFeeling(String feeling, ActiveHealthMode mode) {
    final pregnancy = mode == ActiveHealthMode.pregnancyActive;
    return switch (feeling) {
      'Good' => const WellbeingAdvice(
        title: 'Keep noticing what helps',
        message:
            'It is useful to notice the routines, food, rest, or support that helped you feel this way today.',
        source: 'General wellbeing reminder.',
      ),
      'Tired' => WellbeingAdvice(
        title: 'A gentle pause can help',
        message: pregnancy
            ? 'Rest when you can, keep a drink nearby, and choose regular meals that feel manageable today.'
            : 'A short rest, water, and a regular meal can be a gentle reset today.',
        source: pregnancy
            ? 'Informed by NHS pregnancy tiredness guidance.'
            : 'General wellbeing reminder.',
        careNote: pregnancy
            ? 'If tiredness feels sudden, severe, or worrying to you, contact your maternity care team.'
            : null,
      ),
      'Nauseous' => WellbeingAdvice(
        title: 'Take it slowly',
        message:
            'Small, frequent plain meals and sipping water little and often may feel easier. Avoid foods or smells that make you feel worse.',
        source: pregnancy
            ? 'Informed by NHS guidance on nausea and vomiting in pregnancy.'
            : 'General comfort suggestion.',
        careNote: pregnancy
            ? 'Contact a healthcare professional if you cannot keep food or fluids down, feel dizzy or faint, or are concerned.'
            : null,
      ),
      'Low energy' => WellbeingAdvice(
        title: 'Keep today simple',
        message:
            'Choose one manageable task, take a pause, and have water or a nourishing snack if that feels helpful.',
        source: 'General wellbeing reminder.',
        careNote: pregnancy
            ? 'Discuss persistent or concerning low energy with your maternity care team.'
            : null,
      ),
      'Headache' => WellbeingAdvice(
        title: 'A quiet reset may help',
        message:
            'Have some water, rest your eyes, and take a quiet break if you can. A short note may help you notice patterns over time.',
        source: pregnancy
            ? 'Informed by NHS pregnancy headache guidance.'
            : 'General headache self-care information.',
        careNote: pregnancy
            ? 'Contact your maternity care team urgently for a severe headache, vision changes, pain below the ribs, vomiting, or sudden swelling.'
            : 'Seek medical advice for a severe, unusual, or worsening headache.',
      ),
      'Dizzy' => WellbeingAdvice(
        title: 'Pause somewhere safe',
        message: pregnancy
            ? 'Sit down promptly or lie on your side if you feel faint, and get up slowly after sitting or lying down.'
            : 'Sit down promptly, take a slow breath, and have water if that feels helpful.',
        source: pregnancy
            ? 'Informed by NHS guidance on feeling faint in pregnancy.'
            : 'General safety reminder.',
        careNote: pregnancy
            ? 'Contact a healthcare professional if dizziness does not pass, you faint, or you are concerned.'
            : 'Seek medical advice if dizziness is severe, repeated, or worrying to you.',
      ),
      'Anxious' => WellbeingAdvice(
        title: 'You do not have to carry it alone',
        message:
            'Try a few slow breaths and consider sharing what is on your mind with someone you trust.',
        source: pregnancy
            ? 'Informed by NHS anxiety in pregnancy guidance.'
            : 'General wellbeing reminder.',
        careNote: pregnancy
            ? 'If worry is hard to control or affects daily life, speak with your midwife or doctor; support is available.'
            : 'If anxiety is persistent or affecting daily life, consider speaking with a healthcare professional.',
      ),
      'Low mood' => WellbeingAdvice(
        title: 'A small connection can matter',
        message:
            'If it feels right, tell someone you trust how you are doing and choose one small, kind action for yourself today.',
        source: pregnancy
            ? 'Informed by NHS mental health in pregnancy guidance.'
            : 'General wellbeing reminder.',
        careNote: pregnancy
            ? 'If low mood persists, feels overwhelming, or affects daily life, speak with your midwife or doctor. Seek urgent help if you may harm yourself or others.'
            : 'If low mood persists or feels overwhelming, seek support from a healthcare professional or local crisis service.',
      ),
      'Bloated' => const WellbeingAdvice(
        title: 'Choose comfort over pressure',
        message:
            'A gentle pause, comfortable clothing, and noting what feels supportive can be enough for today.',
        source:
            'General comfort reminder; this is not a diagnosis or treatment plan.',
      ),
      'Uncomfortable' => WellbeingAdvice(
        title: 'Check in with your comfort',
        message:
            'A change of position, a quiet pause, and noting what helps can give you useful context for your next check-in.',
        source: 'General comfort reminder.',
        careNote: pregnancy
            ? 'If discomfort, bleeding, or any symptom concerns you, contact a healthcare professional.'
            : null,
      ),
      'Cramps' => const WellbeingAdvice(
        title: 'Make room for comfort',
        message:
            'Rest, gentle movement if it feels right for you, and warmth may be comforting. Keep a note of what helps.',
        source:
            'General period comfort information; not a diagnosis or treatment plan.',
        careNote:
            'If pain is severe, different for you, or disrupts daily life, consider speaking with a healthcare professional.',
      ),
      'Emotional' => const WellbeingAdvice(
        title: 'Be gentle with yourself',
        message:
            'A few slow breaths, a short note, or reaching out to someone you trust can be a helpful next step.',
        source: 'General wellbeing reminder.',
      ),
      'Calm' => const WellbeingAdvice(
        title: 'Notice what is helping',
        message:
            'If you would like, save a short note about what supported this moment so you can return to it later.',
        source: 'General wellbeing reminder.',
      ),
      _ => const WellbeingAdvice(
        title: 'Check-in saved',
        message:
            'Thank you for noticing how you feel. You can add more detail whenever it is useful to you.',
        source: 'General wellbeing reminder.',
      ),
    };
  }
}
