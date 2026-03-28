import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sheetstorm/features/band/data/models/band_models.dart';
import 'package:sheetstorm/shared/services/api_client.dart';

part 'band_service.g.dart';

@Riverpod(keepAlive: true)
BandService bandService(Ref ref) {
  final dio = ref.read(apiClientProvider);
  return BandService(dio);
}

/// HTTP layer for Kapellen endpoints.
class BandService {
  final Dio _dio;

  BandService(this._dio);

  // ─── Kapellen CRUD ──────────────────────────────────────────────────────────

  Future<List<Band>> getBands() async {
    final res = await _dio.get<List<dynamic>>('/api/v1/bands');
    return res.data!
        .map((e) => Band.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Band> getBandDetail(String id) async {
    final res = await _dio.get<Map<String, dynamic>>('/api/v1/bands/$id');
    return Band.fromJson(res.data!);
  }

  Future<Band> createBand({
    required String name,
    String? description,
    String? location,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/bands',
      data: {
        'name': name,
        if (description != null) 'description': description,
        if (location != null) 'location': location,
      },
    );
    return Band.fromJson(res.data!);
  }

  Future<Band> updateBand(
    String id, {
    String? name,
    String? description,
    String? location,
  }) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/api/v1/bands/$id',
      data: {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (location != null) 'location': location,
      },
    );
    return Band.fromJson(res.data!);
  }

  Future<void> deleteBand(String id) async {
    await _dio.delete<void>('/api/v1/bands/$id');
  }

  // ─── Mitglieder ─────────────────────────────────────────────────────────────

  Future<List<Member>> getMembers(String bandId) async {
    final res = await _dio
        .get<List<dynamic>>('/api/v1/bands/$bandId/members');
    return res.data!
        .map((e) => Member.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Member> updateMemberRoles(
    String bandId,
    String musicianId,
    List<BandRole> roles,
  ) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/api/v1/bands/$bandId/members/$musicianId/roles',
      data: {'roles': roles.map((r) => r.toJson()).toList()},
    );
    return Member.fromJson(res.data!);
  }

  Future<void> removeMember(String bandId, String musicianId) async {
    await _dio
        .delete<void>('/api/v1/bands/$bandId/members/$musicianId');
  }

  Future<void> leaveBand(String bandId) async {
    await _dio.post<void>('/api/v1/bands/$bandId/leave');
  }

  // ─── Einladungen ────────────────────────────────────────────────────────────

  Future<List<Invitation>> getInvitations(String bandId) async {
    final res = await _dio
        .get<List<dynamic>>('/api/v1/bands/$bandId/invitations');
    return res.data!
        .map((e) => Invitation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Invitation> createEmailInvitation(
    String bandId,
    String email,
    BandRole role, {
    int expiryDays = 7,
    String? message,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/bands/$bandId/invitations',
      data: {
        'typ': 'email',
        'email': email,
        'role': role.toJson(),
        'expiry_days': expiryDays,
        if (message != null) 'message': message,
      },
    );
    return Invitation.fromJson(res.data!);
  }

  Future<Invitation> createLinkInvitation(
    String bandId,
    BandRole role, {
    int expiryDays = 7,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/bands/$bandId/invitations',
      data: {
        'typ': 'link',
        'role': role.toJson(),
        'expiry_days': expiryDays,
      },
    );
    return Invitation.fromJson(res.data!);
  }

  Future<void> revokeInvitation(String bandId, String invitationId) async {
    await _dio.delete<void>(
      '/api/v1/bands/$bandId/invitations/$invitationId',
    );
  }

  Future<void> acceptInvitation(String token) async {
    await _dio.post<void>('/api/v1/invitations/$token/accept');
  }

  // ─── Register ───────────────────────────────────────────────────────────────

  Future<List<Section>> getSection(String bandId) async {
    final res = await _dio
        .get<List<dynamic>>('/api/v1/bands/$bandId/sections');
    return res.data!
        .map((e) => Section.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Section> createSection(
    String bandId,
    String name, {
    String? description,
    String? color,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/bands/$bandId/sections',
      data: {
        'name': name,
        if (description != null) 'description': description,
        if (color != null) 'color': color,
      },
    );
    return Section.fromJson(res.data!);
  }

  Future<Section> updateSection(
    String bandId,
    String registerId,
    String name, {
    String? description,
    String? color,
  }) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/api/v1/bands/$bandId/sections/$registerId',
      data: {
        'name': name,
        if (description != null) 'description': description,
        if (color != null) 'color': color,
      },
    );
    return Section.fromJson(res.data!);
  }

  Future<void> deleteSection(String bandId, String registerId) async {
    await _dio
        .delete<void>('/api/v1/bands/$bandId/sections/$registerId');
  }
}
