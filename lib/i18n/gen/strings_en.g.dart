///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class TranslationsEn with BaseTranslations<AppLocale, Translations> implements Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsEn({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	/// Access flat map
	@override dynamic operator[](String key) => _meta.getTranslation(key);

	late final TranslationsEn _root = this; // ignore: unused_field

	@override 
	TranslationsEn $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsEn(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$login$en login = _Translations$login$en._(_root);
	@override late final _Translations$settings$en settings = _Translations$settings$en._(_root);
	@override late final _Translations$scan$en scan = _Translations$scan$en._(_root);
	@override late final _Translations$nav$en nav = _Translations$nav$en._(_root);
}

// Path: login
class _Translations$login$en implements Translations$login$pl {
	_Translations$login$en._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get username => 'Username';
	@override String get password => 'Password';
	@override String get submit => 'Sign in';
	@override String get submitting => 'Signing in...';
}

// Path: settings
class _Translations$settings$en implements Translations$settings$pl {
	_Translations$settings$en._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get loggedInAs => 'Signed in as';
	@override String get logout => 'Sign out';
	@override String get apiUrl => 'wpsApi address';
	@override String get apiToken => 'API token';
	@override String get save => 'Save';
	@override String get language => 'Language';
	@override late final _Translations$settings$theme$en theme = _Translations$settings$theme$en._(_root);
}

// Path: scan
class _Translations$scan$en implements Translations$scan$pl {
	_Translations$scan$en._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get noHardware => 'No physical scanner on this device - type a code manually to simulate a scan.';
	@override String get manualPlaceholder => 'Type a code and submit';
	@override String get simulate => 'Simulate scan';
	@override String get waitingHardware => 'Pull the scanner trigger to scan a code.';
	@override String get waitingManual => 'No scanned codes yet - type one above.';
}

// Path: nav
class _Translations$nav$en implements Translations$nav$pl {
	_Translations$nav$en._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get scan => 'Scan';
	@override String get settings => 'Settings';
}

// Path: settings.theme
class _Translations$settings$theme$en implements Translations$settings$theme$pl {
	_Translations$settings$theme$en._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get label => 'Theme';
	@override String get system => 'System';
	@override String get light => 'Light';
	@override String get dark => 'Dark';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsEn {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'login.username' => 'Username',
			'login.password' => 'Password',
			'login.submit' => 'Sign in',
			'login.submitting' => 'Signing in...',
			'settings.loggedInAs' => 'Signed in as',
			'settings.logout' => 'Sign out',
			'settings.apiUrl' => 'wpsApi address',
			'settings.apiToken' => 'API token',
			'settings.save' => 'Save',
			'settings.language' => 'Language',
			'settings.theme.label' => 'Theme',
			'settings.theme.system' => 'System',
			'settings.theme.light' => 'Light',
			'settings.theme.dark' => 'Dark',
			'scan.noHardware' => 'No physical scanner on this device - type a code manually to simulate a scan.',
			'scan.manualPlaceholder' => 'Type a code and submit',
			'scan.simulate' => 'Simulate scan',
			'scan.waitingHardware' => 'Pull the scanner trigger to scan a code.',
			'scan.waitingManual' => 'No scanned codes yet - type one above.',
			'nav.scan' => 'Scan',
			'nav.settings' => 'Settings',
			_ => null,
		};
	}
}
