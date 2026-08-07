using Test01.Models;

namespace Test01.JWT
{
    public interface IJwtService
    {
        string GenerateToken(User model);
    }
}
