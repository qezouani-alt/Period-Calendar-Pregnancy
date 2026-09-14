import 'package:flutter/material.dart';

import '../../../core/design_system/app_theme.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../shared/domain/health_models.dart';

const _topics = [
  'All guides',
  'Periods',
  'Ovulation',
  'Fertility',
  'Your body',
  'Pregnancy',
];

const articles = [
  HealthArticle(
    title: 'The menstrual cycle, gently explained',
    summary:
        'A clear guide to what changes across a cycle and why day one matters.',
    category: 'Periods',
    sourceOrganization: 'World Health Organization',
    sourceUrl:
        'https://www.who.int/news-room/fact-sheets/detail/menstrual-health',
    body: '''THE BIG PICTURE
The menstrual cycle is guided by hormones. Day one is the first day of menstrual bleeding. Over the cycle, the lining of the uterus changes and an ovary may release an egg. If pregnancy does not happen, the lining is shed during the next period.

YOUR PATTERN IS YOURS
Cycle length, flow, pain, energy, sleep and mood can differ from person to person and can change over time. Logging what you notice can make it easier to describe patterns at an appointment. Calendar estimates are useful guides, not guarantees.

WHEN TO GET SUPPORT
Very heavy bleeding, sudden or severe pain, fainting, bleeding in pregnancy, or symptoms that disrupt daily life deserve medical attention. This guide is for education, not diagnosis.''',
  ),
  HealthArticle(
    title: 'Period care and symptoms worth noticing',
    summary:
        'Understand common changes, gentle comfort ideas, and when to speak with a clinician.',
    category: 'Periods',
    sourceOrganization: 'NHS',
    sourceUrl: 'https://www.nhs.uk/conditions/periods/',
    body: '''WHAT CAN BE COMMON
Cramping, bloating, breast tenderness, tiredness, headaches and mood changes can happen before or during a period. Their intensity and timing can vary. Gentle movement, rest, heat and hydration can be comfort measures for some people, but they do not diagnose or treat an underlying cause.

TRACK THE DETAILS THAT HELP
If you choose to track, note when bleeding begins, how long it lasts, what the flow is like, where pain occurs, and what affects your day. This can be more useful than trying to decide alone whether a symptom is “normal.”

WHEN TO REACH OUT
Seek urgent care for severe or sudden pelvic pain, fainting, or very heavy bleeding. Arrange clinical advice for new, worsening, very painful, irregular, or disruptive periods.''',
  ),
  HealthArticle(
    title: 'Ovulation without the myths',
    summary:
        'What ovulation is, why its timing varies, and why apps only estimate it.',
    category: 'Ovulation',
    sourceOrganization: 'ACOG',
    sourceUrl:
        'https://www.acog.org/womens-health/infographics/the-menstrual-cycle',
    body: '''WHAT OVULATION MEANS
Ovulation is when an ovary releases an egg. It happens as part of the menstrual cycle, but the exact day can vary between people and between cycles. Not every cycle includes ovulation.

ESTIMATES ARE NOT CONFIRMATION
An app can estimate a possible ovulation window from previous cycle information. It cannot confirm that ovulation happened. Changes in cervical mucus or other body signs may be useful to notice, but they are not a diagnosis and can have more than one explanation.

KEEP IT IN CONTEXT
Do not rely on predicted ovulation alone to avoid pregnancy. If you have concerns about irregular cycles, pain around ovulation, or fertility, a qualified clinician can help you explore them.''',
  ),
  HealthArticle(
    title: 'The fertile window',
    summary:
        'A practical explanation of timing, uncertainty, and the limits of prediction.',
    category: 'Fertility',
    sourceOrganization: 'NHS',
    sourceUrl:
        'https://www.nhs.uk/conditions/periods/fertility-in-the-menstrual-cycle/',
    body: '''THE TIMING IDEA
Pregnancy can occur when sperm fertilises an egg. Sperm may survive in the reproductive tract for several days, while an egg is available for a much shorter time after ovulation. That is why the fertile window includes days before ovulation, not only one calendar date.

WHY THE WINDOW MOVES
Ovulation often occurs roughly 10 to 16 days before the next period, but this is not the same as “day 14” for everyone. Stress, illness, travel, changes in routine and ordinary cycle variation can all make calendar predictions less precise.

USE TRACKING CAREFULLY
Tracking can support conversations and planning, but it cannot confirm fertility or prevent pregnancy. Use a reliable contraceptive method if avoiding pregnancy is important to you.''',
  ),
  HealthArticle(
    title: 'Trying to conceive: a calm starting point',
    summary:
        'What cycle tracking can offer and when it may help to ask for support.',
    category: 'Fertility',
    sourceOrganization: 'ACOG',
    sourceUrl:
        'https://www.acog.org/womens-health/experts-and-stories/the-latest/trying-to-get-pregnant-heres-when-to-have-sex',
    body: '''START WITH INFORMATION, NOT PRESSURE
If you are trying to conceive, tracking periods and body changes can help you understand your usual pattern. It does not tell the whole story: conception depends on many factors for all partners, and a prediction app cannot diagnose fertility.

MAKE SPACE FOR QUESTIONS
You may want to discuss cycle regularity, medications, past pregnancies, health conditions, family history, vaccinations, and any concerns about sexually transmitted infections with a healthcare professional. Bring your questions and any notes you have chosen to keep.

WHEN SUPPORT MAKES SENSE
If you are worried about fertility, have very irregular periods, or have been trying without the result you hoped for, a clinician can advise on an appropriate next step for your situation.''',
  ),
  HealthArticle(
    title: 'Your reproductive body: a simple map',
    summary:
        'Meet the vulva, vagina, cervix, uterus, fallopian tubes and ovaries without jargon.',
    category: 'Your body',
    sourceOrganization: 'ACOG',
    sourceUrl:
        'https://www.acog.org/womens-health/infographics/female-reproductive-system',
    body: '''THE OUTSIDE AND THE INSIDE
The vulva is the collective name for the external genital structures. The vagina is an internal canal. The cervix is the lower opening of the uterus, and the uterus is the muscular organ where a pregnancy can grow.

OVARIES AND TUBES
The ovaries contain eggs and make hormones. During ovulation, an egg is released from an ovary. The fallopian tubes connect the area near the ovaries to the uterus and are involved in the path an egg may take.

LANGUAGE CAN HELP
Knowing the names for body parts can make it easier to understand health information, describe a concern, ask questions, and make informed choices. Bodies vary; this is a general anatomical overview.''',
  ),
  HealthArticle(
    title: 'Pregnancy: the first steps',
    summary:
        'A grounding overview of pregnancy, prenatal care and questions to bring along.',
    category: 'Pregnancy',
    sourceOrganization: 'ACOG',
    sourceUrl: 'https://www.acog.org/womens-health/faqs/prenatal-care',
    body: '''A POSITIVE TEST IS A STARTING POINT
If you think you may be pregnant, a pregnancy test and timely contact with a qualified prenatal-care professional can help you plan the next steps. Care is individual and may include health history, screening, information, and support.

PREPARE FOR YOUR FIRST VISIT
It can help to note the first day of your last period, medications and supplements, existing health conditions, vaccination history, and questions you want answered. Do not start, stop or change prescribed medication without professional advice.

GET URGENT HELP WHEN NEEDED
Seek urgent medical care for heavy bleeding, severe or one-sided abdominal pain, fainting, chest pain, trouble breathing, or any pregnancy symptom that feels urgent or alarming.''',
  ),
  HealthArticle(
    title: 'Pregnancy changes, trimester by trimester',
    summary:
        'A high-level guide to changing stages of pregnancy and regular care.',
    category: 'Pregnancy',
    sourceOrganization: 'ACOG',
    sourceUrl:
        'https://www.acog.org/womens-health/faqs/how-your-fetus-grows-during-pregnancy',
    body: '''THREE CHAPTERS, NOT THREE RULES
Pregnancy is often described in three trimesters. Each stage can bring different physical changes, questions and appointments, but experiences vary widely. Due dates and weekly milestones are estimates, not exact deadlines.

WHY PRENATAL CARE MATTERS
Prenatal visits give you time to discuss symptoms, screening, wellbeing, medications, work, relationships and practical support. Your care schedule may be tailored to your health history and pregnancy needs.

STAY CONNECTED TO CARE
Use this app to organise questions and notes, not to assess the health of a pregnancy. Contact your maternity team or local urgent services when you are worried about a symptom.''',
  ),
  HealthArticle(
    title: 'Food safety in pregnancy',
    summary:
        'General food-safety principles and why local pregnancy guidance matters.',
    category: 'Pregnancy',
    sourceOrganization: 'NHS',
    sourceUrl: 'https://www.nhs.uk/pregnancy/keeping-well/foods-to-avoid/',
    body: '''THE PRACTICAL PRINCIPLE
Pregnancy food advice focuses on reducing the risk of food-borne illness and avoiding substances that may be harmful in pregnancy. Local public-health guidance is the best source because recommendations can differ by country and can change.

KEEP QUESTIONS SPECIFIC
If you are unsure about a particular food, drink, supplement, allergy, cultural dish or dietary need, ask your midwife, doctor, dietitian, or local pregnancy service. Do not use a general guide to replace individual nutrition care.

FOOD IS NOT A TREATMENT
Balanced meals can support day-to-day wellbeing, but they do not diagnose, prevent or treat pregnancy complications. Seek medical advice for severe nausea, dehydration, persistent vomiting, or other concerning symptoms.''',
  ),
];

