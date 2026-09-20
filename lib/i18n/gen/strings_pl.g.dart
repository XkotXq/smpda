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

	/// pl: 'Naciśnij spust skanera lub zeskanuj kod ręcznie, aby rozpocząć.'
	String get idle => 'Naciśnij spust skanera lub zeskanuj kod ręcznie, aby rozpocząć.';

	/// pl: 'Lokalizacja'
	String get location => 'Lokalizacja';

	/// pl: 'Szpula'
	String get unitLabel => 'Szpula';

	/// pl: 'Numer szpuli (puste = nieoznaczone)'
	String get unitOptional => 'Numer szpuli (puste = nieoznaczone)';

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

	/// pl: 'Wybierz co wydać'
	String get pickTitle => 'Wybierz co wydać';

	/// pl: 'Nieoznaczone'
	String get pickPending => 'Nieoznaczone';

	/// pl: 'Szpula {unitId}'
	String pickUnit({required Object unitId}) => 'Szpula ${unitId}';

	/// pl: 'Nieznany kod - nie znaleziono materiału ani jednostki.'
	String get toastUnknown => 'Nieznany kod - nie znaleziono materiału ani jednostki.';

	/// pl: 'Brak dostępnej ilości tego materiału do wydania.'
	String get toastNotIssuable => 'Brak dostępnej ilości tego materiału do wydania.';
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

	/// pl: 'Sekcja FRP jest w budowie.'
	String get placeholder => 'Sekcja FRP jest w budowie.';
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
			'settings.title' => 'Ustawienia',
			'settings.loggedInAs' => 'Zalogowano jako',
			'settings.logout' => 'Wyloguj',
			'settings.apiUrl' => 'Adres wpsApi',
			'settings.apiToken' => 'Token API',
			'settings.save' => 'Zapisz',
			'settings.language' => 'Język',
			'settings.theme.label' => 'Motyw',
			'settings.theme.system' => 'Systemowy',
			'settings.theme.light' => 'Jasny',
			'settings.theme.dark' => 'Ciemny',
			'nav.back' => 'Wstecz',
			'operations.modeReceive' => 'Przyjęcie',
			'operations.modeIssue' => 'Wydanie',
			'operations.scanPlaceholder' => 'Zeskanuj lub wpisz kod',
			'operations.idle' => 'Naciśnij spust skanera lub zeskanuj kod ręcznie, aby rozpocząć.',
			'operations.location' => 'Lokalizacja',
			'operations.unitLabel' => 'Szpula',
			'operations.unitOptional' => 'Numer szpuli (puste = nieoznaczone)',
			'operations.quantityLabel' => 'Ilość',
			'operations.available' => ({required Object value}) => 'Dostępne: ${value}',
			'operations.confirm' => 'Zatwierdź',
			'operations.cancel' => 'Anuluj',
			'operations.submitting' => 'Zapisywanie...',
			'operations.submitted' => 'Zapisano.',
			'operations.pickTitle' => 'Wybierz co wydać',
			'operations.pickPending' => 'Nieoznaczone',
			'operations.pickUnit' => ({required Object unitId}) => 'Szpula ${unitId}',
			'operations.toastUnknown' => 'Nieznany kod - nie znaleziono materiału ani jednostki.',
			'operations.toastNotIssuable' => 'Brak dostępnej ilości tego materiału do wydania.',
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
			'frp.placeholder' => 'Sekcja FRP jest w budowie.',
			_ => null,
		};
	}
}
