namespace Sheetstorm.Web;

public sealed record PushSubscriptionDto(string Endpoint, string P256dh, string Auth);
public sealed record ConductorKeyDto(string PublicKeyBase64);
public sealed record AnnotationSaveDto(string LayerJson);