class LearnPage extends StatefulWidget {
  const LearnPage({super.key});

  @override
  State<LearnPage> createState() => _LearnPageState();
}

class _LearnPageState extends State<LearnPage> {
  String _selectedTopic = _topics.first;

  @override
  Widget build(BuildContext context) {
    final visible = _selectedTopic == _topics.first
        ? articles
        : articles
              .where((article) => article.category == _selectedTopic)
              .toList();
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.lg,
            AppSpace.lg,
            AppSpace.lg,
            112,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text(
                'Your reading room',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Clear, source-led guides for every chapter of your health.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpace.lg),
              const _LibraryWelcomeCard(),
              const SizedBox(height: AppSpace.lg),
              Material(
                color: Colors.transparent,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _topics
                        .map(
                          (topic) => Padding(
                            padding: const EdgeInsets.only(right: AppSpace.xs),
                            child: ChoiceChip(
                              label: Text(topic),
                              selected: _selectedTopic == topic,
                              onSelected: (_) =>
                                  setState(() => _selectedTopic = topic),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              Text(
                _selectedTopic == _topics.first
                    ? 'Choose a guide'
                    : '$_selectedTopic guides',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpace.sm),
              ...visible.map(
                (article) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.sm),
                  child: _BookTile(article: article),
                ),
              ),
              const SizedBox(height: AppSpace.xs),
              Text(
                'These guides offer general education, not diagnosis, treatment, or emergency care.',
                style: Theme.of(context).textTheme.labelSmall,
                textAlign: TextAlign.center,
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _LibraryWelcomeCard extends StatelessWidget {
  const _LibraryWelcomeCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpace.md),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          AppColors.lavender.withValues(alpha: .42),
          AppColors.rose.withValues(alpha: .28),
        ],
      ),
      borderRadius: BorderRadius.circular(AppRadius.large),
      border: Border.all(color: AppColors.line),
    ),
    child: Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: const BoxDecoration(
            color: AppColors.plum,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.auto_stories_rounded, color: Colors.white),
        ),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A library for your questions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Read at your pace, return whenever you need, and take what is useful.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.ink.withValues(alpha: .72),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _BookTile extends StatelessWidget {
  const _BookTile({required this.article});

  final HealthArticle article;

  @override
  Widget build(BuildContext context) {
    final color = _coverColor(article.category);
    return SurfaceCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => _ArticlePage(article: article)),
      ),
      padding: const EdgeInsets.all(AppSpace.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 66,
            height: 112,
            padding: const EdgeInsets.all(AppSpace.xs),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.menu_book_rounded,
                  color: Colors.white,
                  size: 21,
                ),
                const Spacer(),
                Text(
                  article.category.toUpperCase(),
                  maxLines: 2,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    letterSpacing: .7,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  article.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  'READ GUIDE · ${article.sourceOrganization.toUpperCase()}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.berry,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.xs),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ],
      ),
    );
  }
}

