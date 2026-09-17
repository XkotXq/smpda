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
	@override String get scanHint => 'Pull the scanner trigger or type a code manually.';
	@override String get queueEmpty => 'The queue is empty - scan a material to add a line.';
	@override String queueTitle({required Object count}) => 'To confirm (${count})';
	@override String get unitLabel => 'Unit no.';
	@override String get unitOptional => 'Unit no. (optional - blank = unassigned quantity)';
	@override String get quantityLabel => 'Quantity';
	@override String available({required Object value}) => 'Available: ${value}';
	@override String get submit => 'Confirm';
	@override String get submitting => 'Saving...';
	@override String get submitted => 'Saved.';
	@override String get remove => 'Remove';
	@override String get pickTitle => 'Choose what to issue';
	@override String get pickPending => 'Unassigned quantity';
	@override String pickUnit({required Object unitId}) => 'Unit ${unitId}';
	@override String get toastUnknown => 'Unknown code - no matching material or unit.';
	@override String get toastAlready => 'That line is already queued.';
	@override String get toastNotIssuable => 'No available quantity of this material to issue.';
}

// Path: dashboard
class _Translations$dashboard$en implements Translations$dashboard$pl {
	_Translations$dashboard$en._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
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
	@override String get subtitle => 'FRP material checks';
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
			'operations.scanHint' => 'Pull the scanner trigger or type a code manually.',
			'operations.queueEmpty' => 'The queue is empty - scan a material to add a line.',
			'operations.queueTitle' => ({required Object count}) => 'To confirm (${count})',
			'operations.unitLabel' => 'Unit no.',
			'operations.unitOptional' => 'Unit no. (optional - blank = unassigned quantity)',
			'operations.quantityLabel' => 'Quantity',
			'operations.available' => ({required Object value}) => 'Available: ${value}',
			'operations.submit' => 'Confirm',
			'operations.submitting' => 'Saving...',
			'operations.submitted' => 'Saved.',
			'operations.remove' => 'Remove',
			'operations.pickTitle' => 'Choose what to issue',
			'operations.pickPending' => 'Unassigned quantity',
			'operations.pickUnit' => ({required Object unitId}) => 'Unit ${unitId}',
			'operations.toastUnknown' => 'Unknown code - no matching material or unit.',
			'operations.toastAlready' => 'That line is already queued.',
			'operations.toastNotIssuable' => 'No available quantity of this material to issue.',
			'dashboard.materialsSm.title' => 'Materiały SM',
			'dashboard.materialsSm.subtitle' => 'Receipts and issues',
			'dashboard.frp.title' => 'FRP',
			'dashboard.frp.subtitle' => 'FRP material checks',
			'frp.placeholder' => 'The FRP section is under construction.',
			_ => null,
		};
	}
}
