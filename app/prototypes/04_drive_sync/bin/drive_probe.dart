// SPDX-License-Identifier: GPL-3.0-or-later

// M1 prototype 4 (PRD R1, R10): file-mode sync on Google Drive between two
// accounts with the narrow `drive.file` scope. Desktop only: OAuth with PKCE
// in the system browser and a loopback redirect. Not production code.
//
// Secrets never go in the repository: the OAuth client file and the tokens
// live in `.secrets/`, which git ignores. A real app keeps tokens in the
// system keychain (flutter_secure_storage); this command-line probe cannot.
//
// Usage: dart run bin/drive_probe.dart <command> <account A|B> [arguments]
//   login <acct>              plain consent for drive.file
//   pick <acct> [fileId]      consent + Google Picker (folders allowed)
//   create <acct>             create a fake trip folder with operation files
//   share <acct> <role>       share the trip folder with the other account
//                             (role: writer | reader); the address is read
//                             from .secrets/config.json
//   inspect <acct>            what does this account's app see of the trip?
//   write <acct>              add an operation file in ops/<device>/
//   wait <acct> <fileName>    poll until a file written by the other appears
//   changes <acct>            read the Drive "changes" feed since last call

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

const String scope = 'https://www.googleapis.com/auth/drive.file';
const String api = 'https://www.googleapis.com/drive/v3';
const String upload = 'https://www.googleapis.com/upload/drive/v3';
const String userAgent =
    'Itinerea/0.0.1 (+https://github.com/NotEnjoyingThis/itinerea)';
const String folderMime = 'application/vnd.google-apps.folder';

final Directory secrets = Directory('.secrets');
final File stateFile = File('.secrets/state.json');

Map<String, dynamic> readJson(File file) => file.existsSync()
    ? jsonDecode(file.readAsStringSync()) as Map<String, dynamic>
    : <String, dynamic>{};

void writeJson(File file, Map<String, dynamic> value) =>
    file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(value));

/// The "installed" section of the OAuth client file from the Cloud Console.
Map<String, dynamic> oauthClient() {
  final file = secrets.listSync().whereType<File>().firstWhere(
    (f) => f.uri.pathSegments.last.startsWith('client_secret'),
    orElse: () => throw StateError(
      'Put the OAuth client file (client_secret*.json) in .secrets/',
    ),
  );
  return readJson(file)['installed'] as Map<String, dynamic>;
}

String randomUrlSafe(int bytes) {
  final random = Random.secure();
  return base64Url
      .encode(List<int>.generate(bytes, (_) => random.nextInt(256)))
      .replaceAll('=', '');
}

/// OAuth 2.0 authorization code flow with PKCE and a loopback redirect.
/// With [picker] the consent screen also opens the Google Picker and the
/// redirect carries the ids of the picked files.
Future<void> authorize(
  String account, {
  bool picker = false,
  String? fileId,
}) async {
  final client = oauthClient();
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final redirect = 'http://127.0.0.1:${server.port}';
  final verifier = randomUrlSafe(48);
  final challenge = base64Url
      .encode(sha256.convert(ascii.encode(verifier)).bytes)
      .replaceAll('=', '');
  final state = randomUrlSafe(16);
  final url = Uri.parse(client['auth_uri'] as String).replace(
    queryParameters: {
      'client_id': client['client_id'],
      'redirect_uri': redirect,
      'response_type': 'code',
      'scope': scope,
      'access_type': 'offline',
      'code_challenge': challenge,
      'code_challenge_method': 'S256',
      'state': state,
      'prompt': picker ? 'consent' : 'consent select_account',
      if (picker) 'trigger_onepick': 'true',
      if (picker) 'allow_folder_selection': 'true',
      if (picker && fileId != null) 'file_ids': fileId,
    },
  );
  stdout.writeln('Open this address in the browser (account $account):\n$url');
  if (Platform.isWindows) {
    await Process.run('rundll32', ['url.dll,FileProtocolHandler', '$url']);
  }

  final request = await server.first.timeout(const Duration(minutes: 5));
  final query = request.uri.queryParameters;
  request.response
    ..headers.contentType = ContentType.text
    ..write('Itinerea prototype: you can close this tab.');
  await request.response.close();
  await server.close();

  if (query['state'] != state || query['code'] == null) {
    throw StateError('Authorization failed: ${query['error'] ?? 'bad state'}');
  }
  final watch = Stopwatch()..start();
  final response = await http.post(
    Uri.parse(client['token_uri'] as String),
    headers: {'User-Agent': userAgent},
    body: {
      'code': query['code'],
      'client_id': client['client_id'],
      'client_secret': client['client_secret'],
      'redirect_uri': redirect,
      'grant_type': 'authorization_code',
      'code_verifier': verifier,
    },
  );
  final token = jsonDecode(response.body) as Map<String, dynamic>;
  if (response.statusCode != 200) {
    throw StateError('Token exchange failed: ${token['error']}');
  }
  token['obtained_at'] = DateTime.now().toUtc().toIso8601String();
  writeJson(File('.secrets/token_$account.json'), token);
  stdout.writeln(
    jsonEncode({
      'step': picker ? 'pick' : 'login',
      'account': account,
      'grantedScope': token['scope'],
      'hasRefreshToken': token['refresh_token'] != null,
      'tokenExchangeMs': watch.elapsedMilliseconds,
      'pickedFileIds': query['picked_file_ids'],
    }),
  );
}

