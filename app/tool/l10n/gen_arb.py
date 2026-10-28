#!/usr/bin/env python3
"""ARB файлдарын (kk, ru) және S фасадын жасайды.

Жаңа мәтін қосу: tool/l10n/kk.json мен ru.json-ға бір кілт қосып (параметрлісі
болса — FUNCS тізіміне), содан кейін app/ бумасынан:
  python3 tool/l10n/gen_arb.py && flutter gen-l10n
"""
import json
from pathlib import Path

APP = Path(__file__).resolve().parents[2]
kk_consts = json.loads((APP / 'tool/l10n/kk.json').read_text())
ru_consts = json.loads((APP / 'tool/l10n/ru.json').read_text())
missing = set(kk_consts) - set(ru_consts)
assert not missing, f'ru.json-та аударма жоқ: {sorted(missing)}'


def plural_ru(var, one, few, many):
    return f'{{{var}, plural, one{{{one}}} few{{{few}}} many{{{many}}} other{{{few}}}}}'


# (атауы, [(параметр, тип)], kk, ru)
FUNCS = [
    ('fieldRequired', [('field', 'String')], '{field} толтырылуы керек.', 'Заполните поле «{field}».'),
    ('answerTooLong', [('max', 'int')], 'Жауап {max} таңбадан аспауы керек.', 'Ответ не должен превышать {max} символов.'),
    ('greeting', [('name', 'String')], 'Сәлем, {name}!', 'Привет, {name}!'),
    ('directionTopics', [('direction', 'String')], '{direction} тақырыптары', 'Темы {direction}'),
    ('continueWithTopics', [('n', 'int')], 'Жалғастыру · {n} тақырып',
     plural_ru('n', 'Продолжить · {n} тема', 'Продолжить · {n} темы', 'Продолжить · {n} тем')),
    ('questionsCount', [('n', 'int')], '{n} сұрақ',
     plural_ru('n', '{n} вопрос', '{n} вопроса', '{n} вопросов')),
    ('progressOf', [('current', 'int'), ('total', 'int')], '{current} / {total} сұрақ', 'Вопрос {current} из {total}'),
    ('feedbackHeader', [('n', 'int'), ('total', 'int')], '{n} / {total} · Жауап талдауы', '{n} / {total} · Разбор ответа'),
    ('disputeSubtitle', [('n', 'int'), ('topic', 'String')], '{n}-сұрақ · {topic}', 'Вопрос {n} · {topic}'),
    ('summaryCounts', [('answered', 'int'), ('skipped', 'int'), ('assessed', 'int')],
     '{answered} жауап · {skipped} өткізу · {assessed} бағаланды',
     'Ответов: {answered} · пропусков: {skipped} · оценено: {assessed}'),
    ('summaryFormula', [('earned', 'int'), ('max', 'int'), ('score', 'String')],
     'Нәтиже: {earned} / {max} × 100 = {score}.', 'Результат: {earned} / {max} × 100 = {score}.'),
    ('incompleteCounts', [('answered', 'int'), ('skipped', 'int'), ('assessed', 'int'), ('pending', 'int')],
     '{answered} жауап · {skipped} өткізу\n{assessed} бағаланды · {pending} бағалау күтілуде',
     'Ответов: {answered} · пропусков: {skipped}\nОценено: {assessed} · ждут оценки: {pending}'),
    ('recommendScore', [('score', 'String')], '{score} / 100 · Осы сессияда', '{score} / 100 · В этой сессии'),
    ('whyLowest', [('n', 'int')], '{n} жауаптағы ең төмен балл осы тақырыпта.',
     'Самый низкий балл — по этой теме (ответов: {n}).'),
    ('whyMissing', [('n', 'int'), ('missing', 'String')], '{n} жауапта толық ашылмаған: {missing}.',
     'Не раскрыто полностью (ответов: {n}): {missing}.'),
    ('filters', [('n', 'int')], 'Сүзгілер · {n}', 'Фильтры · {n}'),
    ('assessedPoints', [('total', 'int')], 'Бағаланды · {total} / 15', 'Оценено · {total} / 15'),
    ('savedAnswerHeader', [('n', 'int'), ('total', 'int')], '{n} / {total} · Сақталған жауап', '{n} / {total} · Сохранённый ответ'),
    ('lastSessions', [('n', 'int')], 'Соңғы {n} толық сессия',
     plural_ru('n', 'Последняя {n} полная сессия', 'Последние {n} полные сессии', 'Последние {n} полных сессий')),
    ('completeSessions', [('n', 'int')], '{n} толық сессия',
     plural_ru('n', '{n} полная сессия', '{n} полные сессии', '{n} полных сессий')),
    ('averageScore', [('score', 'String')], 'Орташа балл: {score}', 'Средний балл: {score}'),
    ('catalogSubtitle', [('direction', 'String')], '{direction} · Дайындық кітапханасы', '{direction} · Библиотека подготовки'),
    ('found', [('n', 'int')], '{n} тақырып табылды',
     plural_ru('n', 'Найдена {n} тема', 'Найдено {n} темы', 'Найдено {n} тем')),
    ('averageShort', [('score', 'String')], 'орт. {score}', 'ср. {score}'),
    ('topicCount', [('n', 'int')], '{n} тақырып', plural_ru('n', '{n} тема', '{n} темы', '{n} тем')),
    ('questionN', [('n', 'int')], '{n}-сұрақ', 'Вопрос {n}'),
]