class _ArticlePage extends StatelessWidget {
  const _ArticlePage({required this.article});

  final HealthArticle article;

  @override
  Widget build(BuildContext context) {
    final paragraphs = article.body.split('\n\n');
    return Scaffold(
      appBar: AppBar(surfaceTintColor: Colors.transparent),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.lg,
            AppSpace.sm,
            AppSpace.lg,
            AppSpace.xxl,
          ),
          children: [
            _ArticleCover(article: article),
            const SizedBox(height: AppSpace.xl),
            ...paragraphs.map(
              (paragraph) => _ArticleParagraph(paragraph: paragraph),
            ),
            const SizedBox(height: AppSpace.lg),
            SurfaceCard(
              color: AppColors.lavender.withValues(alpha: .14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NAMED SOURCE',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    article.sourceOrganization,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Use the named source and a qualified healthcare professional for personalised guidance.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArticleCover extends StatelessWidget {
  const _ArticleCover({required this.article});

  final HealthArticle article;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpace.lg),
    decoration: BoxDecoration(
      color: _coverColor(article.category),
      borderRadius: BorderRadius.circular(AppRadius.large),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.menu_book_rounded, color: Colors.white, size: 29),
        const SizedBox(height: AppSpace.xl),
        Text(
          article.category.toUpperCase(),
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          article.title,
          style: Theme.of(
            context,
          ).textTheme.headlineLarge?.copyWith(color: Colors.white),
        ),
      ],
    ),
  );
}

class _ArticleParagraph extends StatelessWidget {
  const _ArticleParagraph({required this.paragraph});

  final String paragraph;

  @override
  Widget build(BuildContext context) {
    final lines = paragraph.split('\n');
    final heading = lines.first;
    final copy = lines.skip(1).join(' ').trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: AppColors.berry),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(copy, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

Color _coverColor(String category) => switch (category) {
  'Periods' => AppColors.berry,
  'Ovulation' => AppColors.fertility,
  'Fertility' => AppColors.pregnancy,
  'Your body' => AppColors.plum,
  'Pregnancy' => const Color(0xFFB46987),
  _ => AppColors.plum,
};
