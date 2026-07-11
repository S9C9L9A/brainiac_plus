/// Kinds of entities the knowledge graph tracks.
enum NodeType { task, file, command, agent, project, note, unknown }

/// Kinds of relations between entities.
enum EdgeRelation { wrote, ran, produced, relatedTo, partOf, unknown }

/// A vertex in the shared knowledge graph.
class GraphNode {
  final String id;
  final NodeType type;
  final String label;
  final Map<String, String> props;

  const GraphNode({
    required this.id,
    required this.type,
    required this.label,
    this.props = const {},
  });

  GraphNode mergeProps(Map<String, String> extra) =>
      GraphNode(id: id, type: type, label: label, props: {...props, ...extra});

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'label': label,
    'props': props,
  };

  factory GraphNode.fromJson(Map<String, dynamic> json) => GraphNode(
    id: json['id'] as String,
    type: NodeType.values.firstWhere(
      (t) => t.name == json['type'],
      orElse: () => NodeType.unknown,
    ),
    label: json['label'] as String? ?? '',
    props:
        (json['props'] as Map?)?.map(
          (k, v) => MapEntry(k.toString(), v.toString()),
        ) ??
        const {},
  );
}

/// A directed relation between two nodes.
class GraphEdge {
  final String from;
  final String to;
  final EdgeRelation relation;

  const GraphEdge({
    required this.from,
    required this.to,
    required this.relation,
  });

  String get key => '$from|${relation.name}|$to';

  Map<String, dynamic> toJson() => {
    'from': from,
    'to': to,
    'relation': relation.name,
  };

  factory GraphEdge.fromJson(Map<String, dynamic> json) => GraphEdge(
    from: json['from'] as String,
    to: json['to'] as String,
    relation: EdgeRelation.values.firstWhere(
      (r) => r.name == json['relation'],
      orElse: () => EdgeRelation.unknown,
    ),
  );
}

/// The shared, persistent memory the assistant and its agents read and write:
/// what tasks ran, which files they touched, which commands they executed, and
/// how those relate. In-app and self-contained; a future sync to an external
/// graph store (Neo4j / graphify) can serialize this same structure.
class KnowledgeGraph {
  final Map<String, GraphNode> _nodes = {};
  final Map<String, GraphEdge> _edges = {};

  KnowledgeGraph();

  List<GraphNode> get nodes => _nodes.values.toList();
  List<GraphEdge> get edges => _edges.values.toList();

  /// Inserts [node], or merges its props into the existing node with that id.
  void upsertNode(GraphNode node) {
    final existing = _nodes[node.id];
    _nodes[node.id] = existing == null ? node : existing.mergeProps(node.props);
  }

  GraphNode? nodeById(String id) => _nodes[id];

  /// Adds a relation; a duplicate (same from/relation/to) is ignored.
  void addEdge(String from, String to, EdgeRelation relation) {
    final edge = GraphEdge(from: from, to: to, relation: relation);
    _edges[edge.key] = edge;
  }

  /// Nodes directly reachable from [id] via any outgoing edge.
  List<GraphNode> neighbors(String id) {
    return _edges.values
        .where((e) => e.from == id)
        .map((e) => _nodes[e.to])
        .whereType<GraphNode>()
        .toList();
  }

  List<GraphNode> nodesOfType(NodeType type) =>
      _nodes.values.where((n) => n.type == type).toList();

  Map<String, dynamic> toJson() => {
    'nodes': _nodes.values.map((n) => n.toJson()).toList(),
    'edges': _edges.values.map((e) => e.toJson()).toList(),
  };

  factory KnowledgeGraph.fromJson(Map<String, dynamic> json) {
    final g = KnowledgeGraph();
    for (final n in (json['nodes'] as List? ?? const [])) {
      g.upsertNode(GraphNode.fromJson(n as Map<String, dynamic>));
    }
    for (final e in (json['edges'] as List? ?? const [])) {
      final edge = GraphEdge.fromJson(e as Map<String, dynamic>);
      g.addEdge(edge.from, edge.to, edge.relation);
    }
    return g;
  }
}
