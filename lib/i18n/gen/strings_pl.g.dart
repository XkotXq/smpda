///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsPl = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.pl,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <pl>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	/// Access flat map
	dynamic operator[](String key) => _meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations
	late final Translations$login$pl login = Translations$login$pl._(_root);
	late final Translations$settings$pl settings = Translations$settings$pl._(_root);
	late final Translations$nav$pl nav = Translations$nav$pl._(_root);
	late final Translations$operations$pl operations = Translations$operations$pl._(_root);
	late final Translations$dashboard$pl dashboard = Translations$dashboard$pl._(_root);
	late final Translations$frp$pl frp = Translations$frp$pl._(_root);
	late final Translations$history$pl history = Translations$history$pl._(_root);
}

// Path: login
class Translations$login$pl {
	Translations$login$pl._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// pl: 'Login'
	String get username => 'Login';

	/// pl: 'Hasło'
	String get password => 'Hasło';

	/// pl: 'Zaloguj'
	String get submit => 'Zaloguj';

	/// pl: 'Logowanie...'
	String get submitting => 'Logowanie...';

	late final Translations$login$errors$pl errors = Translations$login$errors$pl._(_root);
}

// Path: settings
class Translations$settings$pl {
	Translations$settings$pl._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// pl: 'Ustawienia'
	String get title => 'Ustawienia';

	/// pl: 'Zalogowano jako'
	String get loggedInAs => 'Zalogowano jako';

	/// pl: 'Wyloguj'
	String get logout => 'Wyloguj';

	/// pl: 'Adres wpsApi'
	String get apiUrl => 'Adres wpsApi';

	/// pl: 'Token API'
	String get apiToken => 'Token API';

	/// pl: 'Zapisz'
	String get save => 'Zapisz';

	/// pl: 'Język'
	String get language => 'Język';

	/// pl: 'Klawiatura ekranowa przy polach liczbowych'
	String get numericKeyboard => 'Klawiatura ekranowa przy polach liczbowych';

	/// pl: 'Wyłącz, jeśli wpisujesz ilości fizyczną klawiaturą skanera.'
	String get numericKeyboardHint => 'Wyłącz, jeśli wpisujesz ilości fizyczną klawiaturą skanera.';

	late final Translations$settings$theme$pl theme = Translations$settings$theme$pl._(_root);
}

// Path: nav
class Translations$nav$pl {
	Translations$nav$pl._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// pl: 'Wstecz'
	String get back => 'Wstecz';
}

// Path: operations
class Translations$operations$pl {
	Translations$operations$pl._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// pl: 'Przyjęcie'
	String get modeReceive => 'Przyjęcie';

	/// pl: 'Wydanie'
	String get modeIssue => 'Wydanie';

	/// pl: 'Zeskanuj lub wpisz kod'
	String get scanPlaceholder => 'Zeskanuj lub wpisz kod';

	/// pl: 'Lokalizacja'
	String get location => 'Lokalizacja';

	/// pl: 'Materiał'
	String get material => 'Materiał';

	/// pl: 'Na stanie'
	String get onStock => 'Na stanie';

	/// pl: 'Ilość wydania'
	String get issueQuantity => 'Ilość wydania';

	/// pl: 'Wybierz numer szpuli'
	String get pickSpool => 'Wybierz numer szpuli';

	/// pl: 'Brak numeru szpuli'
	String get noSpoolNumber => 'Brak numeru szpuli';

	/// pl: 'bez nr szpuli'
	String get noSpoolTag => 'bez nr szpuli';

	/// pl: 'Szpula'
	String get unitLabel => 'Szpula';

	/// pl: 'Numer szpuli'
	String get unitOptional => 'Numer szpuli';

	/// pl: 'Ilość'
	String get quantityLabel => 'Ilość';

	/// pl: 'Dostępne: {value}'
	String available({required Object value}) => 'Dostępne: ${value}';

	/// pl: 'Zatwierdź'
	String get confirm => 'Zatwierdź';

