import '../models/enums.dart';
import '../models/topic.dart';

/// Демонстрациялық тақырыптар каталогы. Барлық мәтін — синтетикалық үлгі.
const mockTopics = <Topic>[
  // Mobile
  Topic(
    id: 'dart-basics',
    title: 'Dart негіздері',
    summary: 'Типтер, null safety, коллекциялар',
    direction: Direction.mobile,
    description: 'Типтер мен null safety ережелерін мысалдармен қайталаңыз.',
    reviewPoints: [
      'Типтер және nullable мәндер',
      'Коллекциялар және generics',
      'Қате мен exception',
    ],
    sampleQuestion: 'Null safety қандай қатені алдын ала табуға көмектеседі?',
  ),
  Topic(
    id: 'flutter-widgets',
    title: 'Flutter виджеттері',
    summary: 'Құрылым, күй және өмірлік цикл',
    direction: Direction.mobile,
    description:
        'Интерфейсті қалай құратынымызды және күй өзгергенде не '
        'болатынын мысалмен түсіндіріп үйреніңіз.',
    reviewPoints: [
      'StatelessWidget және StatefulWidget',
      'State нысанының өмірлік циклі',
      'setState() және қайта құру',
    ],
    sampleQuestion: 'Күй өзгергенде Flutter интерфейсті қалай жаңартады?',
  ),
  Topic(
    id: 'state-management',
    title: 'Күйді басқару',
    summary: 'Оқиға, күй және жаңарту',
    direction: Direction.mobile,
    description:
        'Күйдің қайда сақталатынын және қалай жаңаратынын түсіндіріңіз.',
    reviewPoints: [
      'Жергілікті және ортақ күй',
      'Күй өзгерісінің өмірлік циклі',
      'UI мен деректердің бөлінуі',
    ],
    sampleQuestion: 'Күйді виджеттен бөлек басқару қашан қажет?',
  ),
  Topic(
    id: 'async',
    title: 'Асинхрондылық',
    summary: 'Future, Stream, async / await',
    direction: Direction.mobile,
    description: 'Күту уақытын интерфейсті бұғаттамай ұйымдастырыңыз.',
    reviewPoints: ['Future және Stream', 'async / await', 'Қателерді өңдеу'],
    sampleQuestion: 'Future мен Stream арасындағы айырма қандай?',
  ),

  // Frontend
  Topic(
    id: 'html-css',
    title: 'HTML және CSS',
    summary: 'Семантика, Flexbox, Grid',
    direction: Direction.frontend,
    description: 'Беттің құрылымын және орналасуын түсінікті етіп құрыңыз.',
    reviewPoints: [
      'Семантикалық тегтер',
      'Flexbox және Grid',
      'Бейімделгіш орналасу',
    ],
    sampleQuestion: 'Flexbox пен Grid-ті қай кезде таңдайсыз?',
  ),
  Topic(
    id: 'javascript',
    title: 'JavaScript негіздері',
    summary: 'Closure, this, оқиғалар',
    direction: Direction.frontend,
    description: 'Тілдің негізгі механизмдерін мысалдармен түсіндіріңіз.',
    reviewPoints: ['Closure', 'this кілт сөзі', 'Event loop'],
    sampleQuestion: 'Closure дегеніміз не және ол қай жерде пайдалы?',
  ),
  Topic(
    id: 'react',
    title: 'React',
    summary: 'Компоненттер, props, hooks',
    direction: Direction.frontend,
    description: 'Компоненттік тәсіл мен күйді басқаруды қайталаңыз.',
    reviewPoints: ['Props пен state', 'useEffect', 'Тізім кілттері'],
    sampleQuestion: 'Props пен state айырмашылығы неде?',
  ),

  // Backend
  Topic(
    id: 'http-rest',
    title: 'HTTP және REST',
    summary: 'Әдістер, статус кодтары, идемпотенттік',
    direction: Direction.backend,
    description: 'Клиент пен сервер арасындағы келісімді түсіндіріңіз.',
    reviewPoints: ['HTTP әдістері', 'Статус кодтары', 'Идемпотенттік'],
    sampleQuestion: 'PUT пен PATCH әдістерінің айырмашылығы неде?',
  ),
  Topic(
    id: 'sql',
    title: 'SQL және дерекқорлар',
    summary: 'JOIN, индекс, транзакция',
    direction: Direction.backend,
    description: 'Деректерді сақтау мен сұраулардың тиімділігін қайталаңыз.',
    reviewPoints: ['JOIN түрлері', 'Индекстер', 'Транзакция және ACID'],
    sampleQuestion: 'Индекс сұрауды қалай жылдамдатады?',
  ),
  Topic(
    id: 'auth',
    title: 'Аутентификация',
    summary: 'Сессия, JWT, хэштеу',
    direction: Direction.backend,
    description: 'Пайдаланушыны қауіпсіз тануды түсіндіріңіз.',
    reviewPoints: ['Аутентификация мен авторизация', 'JWT', 'Парольді хэштеу'],
    sampleQuestion: 'Парольді неге ашық түрде сақтауға болмайды?',
  ),

  // QA
  Topic(
    id: 'test-types',
    title: 'Тестілеу түрлері',
    summary: 'Unit, интеграциялық, регрессия',
    direction: Direction.qa,
    description: 'Тест деңгейлері мен олардың мақсатын қайталаңыз.',
    reviewPoints: [
      'Unit және интеграциялық тест',
      'Регрессиялық тест',
      'Smoke тест',
    ],
    sampleQuestion: 'Регрессиялық тест не үшін қажет?',
  ),
  Topic(
    id: 'bug-report',
    title: 'Баг есебі',
    summary: 'Қадамдар, нәтиже, басымдық',
    direction: Direction.qa,
    description: 'Әзірлеушіге түсінікті ақау есебін құрастырыңыз.',
    reviewPoints: [
      'Қайталау қадамдары',
      'Күтілетін және нақты нәтиже',
      'Severity мен priority',
    ],
    sampleQuestion: 'Жақсы баг есебінде қандай бөлімдер болуы керек?',
  ),
  Topic(
    id: 'automation',
    title: 'Тест автоматтандыру',
    summary: 'Пирамида, тұрақты тест, CI',
    direction: Direction.qa,
    description: 'Қай тестті автоматтандыру керегін негіздеңіз.',
    reviewPoints: ['Тест пирамидасы', 'Тұрақсыз тесттер', 'CI ішінде тест'],
    sampleQuestion: 'Тест пирамидасы нені білдіреді?',
  ),
];
