using System.Security.Cryptography;

namespace Test01.Servies
{
    public class RefreshTokenService
    {
        public string GenerateRefreshToken()
        {
            var randomBytes = RandomNumberGenerator.GetBytes(64);

            return Convert.ToBase64String(randomBytes);
        }
    }
}