	/// pl: 'Anuluj'
	String get cancel => 'Anuluj';

	/// pl: 'Zapisywanie...'
	String get submitting => 'Zapisywanie...';

	/// pl: 'Zapisano.'
	String get submitted => 'Zapisano.';

	/// pl: 'Wydano {name}.'
	String issued({required Object name}) => 'Wydano ${name}.';

	/// pl: 'Przyjęto {name}.'
	String received({required Object name}) => 'Przyjęto ${name}.';

	/// pl: 'Tego materiału nie ma już na stanie.'
	String get errorNotInStock => 'Tego materiału nie ma już na stanie.';

	/// pl: 'Ta szpula została już wydana.'
	String get errorUnitGone => 'Ta szpula została już wydana.';

	/// pl: 'Na stanie jest tylko {available}.'
	String errorNotEnough({required Object available}) => 'Na stanie jest tylko ${available}.';

	/// pl: 'Pobieranie stanu z serwera…'
	String get loadingStock => 'Pobieranie stanu z serwera…';

	/// pl: 'Nie udało się pobrać stanu z serwera.'
	String get toastLoadFailed => 'Nie udało się pobrać stanu z serwera.';

	/// pl: 'Nieznany kod - nie znaleziono materiału ani jednostki.'
	String get toastUnknown => 'Nieznany kod - nie znaleziono materiału ani jednostki.';

	/// pl: 'Brak dostępnej ilości tego materiału do wydania.'
	String get toastNotIssuable => 'Brak dostępnej ilości tego materiału do wydania.';

	/// pl: 'Pobieranie nazwy…'
	String get loadingName => 'Pobieranie nazwy…';
}

// Path: dashboard
class Translations$dashboard$pl {
	Translations$dashboard$pl._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// pl: 'Stock Manager'
	String get appTitle => 'Stock Manager';

	/// pl: 'Online'
	String get online => 'Online';

	/// pl: 'Offline'
	String get offline => 'Offline';

	/// pl: 'Moduły'
	String get modules => 'Moduły';

	/// pl: 'Konto'
	String get tabAccount => 'Konto';

	late final Translations$dashboard$account$pl account = Translations$dashboard$account$pl._(_root);
	late final Translations$dashboard$materialsSm$pl materialsSm = Translations$dashboard$materialsSm$pl._(_root);
	late final Translations$dashboard$frp$pl frp = Translations$dashboard$frp$pl._(_root);
}

// Path: frp
class Translations$frp$pl {
	Translations$frp$pl._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// pl: 'Do oznaczenia numerem szpuli'
	String get listTitle => 'Do oznaczenia numerem szpuli';

	/// pl: 'Brak FRP bez numeru szpuli.'
	String get listEmpty => 'Brak FRP bez numeru szpuli.';

	/// pl: 'Spróbuj ponownie'
	String get retry => 'Spróbuj ponownie';

	/// pl: 'Ten FRP nie ma ilości bez numeru szpuli.'
	String get toastNotPending => 'Ten FRP nie ma ilości bez numeru szpuli.';

	/// pl: 'Oznaczenie szpuli'
	String get labelTitle => 'Oznaczenie szpuli';

	/// pl: 'Do oznaczenia'
	String get toLabel => 'Do oznaczenia';

	/// pl: 'Batch'
	String get batch => 'Batch';

	/// pl: 'Numer szpuli'
	String get spoolNumber => 'Numer szpuli';

	/// pl: 'Długość'
	String get length => 'Długość';

	/// pl: 'Oznaczono {name}: {unitId}.'
	String labeled({required Object name, required Object unitId}) => 'Oznaczono ${name}: ${unitId}.';

	/// pl: 'Numer {taken} został już zajęty - nowy numer: {next}.'
	String numberTaken({required Object taken, required Object next}) => 'Numer ${taken} został już zajęty - nowy numer: ${next}.';
}

// Path: history
class Translations$history$pl {
	Translations$history$pl._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// pl: 'Moje wydania'
	String get issuesTitle => 'Moje wydania';

