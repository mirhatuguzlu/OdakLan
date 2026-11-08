// Compiled to JS for the `game` Edge Function (tool/build_server.sh):
// exposes `globalThis.odaklanHandle(requestJson) -> resultJson`.
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:odaklan_core/odaklan_core.dart';

void main() {
  globalContext.setProperty(
    'odaklanHandle'.toJS,
    ((JSString req) => handleGameRequest(req.toDart).toJS).toJS,
  );
}
