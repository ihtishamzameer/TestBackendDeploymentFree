namespace Test01.Models
{
    namespace Test01.Models
    {
        public class PasswordResetToken
        {
            public int Id { get; set; }

            public string Token { get; set; } = string.Empty;

            public DateTime CreatedAt { get; set; }

            public DateTime ExpiresAt { get; set; }

            public DateTime? UsedAt { get; set; }

            public bool IsUsed => UsedAt.HasValue;

            public bool IsExpired => DateTime.UtcNow >= ExpiresAt;

            public int UserId { get; set; }

            public User User { get; set; } = null!;
        }
    }
}
