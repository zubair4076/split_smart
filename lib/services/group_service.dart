import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';

class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new group
  Future<GroupModel> createGroup({
    required String name,
    required String adminId,
    required double initialAmount,
  }) async {
    try {
      final docRef = _firestore.collection('groups').doc();
      final group = GroupModel(
        id: docRef.id,
        name: name,
        adminId: adminId,
        memberIds: [adminId],
        createdAt: DateTime.now(),
        initialAmount: initialAmount,
        memberBalances: {adminId: initialAmount},
      );

      await docRef.set(group.toMap());

      // Add group to user's groupIds
      await _firestore.collection('users').doc(adminId).update({
        'groupIds': FieldValue.arrayUnion([docRef.id]),
      });

      return group;
    } catch (e) {
      rethrow;
    }
  }

  // Get group by ID
  Future<GroupModel?> getGroup(String groupId) async {
    try {
      final doc = await _firestore.collection('groups').doc(groupId).get();
      if (doc.exists) {
        return GroupModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Get user's groups
  Stream<List<GroupModel>> getUserGroups(String userId) {
    return _firestore
        .collection('groups')
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => GroupModel.fromMap(doc.data()))
          .toList();
    });
  }

  // Add member to group
  Future<void> addMemberToGroup(String groupId, String userId) async {
    try {
      // Get user data
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        throw 'User not found';
      }

      // Add user to group
      await _firestore.collection('groups').doc(groupId).update({
        'memberIds': FieldValue.arrayUnion([userId]),
        'memberBalances.$userId': 0.0,
      });

      // Add group to user's groupIds
      await _firestore.collection('users').doc(userId).update({
        'groupIds': FieldValue.arrayUnion([groupId]),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Remove member from group
  Future<void> removeMemberFromGroup(String groupId, String userId) async {
    try {
      // Remove user from group
      await _firestore.collection('groups').doc(groupId).update({
        'memberIds': FieldValue.arrayRemove([userId]),
        'memberBalances.$userId': FieldValue.delete(),
      });

      // Remove group from user's groupIds
      await _firestore.collection('users').doc(userId).update({
        'groupIds': FieldValue.arrayRemove([groupId]),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Update group details
  Future<void> updateGroup(String groupId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('groups').doc(groupId).update(data);
    } catch (e) {
      rethrow;
    }
  }

  // Delete group
  Future<void> deleteGroup(String groupId) async {
    try {
      // Get group data
      final group = await getGroup(groupId);
      if (group != null) {
        // Remove group from all members' groupIds
        for (String memberId in group.memberIds) {
          await _firestore.collection('users').doc(memberId).update({
            'groupIds': FieldValue.arrayRemove([groupId]),
          });
        }

        // Delete group document
        await _firestore.collection('groups').doc(groupId).delete();
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get group members
  Future<List<UserModel>> getGroupMembers(String groupId) async {
    try {
      final group = await getGroup(groupId);
      if (group == null) return [];

      final memberDocs = await Future.wait(
        group.memberIds.map((memberId) =>
            _firestore.collection('users').doc(memberId).get()),
      );

      return memberDocs
          .where((doc) => doc.exists)
          .map((doc) => UserModel.fromMap(doc.data()!))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
} 