using System.Security.Cryptography;

namespace Sheetstorm.Web.Services;

public static class TokenHasher
{
    public static string Hash(string token)
    {
        var bytes = SHA256.HashData(System.Text.Encoding.UTF8.GetBytes(token));
        return Convert.ToHexString(bytes);
    }

    public static string GenerateUrlToken(int byteLength = 32)
    {
        var buf = RandomNumberGenerator.GetBytes(byteLength);
        return Convert.ToBase64String(buf).Replace("+", "-").Replace("/", "_").TrimEnd('=');
    }

    public static string GenerateJoinCode()
    {
        const string alphabet = "ABCDEFGHJKMNPQRSTUVWXYZ23456789";
        var buf = RandomNumberGenerator.GetBytes(8);
        return new string(buf.Select(b => alphabet[b % alphabet.Length]).ToArray());
    }
}