Future<String> accessToken(String account) async {
  final file = File('.secrets/token_$account.json');
  final token = readJson(file);
  final obtained = DateTime.parse(token['obtained_at'] as String);
  final expires = obtained.add(
    Duration(seconds: (token['expires_in'] as int) - 60),
  );
  if (DateTime.now().toUtc().isBefore(expires)) {
    return token['access_token'] as String;
  }
  final client = oauthClient();
  final response = await http.post(
    Uri.parse(client['token_uri'] as String),
    body: {
      'client_id': client['client_id'],
      'client_secret': client['client_secret'],
      'refresh_token': token['refresh_token'],
      'grant_type': 'refresh_token',
    },
  );
  final fresh = jsonDecode(response.body) as Map<String, dynamic>;
  if (response.statusCode != 200) {
    throw StateError('Token refresh failed: ${fresh['error']}');
  }
  token
    ..addAll(fresh)
    ..['obtained_at'] = DateTime.now().toUtc().toIso8601String();
  writeJson(file, token);
  return token['access_token'] as String;
}

/// One Drive API call. Returns status, decoded JSON (or text) and duration.
Future<({int status, Object? body, int ms})> drive(
  String account,
  String method,
  String url, {
  Object? json,
  List<int>? bytes,
  String? contentType,
}) async {
  final request = http.Request(method, Uri.parse(url))
    ..headers['Authorization'] = 'Bearer ${await accessToken(account)}'
    ..headers['User-Agent'] = userAgent;
  if (json != null) {
    request
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode(json);
  } else if (bytes != null) {
    request
      ..headers['Content-Type'] = contentType!
      ..bodyBytes = bytes;
  }
  final watch = Stopwatch()..start();
  final response = await http.Response.fromStream(await request.send());
  Object? body = response.body;
  try {
    body = jsonDecode(response.body);
  } on FormatException {
    // Plain text (file content).
  }
  return (
    status: response.statusCode,
    body: body,
    ms: watch.elapsedMilliseconds,
  );
}

/// Short reason of a Drive error, without the full payload.
String? reason(Object? body) {
  if (body is Map && body['error'] is Map) {
    final error = body['error'] as Map;
    final errors = error['errors'];
    return errors is List && errors.isNotEmpty
        ? '${(errors.first as Map)['reason']}'
        : '${error['status'] ?? error['message']}';
  }
  return null;
}

Future<String> createFolder(String account, String name, String? parent) async {
  final result = await drive(
    account,
    'POST',
    '$api/files?fields=id',
    json: {
      'name': name,
      'mimeType': folderMime,
      if (parent != null) 'parents': [parent],
    },
  );
  if (result.status != 200) {
    throw StateError('Folder "$name" not created: ${reason(result.body)}');
  }
  return (result.body! as Map)['id'] as String;
}

Future<({int status, Object? body, int ms})> createFile(
  String account,
  String name,
  String parent,
  String content,
) {
  const boundary = 'itinerea_prototype_boundary';
  final body =
      '--$boundary\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n'
      '${jsonEncode({
        'name': name,
        'parents': [parent],
      })}\r\n'
      '--$boundary\r\nContent-Type: application/x-ndjson\r\n\r\n'
      '$content\r\n--$boundary--';
  return drive(
    account,
    'POST',
    '$upload/files?uploadType=multipart&fields=id,name',
    bytes: utf8.encode(body),
    contentType: 'multipart/related; boundary=$boundary',
  );
}

