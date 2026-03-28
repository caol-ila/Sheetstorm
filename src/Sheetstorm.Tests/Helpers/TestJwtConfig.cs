using Microsoft.Extensions.Configuration;

namespace Sheetstorm.Tests.Helpers;

public static class TestJwtConfig
{
    public const string Key = "TestSecretKey-MustBe32BytesMinimumForHMAC256Algorithm!";
    public const string Issuer = "sheetstorm-test";
    public const string Audience = "sheetstorm-test-audience";

    public static IConfiguration Create() =>
        new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Jwt:Key"] = Key,
                ["Jwt:Issuer"] = Issuer,
                ["Jwt:Audience"] = Audience
            })
            .Build();
}
