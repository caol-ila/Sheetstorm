using Sheetstorm.Domain.BandManagement;

namespace Sheetstorm.Infrastructure.BandManagement;

public interface IBandService
{
    Task<IReadOnlyList<BandDto>> GetMyBandsAsync(Guid musicianId);
    Task<BandDetailDto> GetBandAsync(Guid bandId, Guid musicianId);
    Task<BandDto> CreateBandAsync(CreateBandRequest request, Guid musicianId);
    Task<BandDto> UpdateBandAsync(Guid bandId, UpdateBandRequest request, Guid musicianId);
    Task DeleteBandAsync(Guid bandId, Guid musicianId);
    Task<IReadOnlyList<MemberDto>> GetMembersAsync(Guid bandId, Guid musicianId);
    Task<InvitationDto> CreateInvitationAsync(Guid bandId, CreateInvitationRequest request, Guid musicianId);
    Task<BandDto> JoinAsync(JoinRequest request, Guid musicianId);
    Task ChangeRoleAsync(Guid bandId, Guid userId, ChangeRoleRequest request, Guid musicianId);
    Task RemoveMemberAsync(Guid bandId, Guid userId, Guid musicianId);

    // Voices-Override
    Task<VoiceMappingResponse> GetVoiceMappingAsync(Guid bandId, Guid musicianId);
    Task<VoiceMappingResponse> SetVoiceMappingAsync(Guid bandId, SetVoiceMappingRequest request, Guid musicianId);
    Task SetUserVoicesAsync(Guid bandId, Guid userId, UserVoicesRequest request, Guid musicianId);
}
