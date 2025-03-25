import 'dart:js_interop';

@JS('queryFields')
external JSPromise<JSObject> _queryFields();

@JS('fillFields')
external JSPromise<JSObject> _fillFields(JSNumber frameId, JSAny? fields);

@JS('getFavIconUrl')
external JSPromise<JSObject> _getFavIconURL();

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
