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
	@override late final _Translations$nav$en nav = _Translations$nav$en._(_root);
	@override late final _Translations$operations$en operations = _Translations$operations$en._(_root);
	@override late final _Translations$dashboard$en dashboard = _Translations$dashboard$en._(_root);
	@override late final _Translations$frp$en frp = _Translations$frp$en._(_root);
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
	@override String get title => 'Settings';
	@override String get loggedInAs => 'Signed in as';
	@override String get logout => 'Sign out';
	@override String get apiUrl => 'wpsApi address';
	@override String get apiToken => 'API token';
	@override String get save => 'Save';
	@override String get language => 'Language';
	@override late final _Translations$settings$theme$en theme = _Translations$settings$theme$en._(_root);
}

// Path: nav
class _Translations$nav$en implements Translations$nav$pl {
	_Translations$nav$en._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get back => 'Back';
}

// Path: operations
class _Translations$operations$en implements Translations$operations$pl {
	_Translations$operations$en._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get modeReceive => 'Receive';
	@override String get modeIssue => 'Issue';
	@override String get scanPlaceholder => 'Scan or type a code';
	@override String get idle => 'Pull the scanner trigger or scan a code manually to start.';
	@override String get location => 'Location';
	@override String get unitLabel => 'Spool';
	@override String get unitOptional => 'Spool number (blank = unmarked)';
	@override String get quantityLabel => 'Quantity';
	@override String available({required Object value}) => 'Available: ${value}';
	@override String get confirm => 'Confirm';
	@override String get cancel => 'Cancel';
	@override String get submitting => 'Saving...';
	@override String get submitted => 'Saved.';
	@override String get pickTitle => 'Choose what to issue';
	@override String get pickPending => 'Unmarked';
	@override String pickUnit({required Object unitId}) => 'Spool ${unitId}';
	@override String get toastUnknown => 'Unknown code - no matching material or unit.';
	@override String get toastNotIssuable => 'No available quantity of this material to issue.';
}

// Path: dashboard
class _Translations$dashboard$en implements Translations$dashboard$pl {
	_Translations$dashboard$en._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get appTitle => 'Stock Manager';
	@override String get online => 'Online';
	@override String get offline => 'Offline';
	@override String get modules => 'Modules';
	@override String get tabAccount => 'Account';
	@override late final _Translations$dashboard$account$en account = _Translations$dashboard$account$en._(_root);
	@override late final _Translations$dashboard$materialsSm$en materialsSm = _Translations$dashboard$materialsSm$en._(_root);
	@override late final _Translations$dashboard$frp$en frp = _Translations$dashboard$frp$en._(_root);
}

// Path: frp
class _Translations$frp$en implements Translations$frp$pl {
	_Translations$frp$en._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get placeholder => 'The FRP section is under construction.';
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

// Path: dashboard.account
class _Translations$dashboard$account$en implements Translations$dashboard$account$pl {
	_Translations$dashboard$account$en._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Account information';
	@override String get operator => 'Employee number';
	@override String get status => 'Status';
	@override String get server => 'Server';
}

// Path: dashboard.materialsSm
class _Translations$dashboard$materialsSm$en implements Translations$dashboard$materialsSm$pl {
	_Translations$dashboard$materialsSm$en._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Materiały SM';
	@override String get subtitle => 'Receipts and issues';
}

// Path: dashboard.frp
class _Translations$dashboard$frp$en implements Translations$dashboard$frp$pl {
	_Translations$dashboard$frp$en._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'FRP';
	@override String get subtitle => 'Spool number marking';
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
			'settings.title' => 'Settings',
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
			'nav.back' => 'Back',
			'operations.modeReceive' => 'Receive',
			'operations.modeIssue' => 'Issue',
			'operations.scanPlaceholder' => 'Scan or type a code',
			'operations.idle' => 'Pull the scanner trigger or scan a code manually to start.',
			'operations.location' => 'Location',
			'operations.unitLabel' => 'Spool',
			'operations.unitOptional' => 'Spool number (blank = unmarked)',
			'operations.quantityLabel' => 'Quantity',
			'operations.available' => ({required Object value}) => 'Available: ${value}',
			'operations.confirm' => 'Confirm',
			'operations.cancel' => 'Cancel',
			'operations.submitting' => 'Saving...',
			'operations.submitted' => 'Saved.',
			'operations.pickTitle' => 'Choose what to issue',
			'operations.pickPending' => 'Unmarked',
			'operations.pickUnit' => ({required Object unitId}) => 'Spool ${unitId}',
			'operations.toastUnknown' => 'Unknown code - no matching material or unit.',
			'operations.toastNotIssuable' => 'No available quantity of this material to issue.',
			'dashboard.appTitle' => 'Stock Manager',
			'dashboard.online' => 'Online',
			'dashboard.offline' => 'Offline',
			'dashboard.modules' => 'Modules',
			'dashboard.tabAccount' => 'Account',
			'dashboard.account.title' => 'Account information',
			'dashboard.account.operator' => 'Employee number',
			'dashboard.account.status' => 'Status',
			'dashboard.account.server' => 'Server',
			'dashboard.materialsSm.title' => 'Materiały SM',
			'dashboard.materialsSm.subtitle' => 'Receipts and issues',
			'dashboard.frp.title' => 'FRP',
			'dashboard.frp.subtitle' => 'Spool number marking',
			'frp.placeholder' => 'The FRP section is under construction.',
			_ => null,
		};
	}
}
