import 'dart:js_interop';

@JS('queryFields')
external JSPromise<JSObject> _queryFields();

@JS('fillFields')
external JSPromise<JSObject> _fillFields(JSNumber frameId, JSAny? fields);

@JS('getFavIconUrl')
external JSPromise<JSObject> _getFavIconURL();

@JS('getURL')
external JSPromise<JSObject> _getURL();

@JS('exportEntries')
external JSPromise<JSObject> _exportEntries(JSAny? entries);

@JS('createSettingsPage')
external JSPromise<JSObject> _createSettingsPage();

@JS('navigateToPageRoute')
external JSPromise<JSObject> _navigateToPageRoute(JSString route);

@JS('closeCurrentTab')
external JSPromise<JSObject> _closeCurrentTab();

@JS('closeLastFocusedWindow')
external JSPromise<JSObject> _closeLastFocusedWindow();

@JS('getToken')
external JSPromise<JSObject> _getToken();

Future<Map> queryFields() async {
  var result = await _queryFields().toDart;
  return result.dartify() as Map;
}

Future<void> fillFields(int frameId, List<Map> fields) async {
  await _fillFields(frameId.toJS, fields.jsify()).toDart;
}

Future<String> getFavIconUrl() async {
  var result = await _getFavIconURL().toDart;
  return result.dartify() as String;
}

Future<String> getURL() async {
  var res = await _getURL().toDart;
  return res.dartify() as String;
}

Future<void> exportEntries(List<String> entries) async {
  await _exportEntries(entries.jsify()).toDart;
}

Future<void> createSettingsPage() async {
  await _createSettingsPage().toDart;
}

Future<void> navigateToPageRoute(String route) async {
  await _navigateToPageRoute(route.toJS).toDart;
}

Future<void> closeCurrentTab() async {
  await _closeCurrentTab().toDart;
}

Future<void> closeLastFocusedWindow() async {
  await _closeLastFocusedWindow().toDart;
}

Future<String> getToken() async {
  print("token");
  var token = await _getToken().toDart;
  return token.dartify() as String;
}
