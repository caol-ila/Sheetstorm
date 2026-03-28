using Sheetstorm.Domain.Kapellenverwaltung;

namespace Sheetstorm.Infrastructure.KapelleManagement;

public interface IKapelleService
{
    Task<IReadOnlyList<KapelleDto>> GetMeineKapellenAsync(Guid musikerId);
    Task<KapelleDetailDto> GetKapelleAsync(Guid kapelleId, Guid musikerId);
    Task<KapelleDto> KapelleErstellenAsync(KapelleErstellenRequest request, Guid musikerId);
    Task<KapelleDto> KapelleBearbeitenAsync(Guid kapelleId, KapelleBearbeitenRequest request, Guid musikerId);
    Task KapelleLoeschenAsync(Guid kapelleId, Guid musikerId);
    Task<IReadOnlyList<MitgliedDto>> GetMitgliederAsync(Guid kapelleId, Guid musikerId);
    Task<EinladungDto> EinladungErstellenAsync(Guid kapelleId, EinladungErstellenRequest request, Guid musikerId);
    Task<KapelleDto> BeitretenAsync(BeitretenRequest request, Guid musikerId);
    Task RolleAendernAsync(Guid kapelleId, Guid userId, RolleAendernRequest request, Guid musikerId);
    Task MitgliedEntfernenAsync(Guid kapelleId, Guid userId, Guid musikerId);
}
