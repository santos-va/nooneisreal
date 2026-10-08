class_name NpcConversationContext
extends RefCounted
## Authored facts only. Saved free text is deliberately excluded from model context.
const VOICES: Array[String] = ["турботлива", "дотепний", "уважна", "неквапний", "мрійлива", "енергійна", "стриманий", "допитлива", "практичний", "поетична", "товариський", "спостережлива"]
const DETAILS: Array[String] = ["Люблю, коли сусіди заходять просто привітатися.", "Добрий шов помітний менше, ніж поганий жарт.", "Спершу перевіряю дрібниці — тоді велика справа йде легше.", "Не поспішаю: район краще чути, коли йдеш поволі.", "З мосту дахи схожі на хвилі.", "Мій улюблений звук — кроки на ринковій площі.", "На верхній вулиці менше метушні.", "Щоразу помічаю тут нову дрібницю.", "Перед дорогою варто оглянути спорядження.", "Вечірнє світло найкраще лягає на годинникову вежу.", "У кожного тут є своя історія.", "Іноді досить зупинитися, щоб помітити щось цікаве."]
const OBSERVATIONS: Array[String] = ["Біля крамниць найчастіше зустрінеш тих, хто поспішає додому.", "Вивіски на заході я впізнаю за кольором, ще не читаючи літер.", "Міст нагорі для мене — зручний спосіб оглянути проходи.", "На рампі люблю дивитися, як поступово зникає площа внизу.", "Мені подобається лінія дахів біля вежі.", "До ринку люблю йти довшим шляхом, повз знайомі обличчя.", "Біля верхнього мосту завжди знаходжу привід сповільнитися.", "Порахуй вивіски, коли підеш повз крамниці: кожна має свій характер.", "Рампа — мій вибір, коли треба дістатися нагору без поспіху.", "Тінь вежі щоразу малює інший візерунок.", "На ринку легше почати розмову, ніж закінчити її.", "Між будинками я люблю шукати вид на небо."]
## Lines that carry a quest or a price: «Заплутаність» never fades them (T4 audit of 31caa4c, T1 2026-10-08).
const QUEST_READY_LINE := "Здається, одне з твоїх доручень уже можна завершити."
const PRICE_LINES: Array[String] = ["М’ятну можна приміряти без жетонів."]
var turns: Dictionary = {}


static func never_fade() -> PackedStringArray:
	var lines := PackedStringArray([QUEST_READY_LINE])
	lines.append_array(PRICE_LINES)
	return lines

func facts(population: NpcPopulation, index: int, hero: String, progress: CityProgress, topic: String) -> Dictionary:
	var person: Dictionary = population.people[index]
	var bond: Dictionary = population.relationship(index, hero)
	var quests: Dictionary = {}
	if progress != null:
		for q: Dictionary in progress.quests:
			quests[str(q.id)] = progress.quest_status(q.id)
	var topics: Array[String] = []
	for known: String in ["introduction", "topic_work", "topic_district", "topic_route", "topic_neighbours", "parcel"]:
		if known in bond.topics:
			topics.append(known)
	return {"resident": str(person.id), "name": str(person.name), "voice": VOICES[index % VOICES.size()], "hero": hero, "job": ["grocer", "tailor", "workshop"][index] if index < 3 else str(person.role), "trust": int(bond.trust), "meetings": int(bond.meetings), "topics": topics, "quests": quests, "topic": topic}

func reply(context: Dictionary, index: int) -> String:
	var key: String = str(context.hero) + ":" + str(context.resident) + ":" + str(context.topic)
	var turn: int = int(turns.get(key, 0))
	turns[key] = turn + 1
	var lines: Array[String] = []
	match str(context.topic):
		"work":
			var job: String = {"grocer": "Тримаю припаси для сусідів і збираю доручення.", "tailor": "Підбираю кольори перев’язей. М’ятну можна приміряти без жетонів.", "workshop": "Перевіряю спорядження та міські проходи."}.get(context.job, "Моя справа — " + str(context.job) + ". Між справами гуляю районом.")
			lines = [job + " " + DETAILS[index], DETAILS[index] + " " + job, "Роботи вистачає, та для розмови хвилина знайдеться. " + job + " " + OBSERVATIONS[index]]
		"district":
			lines = ["На півночі — міст дахів і годинникова вежа. До них ведуть рампи.", "Ринкову площу шукай на півдні. Люблю дивитися, як там зустрічаються сусіди.", "Західні крамниці мають окремі вивіски. До працівника можна підійти збоку прилавка."]
		"route":
			lines = ["Ти вже пройшов верхній маршрут. З мосту район зовсім інший, правда?", "Після прогулянки дахами вежу помічаєш навіть знизу.", "Тепер ми обоє знаємо дорогу нагору. " + DETAILS[index]]
		"neighbours":
			lines = ["Ти вже познайомився з нашими сусідами. Район стає ближчим через людей.", "Приємно мати спільних знайомих. Заходь і без доручення.", "Тут тебе вже впізнають. " + DETAILS[index]]
		_:
			var welcome: String = "Приємно познайомитися, " if int(context.meetings) <= 1 else ("Як добре бачити друга, " if int(context.trust) >= 6 else "Знову вітаю, ")
			lines = [welcome + str(context.hero).capitalize() + ". " + DETAILS[index], welcome + str(context.hero).capitalize() + ". Як твоя прогулянка? " + OBSERVATIONS[index], welcome + str(context.hero).capitalize() + ". Знайдеться хвилина перекинутися словами? " + DETAILS[index]]
	var result: String = lines[(turn + index) % lines.size()]
	if str(context.topic) in ["district", "route", "neighbours"]:
		result += " " + OBSERVATIONS[index]
	if str(context.topic) == "greeting":
		for status: String in context.quests.values():
			if status == "ready":
				result += " " + QUEST_READY_LINE
				break
	return result
