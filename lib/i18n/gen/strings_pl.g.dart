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

	/// pl: 'Naciśnij spust skanera lub wpisz kod ręcznie.'
	String get scanHint => 'Naciśnij spust skanera lub wpisz kod ręcznie.';

	/// pl: 'Kolejka jest pusta - zeskanuj materiał, aby dodać wiersz.'
	String get queueEmpty => 'Kolejka jest pusta - zeskanuj materiał, aby dodać wiersz.';

	/// pl: 'Do zatwierdzenia ({count})'
	String queueTitle({required Object count}) => 'Do zatwierdzenia (${count})';

	/// pl: 'Nr jednostki'
	String get unitLabel => 'Nr jednostki';

	/// pl: 'Nr jednostki (opcjonalnie - puste = ilość nieprzypisana)'
	String get unitOptional => 'Nr jednostki (opcjonalnie - puste = ilość nieprzypisana)';

	/// pl: 'Ilość'
	String get quantityLabel => 'Ilość';

	/// pl: 'Dostępne: {value}'
	String available({required Object value}) => 'Dostępne: ${value}';

	/// pl: 'Zatwierdź'
	String get submit => 'Zatwierdź';

	/// pl: 'Zapisywanie...'
	String get submitting => 'Zapisywanie...';

	/// pl: 'Zapisano.'
	String get submitted => 'Zapisano.';

	/// pl: 'Usuń'
	String get remove => 'Usuń';

	/// pl: 'Wybierz co wydać'
	String get pickTitle => 'Wybierz co wydać';

	/// pl: 'Ilość nieprzypisana'
	String get pickPending => 'Ilość nieprzypisana';

	/// pl: 'Jednostka {unitId}'
	String pickUnit({required Object unitId}) => 'Jednostka ${unitId}';

	/// pl: 'Nieznany kod - nie znaleziono materiału ani jednostki.'
	String get toastUnknown => 'Nieznany kod - nie znaleziono materiału ani jednostki.';

	/// pl: 'Ten wpis jest już w kolejce.'
	String get toastAlready => 'Ten wpis jest już w kolejce.';

	/// pl: 'Brak dostępnej ilości tego materiału do wydania.'
	String get toastNotIssuable => 'Brak dostępnej ilości tego materiału do wydania.';
}

// Path: dashboard
class Translations$dashboard$pl {
	Translations$dashboard$pl._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
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

	/// pl: 'Kontrola materiałów FRP'
	String get subtitle => 'Kontrola materiałów FRP';
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
			'operations.scanHint' => 'Naciśnij spust skanera lub wpisz kod ręcznie.',
			'operations.queueEmpty' => 'Kolejka jest pusta - zeskanuj materiał, aby dodać wiersz.',
			'operations.queueTitle' => ({required Object count}) => 'Do zatwierdzenia (${count})',
			'operations.unitLabel' => 'Nr jednostki',
			'operations.unitOptional' => 'Nr jednostki (opcjonalnie - puste = ilość nieprzypisana)',
			'operations.quantityLabel' => 'Ilość',
			'operations.available' => ({required Object value}) => 'Dostępne: ${value}',
			'operations.submit' => 'Zatwierdź',
			'operations.submitting' => 'Zapisywanie...',
			'operations.submitted' => 'Zapisano.',
			'operations.remove' => 'Usuń',
			'operations.pickTitle' => 'Wybierz co wydać',
			'operations.pickPending' => 'Ilość nieprzypisana',
			'operations.pickUnit' => ({required Object unitId}) => 'Jednostka ${unitId}',
			'operations.toastUnknown' => 'Nieznany kod - nie znaleziono materiału ani jednostki.',
			'operations.toastAlready' => 'Ten wpis jest już w kolejce.',
			'operations.toastNotIssuable' => 'Brak dostępnej ilości tego materiału do wydania.',
			'dashboard.materialsSm.title' => 'Materiały SM',
			'dashboard.materialsSm.subtitle' => 'Przyjęcia i wydania',
			'dashboard.frp.title' => 'FRP',
			'dashboard.frp.subtitle' => 'Kontrola materiałów FRP',
			'frp.placeholder' => 'Sekcja FRP jest w budowie.',
			_ => null,
		};
	}
}