Future<({int status, List<Map<String, dynamic>> files, int ms, String? why})>
children(String account, String folder) async {
  final result = await drive(
    account,
    'GET',
    '$api/files?q=${Uri.encodeQueryComponent("'$folder' in parents and trashed = false")}'
        '&fields=files(id,name,mimeType,ownedByMe,capabilities/canEdit)'
        '&pageSize=100',
  );
  final files = result.status == 200
      ? ((result.body! as Map)['files'] as List).cast<Map<String, dynamic>>()
      : <Map<String, dynamic>>[];
  return (
    status: result.status,
    files: files,
    ms: result.ms,
    why: reason(result.body),
  );
}

String fakeOperation(String device, int seq) => jsonEncode({
  'op': randomUrlSafe(12),
  'dev': device,
  'hlc': '${DateTime.now().toUtc().toIso8601String()}-$seq',
  'v': 1,
  'entity': 'Stop',
  'id': randomUrlSafe(12),
  'set': {'durationMin': 60 + seq},
});

Future<void> main(List<String> args) async {
  if (args.length < 2) {
    stderr.writeln('Usage: dart run bin/drive_probe.dart <command> <A|B> …');
    exitCode = 64;
    return;
  }
  secrets.createSync();
  final command = args[0];
  final account = args[1];
  final device = 'device$account';
  final state = readJson(stateFile);
  void out(Map<String, Object?> value) => stdout.writeln(
    jsonEncode({'step': command, 'account': account, ...value}),
  );

  switch (command) {
    case 'login':
      await authorize(account);
    case 'pick':
      await authorize(
        account,
        picker: true,
        fileId: args.length > 2 ? args[2] : state['trip'] as String?,
      );
    case 'create':
      final tripName = 'trip-${randomUrlSafe(6)}';
      final root = await createFolder(account, 'Itinerea prototype', null);
      final trips = await createFolder(account, 'trips', root);
      final trip = await createFolder(account, tripName, trips);
      final ops = await createFolder(account, 'ops', trip);
      final mine = await createFolder(account, device, ops);
      await createFile(
        account,
        'manifest.json',
        trip,
        jsonEncode({'id': tripName, 'schemaVersion': 1, 'encrypted': false}),
      );
      final first = await createFile(
        account,
        '000001-000003.jsonl',
        mine,
        [for (var i = 1; i <= 3; i++) fakeOperation(device, i)].join('\n'),
      );
      state.addAll({
        'root': root,
        'trip': trip,
        'ops': ops,
        'ops$account': mine,
      });
      writeJson(stateFile, state);
      out({
        'tripFolderId': trip,
        'uploadStatus': first.status,
        'uploadMs': first.ms,
      });
    case 'share':
      final role = args[2];
      final other = account == 'A' ? 'B' : 'A';
      final address =
          readJson(File('.secrets/config.json'))['account$other'] as String;
      final existing = state['permission$other'] as String?;
      final result = existing == null
          ? await drive(
              account,
              'POST',
              '$api/files/${state['trip']}/permissions'
                  '?sendNotificationEmail=false&fields=id,role',
              json: {'type': 'user', 'role': role, 'emailAddress': address},
            )
          : await drive(
              account,
              'PATCH',
              '$api/files/${state['trip']}/permissions/$existing?fields=id,role',
              json: {'role': role},
            );
      if (result.status == 200) {
        state['permission$other'] = (result.body! as Map)['id'];
        writeJson(stateFile, state);
      }
      out({
        'status': result.status,
        'ms': result.ms,
        'role': result.status == 200 ? (result.body! as Map)['role'] : null,
        'why': reason(result.body),
      });
    case 'inspect':
      final trip = state['trip'] as String;
      final folder = await drive(
        account,
        'GET',
        '$api/files/$trip?fields=id,name,ownedByMe,capabilities/canAddChildren',
      );
      final folderBody = folder.body;
      final capabilities = folderBody is Map
          ? folderBody['capabilities']
          : null;
      final top = await children(account, trip);
      final opsId = state['ops'] as String;
      final devices = await children(account, opsId);
      final perDevice = <String, Object?>{};
      for (final folder in devices.files) {
        final files = await children(account, folder['id'] as String);
        String? firstRead;
        if (files.files.isNotEmpty) {
          final content = await drive(
            account,
            'GET',
            '$api/files/${files.files.first['id']}?alt=media',
          );
          firstRead = '${content.status}';
        }
        perDevice[folder['name'] as String] = {
          'files': [for (final f in files.files) f['name']],
          'ownedByMe': [for (final f in files.files) f['ownedByMe']],
          'readFirstFileStatus': firstRead,
        };
      }
      final shared = await drive(
        account,
        'GET',
        '$api/files?q=sharedWithMe&fields=files(id)&pageSize=50',
      );
      out({
        'tripFolderStatus': folder.status,
        'tripFolderWhy': reason(folder.body),
        'canAddChildren': capabilities is Map
            ? capabilities['canAddChildren']
            : null,
        'tripChildren': [for (final f in top.files) f['name']],
        'tripChildrenStatus': top.status,
        'opsStatus': devices.status,
        'opsDevices': perDevice,
        'sharedWithMeVisibleToApp': shared.status == 200
            ? ((shared.body! as Map)['files'] as List).length
            : 'status ${shared.status}',
      });
    case 'write':
      var mine = state['ops$account'] as String?;
      String? folderWhy;
      if (mine == null) {
        try {
          mine = await createFolder(account, device, state['ops'] as String);
          state['ops$account'] = mine;
          writeJson(stateFile, state);
        } on StateError catch (error) {
          folderWhy = error.message;
        }
      }
      if (mine == null) {
        out({'created': false, 'why': folderWhy});
        return;
      }
      final seq = DateTime.now().millisecondsSinceEpoch % 1000000;
      final name = '$seq-$seq.jsonl';
      final result = await createFile(
        account,
        name,
        mine,
        fakeOperation(device, seq),
      );
      state['lastFile$account'] = name;
      state['lastWrite$account'] = DateTime.now().toUtc().toIso8601String();
      writeJson(stateFile, state);
      out({
        'status': result.status,
        'ms': result.ms,
        'file': name,
        'why': reason(result.body),
      });
    case 'wait':
      final other = account == 'A' ? 'B' : 'A';
      final name = args.length > 2
          ? args[2]
          : state['lastFile$other'] as String;
      final written = DateTime.parse(state['lastWrite$other'] as String);
      final folder = state['ops$other'] as String;
      for (var attempt = 1; attempt <= 30; attempt++) {
        final list = await children(account, folder);
        if (list.files.any((f) => f['name'] == name)) {
          out({
            'file': name,
            'visibleAfterMs': DateTime.now()
                .toUtc()
                .difference(written)
                .inMilliseconds,
            'polls': attempt,
            'listMs': list.ms,
          });
          return;
        }
        if (list.status != 200) {
          out({'file': name, 'status': list.status, 'why': list.why});
          return;
        }
        await Future<void>.delayed(const Duration(seconds: 2));
      }
      out({'file': name, 'visible': false, 'polls': 30});
    case 'changes':
      final key = 'pageToken$account';
      if (state[key] == null) {
        final start = await drive(
          account,
          'GET',
          '$api/changes/startPageToken',
        );
        state[key] = (start.body! as Map)['startPageToken'];
        writeJson(stateFile, state);
        out({'started': true, 'status': start.status, 'ms': start.ms});
        return;
      }
      final result = await drive(
        account,
        'GET',
        '$api/changes?pageToken=${state[key]}'
            '&fields=newStartPageToken,changes(fileId,removed,file(name,ownedByMe))',
      );
      final body = result.body! as Map;
      if (body['newStartPageToken'] != null) {
        state[key] = body['newStartPageToken'];
        writeJson(stateFile, state);
      }
      out({
        'status': result.status,
        'ms': result.ms,
        'changes': [
          for (final change in (body['changes'] as List?) ?? const [])
            {
              'name': ((change as Map)['file'] as Map?)?['name'],
              'ownedByMe': (change['file'] as Map?)?['ownedByMe'],
            },
        ],
      });
    default:
      stderr.writeln('Unknown command: $command');
      exitCode = 64;
  }
}
