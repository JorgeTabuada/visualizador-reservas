import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/project_entity.dart';
import '../../../../core/constants/app_constants.dart';

/// Interface do repositório de projetos
abstract class ProjectsRepository {
  Future<List<ProjectEntity>> getProjects({String? organizationId});
  Future<ProjectEntity?> getProjectById(String id);
  Future<ProjectEntity> createProject(ProjectEntity project);
  Future<ProjectEntity> updateProject(ProjectEntity project);
  Future<void> deleteProject(String id);
  Future<void> updateBudgetSpent(String projectId, double amount);
}

/// Implementação do repositório de projetos
class ProjectsRepositoryImpl implements ProjectsRepository {
  final FirebaseFirestore firestore;

  ProjectsRepositoryImpl({required this.firestore});

  CollectionReference get _projectsCollection =>
      firestore.collection(AppConstants.projectsCollection);

  @override
  Future<List<ProjectEntity>> getProjects({String? organizationId}) async {
    Query query = _projectsCollection.orderBy('name');

    if (organizationId != null) {
      query = query.where('organizationId', isEqualTo: organizationId);
    }

    final snapshot = await query.get();

    return snapshot.docs.map((doc) {
      return _projectFromDocument(doc);
    }).toList();
  }

  @override
  Future<ProjectEntity?> getProjectById(String id) async {
    final doc = await _projectsCollection.doc(id).get();
    if (!doc.exists) return null;
    return _projectFromDocument(doc);
  }

  @override
  Future<ProjectEntity> createProject(ProjectEntity project) async {
    final docRef = _projectsCollection.doc();
    final data = _projectToMap(project);
    data['createdAt'] = FieldValue.serverTimestamp();

    await docRef.set(data);

    return project.copyWith(id: docRef.id);
  }

  @override
  Future<ProjectEntity> updateProject(ProjectEntity project) async {
    final data = _projectToMap(project);
    data['updatedAt'] = FieldValue.serverTimestamp();

    await _projectsCollection.doc(project.id).update(data);

    final updatedDoc = await _projectsCollection.doc(project.id).get();
    return _projectFromDocument(updatedDoc);
  }

  @override
  Future<void> deleteProject(String id) async {
    await _projectsCollection.doc(id).delete();
  }

  @override
  Future<void> updateBudgetSpent(String projectId, double amount) async {
    await firestore.runTransaction((transaction) async {
      final docRef = _projectsCollection.doc(projectId);
      final doc = await transaction.get(docRef);

      if (!doc.exists) throw Exception('Projeto não encontrado');

      final data = doc.data() as Map<String, dynamic>;
      final budgetData = data['budget'] as Map<String, dynamic>? ?? {};
      final currentSpent = (budgetData['spent'] as num?)?.toDouble() ?? 0.0;
      final total = (budgetData['total'] as num?)?.toDouble() ?? 0.0;

      final newSpent = currentSpent + amount;
      final newRemaining = total - newSpent;

      transaction.update(docRef, {
        'budget.spent': newSpent,
        'budget.remaining': newRemaining,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  ProjectEntity _projectFromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ProjectEntity(
      id: doc.id,
      organizationId: data['organizationId'] as String,
      name: data['name'] as String,
      code: data['code'] as String? ?? '',
      type: ProjectType.fromString(data['type'] as String? ?? 'other'),
      status: ProjectStatus.fromString(data['status'] as String? ?? 'active'),
      budget: data['budget'] != null
          ? ProjectBudget.fromJson(data['budget'] as Map<String, dynamic>)
          : const ProjectBudget(),
      managerId: data['managerId'] as String?,
      departmentId: data['departmentId'] as String?,
      startDate: data['startDate'] != null
          ? (data['startDate'] as Timestamp).toDate()
          : null,
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : null,
      metadata: data['metadata'] as Map<String, dynamic>?,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> _projectToMap(ProjectEntity project) {
    return {
      'organizationId': project.organizationId,
      'name': project.name,
      'code': project.code,
      'type': project.type.value,
      'status': project.status.value,
      'budget': project.budget.toJson(),
      'managerId': project.managerId,
      'departmentId': project.departmentId,
      'startDate':
          project.startDate != null ? Timestamp.fromDate(project.startDate!) : null,
      'endDate':
          project.endDate != null ? Timestamp.fromDate(project.endDate!) : null,
      'metadata': project.metadata,
    };
  }
}
