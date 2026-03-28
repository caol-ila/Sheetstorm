using System.IdentityModel.Tokens.Jwt;
using Moq;
using Sheetstorm.Domain.Auth;
using Sheetstorm.Infrastructure.Auth;
using Sheetstorm.Infrastructure.Email;
using Sheetstorm.Infrastructure.Persistence;
using Sheetstorm.Tests.Helpers;
using Xunit;

namespace Sheetstorm.Tests.Auth;

public class JwtGenerationTests : IDisposable
{
    private readonly AppDbContext _db;
    private readonly AuthService _sut;

    private const string ValidPassword = "Password1!";
    private const string ValidEmail = "jwt@example.com";
    private const string ValidDisplayName = "JWT Test User";

    public JwtGenerationTests()
    {
        _db = TestDbContextFactory.Create();
        var emailService = new Mock<IEmailService>().Object;
        _sut = new AuthService(_db, TestJwtConfig.Create(), emailService);
    }

    [Fact]
    public async Task GeneratedToken_ContainsCorrectClaims()
    {
        var request = new RegisterRequest(ValidEmail, ValidPassword, ValidDisplayName, null);
        var response = await _sut.RegisterAsync(request);

        var handler = new JwtSecurityTokenHandler();
        var token = handler.ReadJwtToken(response.AccessToken);

        var Musician = _db.Musicians.Single();

        Assert.Equal(Musician.Id.ToString(), token.Subject);
        Assert.Equal(ValidEmail,
            token.Claims.First(c => c.Type == JwtRegisteredClaimNames.Email).Value);
        Assert.Equal(ValidDisplayName,
            token.Claims.First(c => c.Type == JwtRegisteredClaimNames.Name).Value);
        Assert.NotEmpty(
            token.Claims.First(c => c.Type == JwtRegisteredClaimNames.Jti).Value);

        Assert.Equal(TestJwtConfig.Issuer, token.Issuer);
        Assert.Contains(TestJwtConfig.Audience, token.Audiences);
    }

    [Fact]
    public async Task GeneratedToken_ExpiresAfter900Seconds()
    {
        var before = DateTime.UtcNow;
        var request = new RegisterRequest(ValidEmail, ValidPassword, ValidDisplayName, null);
        var response = await _sut.RegisterAsync(request);

        var handler = new JwtSecurityTokenHandler();
        var token = handler.ReadJwtToken(response.AccessToken);

        var expectedExpiry = before.AddSeconds(900);
        // Allow ±5 second tolerance for test execution time
        Assert.True(token.ValidTo >= expectedExpiry.AddSeconds(-5),
            $"Token expires too early: {token.ValidTo} < {expectedExpiry.AddSeconds(-5)}");
        Assert.True(token.ValidTo <= expectedExpiry.AddSeconds(10),
            $"Token expires too late: {token.ValidTo} > {expectedExpiry.AddSeconds(10)}");
    }

    [Fact]
    public async Task AuthResponse_ExpiresIn_Is900AndTokenTypeIsBearer()
    {
        var request = new RegisterRequest(ValidEmail, ValidPassword, ValidDisplayName, null);

        var response = await _sut.RegisterAsync(request);

        Assert.Equal(900, response.ExpiresIn);
        Assert.Equal("Bearer", response.TokenType);
    }

    [Fact]
    public async Task EachToken_HasUniqueJti()
    {
        var request = new RegisterRequest(ValidEmail, ValidPassword, ValidDisplayName, null);
        var response1 = await _sut.RegisterAsync(request);

        // Mark email as verified so login is allowed
        var Musician = _db.Musicians.Single();
        Musician.EmailVerified = true;
        await _db.SaveChangesAsync();

        // Login to get a second token
        var loginResponse = await _sut.LoginAsync(new LoginRequest(ValidEmail, ValidPassword));

        var handler = new JwtSecurityTokenHandler();
        var token1 = handler.ReadJwtToken(response1.AccessToken);
        var token2 = handler.ReadJwtToken(loginResponse.AccessToken);

        var jti1 = token1.Claims.First(c => c.Type == JwtRegisteredClaimNames.Jti).Value;
        var jti2 = token2.Claims.First(c => c.Type == JwtRegisteredClaimNames.Jti).Value;

        Assert.NotEqual(jti1, jti2);
    }

    public void Dispose() => _db.Dispose();
}
