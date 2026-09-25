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
	@override late final _Translations$history$en history = _Translations$history$en._(_root);
	@override late final _Translations$orders$en orders = _Translations$orders$en._(_root);
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
	@override late final _Translations$login$errors$en errors = _Translations$login$errors$en._(_root);
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
	@override String get numericKeyboard => 'On-screen keyboard for number fields';
	@override String get numericKeyboardHint => 'Turn off if you type quantities on the scanner\'s physical keypad.';
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
	@override String get location => 'Location';
	@override String get material => 'Material';
	@override String get onStock => 'In stock';
	@override String get issueQuantity => 'Issue quantity';
	@override String get pickSpool => 'Choose a spool number';
	@override String get noSpoolNumber => 'No spool number';
	@override String get noSpoolTag => 'no spool no.';
	@override String get unitLabel => 'Spool';
	@override String get unitOptional => 'Spool number';
	@override String get quantityLabel => 'Quantity';
	@override String available({required Object value}) => 'Available: ${value}';
	@override String get confirm => 'Confirm';
	@override String get cancel => 'Cancel';
	@override String get submitting => 'Saving...';
	@override String get submitted => 'Saved.';
	@override String issued({required Object name}) => 'Issued ${name}.';
	@override String received({required Object name}) => 'Received ${name}.';
	@override String get errorNotInStock => 'This material is no longer in stock.';
	@override String get errorUnitGone => 'This spool has already been issued.';
	@override String errorNotEnough({required Object available}) => 'Only ${available} in stock.';
	@override String get loadingStock => 'Loading stock from the server…';
	@override String get toastLoadFailed => 'Could not load stock from the server.';
	@override String get toastOffline => 'No connection to the server - can\'t scan. Check Wi-Fi and try again.';
	@override String get toastUnknown => 'Unknown code - no matching material or unit.';
	@override String get toastNotIssuable => 'No available quantity of this material to issue.';
	@override String get loadingName => 'Loading name…';
	@override String get errorSessionExpired => 'Your session has expired - please log in again.';
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
	@override late final _Translations$dashboard$orders$en orders = _Translations$dashboard$orders$en._(_root);
}

// Path: frp
class _Translations$frp$en implements Translations$frp$pl {
	_Translations$frp$en._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get listTitle => 'To label with a spool number';
	@override String get listEmpty => 'No FRP without a spool number.';
	@override String get retry => 'Try again';
	@override String get toastNotPending => 'This FRP has no quantity without a spool number.';
	@override String get labelTitle => 'Spool labeling';
	@override String get toLabel => 'To label';
	@override String get batch => 'Batch';
	@override String get spoolNumber => 'Spool number';
	@override String get length => 'Length';
	@override String labeled({required Object name, required Object unitId}) => 'Labeled ${name}: ${unitId}.';
	@override String numberTaken({required Object taken, required Object next}) => 'Number ${taken} was already taken - new number: ${next}.';
}

// Path: history
class _Translations$history$en implements Translations$history$pl {
	_Translations$history$en._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get issuesTitle => 'My issues';
	@override String get labelingsTitle => 'My labelings';
	@override String get employee => 'Employee number';
	@override String get empty => 'No entries.';
	@override String get refresh => 'Refresh';
}

// Path: orders
class _Translations$orders$en implements Translations$orders$pl {
	_Translations$orders$en._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get placeholder => 'The orders section is under construction.';
}

