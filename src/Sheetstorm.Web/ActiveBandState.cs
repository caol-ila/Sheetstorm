namespace Sheetstorm.Web;

/// <summary>
/// Hält die aktuell aktive Band-Mitgliedschaft im Server-Circuit.
/// </summary>
public sealed class ActiveBandState
{
    public Guid? ActiveBandId { get; private set; }
    public string? ActiveBandName { get; private set; }
    public string? ActiveBandSlug { get; private set; }

    public event Action? Changed;

    public void SetActive(Guid id, string name, string slug)
    {
        ActiveBandId = id;
        ActiveBandName = name;
        ActiveBandSlug = slug;
        Changed?.Invoke();
    }

    public void Clear()
    {
        ActiveBandId = null;
        ActiveBandName = null;
        ActiveBandSlug = null;
        Changed?.Invoke();
    }
}
