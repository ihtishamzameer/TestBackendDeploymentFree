using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Test01.Context;
using Test01.JWT;
using Test01.Models;
using Test01.Models.Test01.Models;
using Test01.Servies;

namespace Test01.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly IJwtService _jwtService;
        private readonly IPasswordHasher<User> _passwordHasher;
        private readonly ILogger<AuthController> _logger;
        private readonly RefreshTokenService _refreshTokenService;
        private readonly PasswordResetTokenService _passwordResetTokenService;

        public AuthController(AppDbContext context,IJwtService jwtService,IPasswordHasher<User> passwordHasher,ILogger<AuthController> logger, RefreshTokenService refreshTokenService, PasswordResetTokenService passwordResetTokenService)
        {
            _context = context;
            _jwtService = jwtService;
            _passwordHasher = passwordHasher;
            _logger = logger;
            _refreshTokenService = refreshTokenService;
            _passwordResetTokenService = passwordResetTokenService;
        }

        [AllowAnonymous]
        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterRequest request)
        {
            if (!ModelState.IsValid)
                return ValidationProblem(ModelState);

            try
            {
                var usernameExists = await _context.Users.AnyAsync(x => x.Username == request.Username);

                if (usernameExists)
                {
                    return Conflict(new
                    {
                        message = "Username already exists."
                    });
                }

                var user = new User
                {
                    Username = request.Username
                };

                user.PasswordHash = _passwordHasher.HashPassword(user,request.Password);

                _context.Users.Add(user);

                await _context.SaveChangesAsync();

                return StatusCode(StatusCodes.Status201Created, new
                {
                    message = "Registration successful."
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex,"Error occurred while registering user {Username}",request.Username);

                return StatusCode(StatusCodes.Status500InternalServerError,
                    new
                    {
                        message = "An error occurred while registering the user."
                    });
            }
        }

        [AllowAnonymous]
        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            if (!ModelState.IsValid)
                return ValidationProblem(ModelState);

            var user = await _context.Users
                .FirstOrDefaultAsync(x => x.Username == request.Username);

            if (user == null)
            {
                return Unauthorized(new
                {
                    message = "Invalid username or password."
                });
            }

            var passwordResult = _passwordHasher.VerifyHashedPassword(
                    user,
                    user.PasswordHash,
                    request.Password
                );

            if (passwordResult == PasswordVerificationResult.Failed)
            {
                return Unauthorized(new
                {
                    message = "Invalid username or password."
                });
            }

            // Generate access token
            var accessToken = _jwtService.GenerateToken(
                user,
                request.RememberMe
            );

            // Generate refresh token
            var refreshTokenValue =_refreshTokenService.GenerateRefreshToken();

            var refreshToken = new RefreshToken
            {
                Token = refreshTokenValue,
                UserId = user.Id,
                CreatedAt = DateTime.UtcNow,
                ExpiresAt = request.RememberMe
                    ? DateTime.UtcNow.AddDays(30)
                    : DateTime.UtcNow.AddDays(7)
            };

            _context.RefreshTokens.Add(refreshToken);

            await _context.SaveChangesAsync();

            return Ok(new
            {
                accessToken,
                refreshToken = refreshTokenValue
            });
        }

       
        [HttpPost("refresh")]
        public async Task<IActionResult> Refresh([FromBody] RefreshTokenRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.RefreshToken))
            {
                return BadRequest(new
                {
                    message = "Refresh token is required."
                });
            }

            var oldRefreshToken = await _context.RefreshTokens.Include(x => x.User).FirstOrDefaultAsync(x => x.Token == request.RefreshToken);

            if (oldRefreshToken == null)
            {
                return Unauthorized(new
                {
                    message = "Invalid refresh token."
                });
            }

            if (oldRefreshToken.IsRevoked)
            {
                return Unauthorized(new
                {
                    message = "Refresh token has been revoked."
                });
            }

            if (oldRefreshToken.IsExpired)
            {
                return Unauthorized(new
                {
                    message = "Refresh token has expired."
                });
            }

            // Revoke the old refresh token
            oldRefreshToken.RevokedAt = DateTime.UtcNow;

            // Generate new access token
            var accessToken = _jwtService.GenerateToken(
                oldRefreshToken.User,
                false
            );

            // Generate new refresh token
            var newRefreshTokenValue =_refreshTokenService.GenerateRefreshToken();

            var newRefreshToken = new RefreshToken
            {
                Token = newRefreshTokenValue,
                UserId = oldRefreshToken.UserId,
                CreatedAt = DateTime.UtcNow,
                //ExpiresAt = DateTime.UtcNow.AddDays(7)
                ExpiresAt = oldRefreshToken.ExpiresAt
            };

            _context.RefreshTokens.Add(newRefreshToken);

            await _context.SaveChangesAsync();

            return Ok(new
            {
                accessToken,
                refreshToken = newRefreshTokenValue
            });
        }

        [HttpPost("forgot-password")]
        public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordRequest request)
        {
            if (!ModelState.IsValid)
                return ValidationProblem(ModelState);

            if (string.IsNullOrWhiteSpace(request.Email))
            {
                return BadRequest(new
                {
                    message = "Email is required."
                });
            }

            var user = await _context.Users
                .FirstOrDefaultAsync(x => x.Email == request.Email);

            // Do not reveal whether the email exists.
            if (user == null)
            {
                return Ok(new
                {
                    message = "If an account exists with this email, a password reset link has been sent."
                });
            }

            var rawToken = _passwordResetTokenService.GenerateToken();

            var hashedToken =
                _passwordResetTokenService.HashToken(rawToken);

            var resetToken = new PasswordResetToken
            {
                Token = hashedToken,
                UserId = user.Id,
                CreatedAt = DateTime.UtcNow,
                ExpiresAt = DateTime.UtcNow.AddMinutes(15)
            };

            _context.PasswordResetTokens.Add(resetToken);

            await _context.SaveChangesAsync();

            // TEMPORARY FOR DEVELOPMENT
            // We will replace this with an email service.
            return Ok(new
            {
                message = "If an account exists with this email, a password reset link has been sent.",
                resetToken = rawToken
            });
        }

        [Authorize]
        [HttpPost("logout")]
        public IActionResult Logout()
        {
            return Ok(new
            {
                message = "Logout successful."
            });
        }

        [AllowAnonymous]
        [HttpGet("test")]
        public IActionResult Test()
        {
            return Ok(new
            {
                message = "Test successful"
            });
        }
    }
}