# Енумдар мен форматтарға арналған қосымша жолдар.
EXTRA = {
    'levelBeginner': ('Бастапқы', 'Начальный'),
    'levelJunior': ('Junior', 'Junior'),
    'levelMiddle': ('Middle', 'Middle'),
    'sortTitleAsc': ('Атауы: А–Я', 'Название: А–Я'),
    'sortTitleDesc': ('Атауы: Я–А', 'Название: Я–А'),
    'sortNewest': ('Жаңасы алдымен', 'Сначала новые'),
    'sortWeakest': ('Әлсізі алдымен', 'Сначала слабые'),
    'historyNewest': ('Жаңасы алдымен', 'Сначала новые'),
    'historyOldest': ('Ескісі алдымен', 'Сначала старые'),
    'historyScoreHigh': ('Балы: жоғарыдан', 'Балл: по убыванию'),
    'historyScoreLow': ('Балы: төменнен', 'Балл: по возрастанию'),
}
months_kk = ['қаңтар', 'ақпан', 'наурыз', 'сәуір', 'мамыр', 'маусым', 'шілде', 'тамыз', 'қыркүйек', 'қазан', 'қараша', 'желтоқсан']
months_ru = ['января', 'февраля', 'марта', 'апреля', 'мая', 'июня', 'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря']
wd_short_kk = ['Дс', 'Сс', 'Ср', 'Бс', 'Жм', 'Сб', 'Жс']
wd_short_ru = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс']
wd_full_kk = ['Дүйсенбі', 'Сейсенбі', 'Сәрсенбі', 'Бейсенбі', 'Жұма', 'Сенбі', 'Жексенбі']
wd_full_ru = ['Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота', 'Воскресенье']
for i in range(12):
    EXTRA[f'month{i + 1}'] = (months_kk[i], months_ru[i])
for i in range(7):
    EXTRA[f'weekdayShort{i + 1}'] = (wd_short_kk[i], wd_short_ru[i])
    EXTRA[f'weekdayFull{i + 1}'] = (wd_full_kk[i], wd_full_ru[i])

arb = {'kk': {'@@locale': 'kk'}, 'ru': {'@@locale': 'ru'}}
for k, v in kk_consts.items():
    arb['kk'][k] = v
    arb['ru'][k] = ru_consts[k]
for k, (kk, ru) in EXTRA.items():
    arb['kk'][k], arb['ru'][k] = kk, ru
for name, params, kk, ru in FUNCS:
    arb['kk'][name] = kk
    arb['kk']['@' + name] = {'placeholders': {p: {'type': t} for p, t in params}}
    arb['ru'][name] = ru

out = APP / 'lib/l10n'
out.mkdir(exist_ok=True)
for loc, data in arb.items():
    (out / f'app_{loc}.arb').write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')

# S фасады: статикалық қолжетімділік, тіл ауысқанда S.use(locale).
lines = [
    '// GENERATED by tool/l10n/gen_arb.py — қолмен өзгертпеңіз.',
    '// Мәтіндерді lib/l10n/app_*.arb файлдарында өзгертіңіз.',
    "import 'package:flutter/widgets.dart';",
    '',
    "import '../../l10n/gen/app_localizations.dart';",
    '',
    '/// Интерфейстің барлық мәтіні. Ағымдағы тіл [use] арқылы ауысады;',
    '/// мәтіндер AppLocalizations (flutter gen-l10n) ішінен алынады.',
    'abstract final class S {',
    "  static AppLocalizations _l = lookupAppLocalizations(const Locale('kk'));",
    '',
    '  static Locale get locale => Locale(_l.localeName);',
    '',
    '  static void use(Locale locale) => _l = lookupAppLocalizations(locale);',
    '',
]
for k in list(kk_consts) + list(EXTRA):
    lines.append(f'  static String get {k} => _l.{k};')
lines.append('')
for name, params, _, _ in FUNCS:
    sig = ', '.join(f'{t} {p}' for p, t in params)
    call = ', '.join(p for p, _ in params)
    lines.append(f'  static String {name}({sig}) => _l.{name}({call});')
lines.append('}')
(APP / 'lib/core/constants/app_strings.dart').write_text('\n'.join(lines) + '\n')
print(f'kk/ru: {len(kk_consts) + len(EXTRA) + len(FUNCS)} жол')