// Path: login.errors
class _Translations$login$errors$en implements Translations$login$errors$pl {
	_Translations$login$errors$en._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get invalidCredentials => 'Wrong username or password.';
	@override String get cipUnreachable => 'Could not reach the CIP system.';
	@override String get tooManyAttempts => 'Too many login attempts. Try again in a few minutes.';
	@override String get serverUnreachable => 'Could not reach the server. Check the address in Settings.';
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
	@override String get title => 'Account';
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

// Path: dashboard.orders
class _Translations$dashboard$orders$en implements Translations$dashboard$orders$pl {
	_Translations$dashboard$orders$en._(this._root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Order handling';
	@override String get subtitle => 'Internal transport orders';
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
			'login.errors.invalidCredentials' => 'Wrong username or password.',
			'login.errors.cipUnreachable' => 'Could not reach the CIP system.',
			'login.errors.tooManyAttempts' => 'Too many login attempts. Try again in a few minutes.',
			'login.errors.serverUnreachable' => 'Could not reach the server. Check the address in Settings.',
			'settings.title' => 'Settings',
			'settings.loggedInAs' => 'Signed in as',
			'settings.logout' => 'Sign out',
			'settings.apiUrl' => 'wpsApi address',
			'settings.apiToken' => 'API token',
			'settings.save' => 'Save',
			'settings.language' => 'Language',
			'settings.numericKeyboard' => 'On-screen keyboard for number fields',
			'settings.numericKeyboardHint' => 'Turn off if you type quantities on the scanner\'s physical keypad.',
			'settings.theme.label' => 'Theme',
			'settings.theme.system' => 'System',
			'settings.theme.light' => 'Light',
			'settings.theme.dark' => 'Dark',
			'nav.back' => 'Back',
			'operations.modeReceive' => 'Receive',
			'operations.modeIssue' => 'Issue',
			'operations.scanPlaceholder' => 'Scan or type a code',
			'operations.location' => 'Location',
			'operations.material' => 'Material',
			'operations.onStock' => 'In stock',
			'operations.issueQuantity' => 'Issue quantity',
			'operations.pickSpool' => 'Choose a spool number',
			'operations.noSpoolNumber' => 'No spool number',
			'operations.noSpoolTag' => 'no spool no.',
			'operations.unitLabel' => 'Spool',
			'operations.unitOptional' => 'Spool number',
			'operations.quantityLabel' => 'Quantity',
			'operations.available' => ({required Object value}) => 'Available: ${value}',
			'operations.confirm' => 'Confirm',
			'operations.cancel' => 'Cancel',
			'operations.submitting' => 'Saving...',
			'operations.submitted' => 'Saved.',
			'operations.issued' => ({required Object name}) => 'Issued ${name}.',
			'operations.received' => ({required Object name}) => 'Received ${name}.',
			'operations.errorNotInStock' => 'This material is no longer in stock.',
			'operations.errorUnitGone' => 'This spool has already been issued.',
			'operations.errorNotEnough' => ({required Object available}) => 'Only ${available} in stock.',
			'operations.loadingStock' => 'Loading stock from the server…',
			'operations.toastLoadFailed' => 'Could not load stock from the server.',
			'operations.toastOffline' => 'No connection to the server - can\'t scan. Check Wi-Fi and try again.',
			'operations.toastUnknown' => 'Unknown code - no matching material or unit.',
			'operations.toastNotIssuable' => 'No available quantity of this material to issue.',
			'operations.loadingName' => 'Loading name…',
			'operations.errorSessionExpired' => 'Your session has expired - please log in again.',
			'dashboard.appTitle' => 'Stock Manager',
			'dashboard.online' => 'Online',
			'dashboard.offline' => 'Offline',
			'dashboard.modules' => 'Modules',
			'dashboard.tabAccount' => 'Account',
			'dashboard.account.title' => 'Account',
			'dashboard.account.operator' => 'Employee number',
			'dashboard.account.status' => 'Status',
			'dashboard.account.server' => 'Server',
			'dashboard.materialsSm.title' => 'Materiały SM',
			'dashboard.materialsSm.subtitle' => 'Receipts and issues',
			'dashboard.frp.title' => 'FRP',
			'dashboard.frp.subtitle' => 'Spool number marking',
			'dashboard.orders.title' => 'Order handling',
			'dashboard.orders.subtitle' => 'Internal transport orders',
			'frp.listTitle' => 'To label with a spool number',
			'frp.listEmpty' => 'No FRP without a spool number.',
			'frp.retry' => 'Try again',
			'frp.toastNotPending' => 'This FRP has no quantity without a spool number.',
			'frp.labelTitle' => 'Spool labeling',
			'frp.toLabel' => 'To label',
			'frp.batch' => 'Batch',
			'frp.spoolNumber' => 'Spool number',
			'frp.length' => 'Length',
			'frp.labeled' => ({required Object name, required Object unitId}) => 'Labeled ${name}: ${unitId}.',
			'frp.numberTaken' => ({required Object taken, required Object next}) => 'Number ${taken} was already taken - new number: ${next}.',
			'history.issuesTitle' => 'My issues',
			'history.labelingsTitle' => 'My labelings',
			'history.employee' => 'Employee number',
			'history.empty' => 'No entries.',
			'history.refresh' => 'Refresh',
			'orders.placeholder' => 'The orders section is under construction.',
			_ => null,
		};
	}
}