	/// pl: 'Moje oznaczenia'
	String get labelingsTitle => 'Moje oznaczenia';

	/// pl: 'Numer pracownika'
	String get employee => 'Numer pracownika';

	/// pl: 'Brak wpisów.'
	String get empty => 'Brak wpisów.';

	/// pl: 'Odśwież'
	String get refresh => 'Odśwież';
}

// Path: login.errors
class Translations$login$errors$pl {
	Translations$login$errors$pl._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// pl: 'Nieprawidłowy login lub hasło.'
	String get invalidCredentials => 'Nieprawidłowy login lub hasło.';

	/// pl: 'Nie udało się połączyć z systemem CIP.'
	String get cipUnreachable => 'Nie udało się połączyć z systemem CIP.';

	/// pl: 'Zbyt wiele prób logowania. Spróbuj ponownie za kilka minut.'
	String get tooManyAttempts => 'Zbyt wiele prób logowania. Spróbuj ponownie za kilka minut.';

	/// pl: 'Nie udało się połączyć z serwerem. Sprawdź adres w Ustawieniach.'
	String get serverUnreachable => 'Nie udało się połączyć z serwerem. Sprawdź adres w Ustawieniach.';
}

// Path: settings.theme
class Translations$settings$theme$pl {
	Translations$settings$theme$pl._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// pl: 'Motyw'
	String get label => 'Motyw';

	/// pl: 'Systemowy'
	String get system => 'Systemowy';

	/// pl: 'Jasny'
	String get light => 'Jasny';

	/// pl: 'Ciemny'
	String get dark => 'Ciemny';
}

// Path: dashboard.account
class Translations$dashboard$account$pl {
	Translations$dashboard$account$pl._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// pl: 'Konto'
	String get title => 'Konto';

	/// pl: 'Numer pracownika'
	String get operator => 'Numer pracownika';

	/// pl: 'Status'
	String get status => 'Status';

	/// pl: 'Serwer'
	String get server => 'Serwer';
}

// Path: dashboard.materialsSm
class Translations$dashboard$materialsSm$pl {
	Translations$dashboard$materialsSm$pl._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// pl: 'Materiały SM'
	String get title => 'Materiały SM';

	/// pl: 'Przyjęcia i wydania'
	String get subtitle => 'Przyjęcia i wydania';
}

// Path: dashboard.frp
class Translations$dashboard$frp$pl {
	Translations$dashboard$frp$pl._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// pl: 'FRP'
	String get title => 'FRP';

	/// pl: 'Oznaczenie numerów szpul'
	String get subtitle => 'Oznaczenie numerów szpul';
}

