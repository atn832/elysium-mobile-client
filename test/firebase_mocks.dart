
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/mockito.dart';

class MockFirestoreInstance extends Mock implements Firestore {
  Map<String, dynamic> root = Map();

  @override
  CollectionReference collection(String path) {
    return MockCollectionReference(getSubpath(root, path));
  }

  @override
  DocumentReference document(String path) {
    return MockDocumentReference(path, getSubpath(root, path));
  }

  WriteBatch batch() {
    return MockWriteBatch();
  }

  String dump() {
    JsonEncoder encoder = new JsonEncoder.withIndent('  ', myEncode);
    final jsonText = encoder.convert(root);
    return jsonText;
  }
}

dynamic myEncode(dynamic item) {
  if (item is DateTime) {
    return item.toIso8601String();
  } else if (item is Timestamp) {
    return item.toDate().toIso8601String();
  } else if (item is FieldValue) {
    return item.type.toString();
  }
  return item;
}

dynamic getSubpath(Map<String, dynamic> root, String path) {
  if (root[path] == null) {
    root[path] = Map<String, dynamic>();
  }
  return root[path];
}

class MockWriteBatch extends Mock implements WriteBatch {
  List<WriteTask> tasks = [];

  @override
  void setData(DocumentReference document, Map<String, dynamic> data,
      {bool merge = false}) {
    tasks.add(WriteTask()
      ..document = document
      ..data = data
      ..merge = merge);
  }

  @override
  Future<void> commit() {
    for (final task in tasks) {
      task.document.setData(task.data, merge: task.merge);
    }
    tasks.clear();
    return Future.value();
  }
}

class WriteTask {
  DocumentReference document;
  Map<String, dynamic> data;
  bool merge;
}

class MockCollectionReference extends Mock implements CollectionReference {
  final Map<String, dynamic> root;
  String currentChildId = '';

  MockCollectionReference(this.root);

  @override
  DocumentReference document([String path]) {
    return MockDocumentReference(path, getSubpath(root, path));
  }

  @override
  Future<DocumentReference> add(Map<String, dynamic> data) {
    currentChildId += 'z';
    root[currentChildId] = data;
    return Future.value(document(currentChildId));
  }

  @override
  Query where(String field,
      {isEqualTo,
        isLessThan,
        isLessThanOrEqualTo,
        isGreaterThan,
        isGreaterThanOrEqualTo,
        arrayContains,
        bool isNull}) {
    final matchingDocuments = root.entries
        .where((entry) {
      final document = entry.value;
      return document[field] == isEqualTo;
    })
        .map((entry) => MockDocumentSnapshot(entry.key, entry.value))
        .toList();
    return MockQuery(matchingDocuments);
  }
}

class MockQuery extends Mock implements Query {
  List<DocumentSnapshot> documents;

  MockQuery(this.documents);

  @override
  Future<QuerySnapshot> getDocuments({Source source = Source.serverAndCache}) {
    return Future.value(MockSnapshot(documents));
  }
}

class MockSnapshot extends Mock implements QuerySnapshot {
  List<DocumentSnapshot> _documents;

  MockSnapshot(this._documents);

  @override
  List<DocumentSnapshot> get documents => _documents;
}

class MockDocumentSnapshot extends Mock implements DocumentSnapshot {
  final String _documentId;
  final Map<String, dynamic> _document;

  MockDocumentSnapshot(this._documentId, this._document);

  @override
  String get documentID => _documentId;

  @override
  dynamic operator [](String key) {
    return _document[key];
  }

  @override
  Map<String, dynamic> get data => _document;
}

class MockDocumentReference extends Mock implements DocumentReference {
  final String _documentId;
  final Map<String, dynamic> root;

  MockDocumentReference(this._documentId, this.root);

  @override
  String get documentID => _documentId;

  @override
  CollectionReference collection(String collectionPath) {
    return MockCollectionReference(getSubpath(root, collectionPath));
  }

  @override
  Future<void> updateData(Map<String, dynamic> data) {
    data.forEach((key, value) {
      if (value is FieldValue) {
        switch (value.type) {
          case FieldValueType.delete:
            root.remove(key);
            break;
          default:
            throw Exception('Not implemented');
        }
      } else {
        root[key] = value;
      }
    });
    return Future.value(null);
  }

  @override
  Future<void> setData(Map<String, dynamic> data, {bool merge = false}) {
    if (!merge) {
      root.clear();
    }
    return updateData(data);
  }

  @override
  Future<DocumentSnapshot> get({Source source = Source.serverAndCache}) {
    return Future.value(MockDocumentSnapshot(_documentId, root));
  }
}