/// The flat map containing all translations for locale <pl>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'login.username' => 'Login',
			'login.password' => 'Hasło',
			'login.submit' => 'Zaloguj',
			'login.submitting' => 'Logowanie...',
			'login.errors.invalidCredentials' => 'Nieprawidłowy login lub hasło.',
			'login.errors.cipUnreachable' => 'Nie udało się połączyć z systemem CIP.',
			'login.errors.tooManyAttempts' => 'Zbyt wiele prób logowania. Spróbuj ponownie za kilka minut.',
			'login.errors.serverUnreachable' => 'Nie udało się połączyć z serwerem. Sprawdź adres w Ustawieniach.',
			'settings.title' => 'Ustawienia',
			'settings.loggedInAs' => 'Zalogowano jako',
			'settings.logout' => 'Wyloguj',
			'settings.apiUrl' => 'Adres wpsApi',
			'settings.apiToken' => 'Token API',
			'settings.save' => 'Zapisz',
			'settings.language' => 'Język',
			'settings.numericKeyboard' => 'Klawiatura ekranowa przy polach liczbowych',
			'settings.numericKeyboardHint' => 'Wyłącz, jeśli wpisujesz ilości fizyczną klawiaturą skanera.',
			'settings.theme.label' => 'Motyw',
			'settings.theme.system' => 'Systemowy',
			'settings.theme.light' => 'Jasny',
			'settings.theme.dark' => 'Ciemny',
			'nav.back' => 'Wstecz',
			'operations.modeReceive' => 'Przyjęcie',
			'operations.modeIssue' => 'Wydanie',
			'operations.scanPlaceholder' => 'Zeskanuj lub wpisz kod',
			'operations.location' => 'Lokalizacja',
			'operations.material' => 'Materiał',
			'operations.onStock' => 'Na stanie',
			'operations.issueQuantity' => 'Ilość wydania',
			'operations.pickSpool' => 'Wybierz numer szpuli',
			'operations.noSpoolNumber' => 'Brak numeru szpuli',
			'operations.noSpoolTag' => 'bez nr szpuli',
			'operations.unitLabel' => 'Szpula',
			'operations.unitOptional' => 'Numer szpuli',
			'operations.quantityLabel' => 'Ilość',
			'operations.available' => ({required Object value}) => 'Dostępne: ${value}',
			'operations.confirm' => 'Zatwierdź',
			'operations.cancel' => 'Anuluj',
			'operations.submitting' => 'Zapisywanie...',
			'operations.submitted' => 'Zapisano.',
			'operations.issued' => ({required Object name}) => 'Wydano ${name}.',
			'operations.received' => ({required Object name}) => 'Przyjęto ${name}.',
			'operations.errorNotInStock' => 'Tego materiału nie ma już na stanie.',
			'operations.errorUnitGone' => 'Ta szpula została już wydana.',
			'operations.errorNotEnough' => ({required Object available}) => 'Na stanie jest tylko ${available}.',
			'operations.loadingStock' => 'Pobieranie stanu z serwera…',
			'operations.toastLoadFailed' => 'Nie udało się pobrać stanu z serwera.',
			'operations.toastUnknown' => 'Nieznany kod - nie znaleziono materiału ani jednostki.',
			'operations.toastNotIssuable' => 'Brak dostępnej ilości tego materiału do wydania.',
			'operations.loadingName' => 'Pobieranie nazwy…',
			'dashboard.appTitle' => 'Stock Manager',
			'dashboard.online' => 'Online',
			'dashboard.offline' => 'Offline',
			'dashboard.modules' => 'Moduły',
			'dashboard.tabAccount' => 'Konto',
			'dashboard.account.title' => 'Konto',
			'dashboard.account.operator' => 'Numer pracownika',
			'dashboard.account.status' => 'Status',
			'dashboard.account.server' => 'Serwer',
			'dashboard.materialsSm.title' => 'Materiały SM',
			'dashboard.materialsSm.subtitle' => 'Przyjęcia i wydania',
			'dashboard.frp.title' => 'FRP',
			'dashboard.frp.subtitle' => 'Oznaczenie numerów szpul',
			'frp.listTitle' => 'Do oznaczenia numerem szpuli',
			'frp.listEmpty' => 'Brak FRP bez numeru szpuli.',
			'frp.retry' => 'Spróbuj ponownie',
			'frp.toastNotPending' => 'Ten FRP nie ma ilości bez numeru szpuli.',
			'frp.labelTitle' => 'Oznaczenie szpuli',
			'frp.toLabel' => 'Do oznaczenia',
			'frp.batch' => 'Batch',
			'frp.spoolNumber' => 'Numer szpuli',
			'frp.length' => 'Długość',
			'frp.labeled' => ({required Object name, required Object unitId}) => 'Oznaczono ${name}: ${unitId}.',
			'frp.numberTaken' => ({required Object taken, required Object next}) => 'Numer ${taken} został już zajęty - nowy numer: ${next}.',
			'history.issuesTitle' => 'Moje wydania',
			'history.labelingsTitle' => 'Moje oznaczenia',
			'history.employee' => 'Numer pracownika',
			'history.empty' => 'Brak wpisów.',
			'history.refresh' => 'Odśwież',
			_ => null,
		};
	}
}
