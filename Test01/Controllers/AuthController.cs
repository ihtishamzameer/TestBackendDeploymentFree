using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Test01.Context;
using Test01.JWT;
using Test01.Models;

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

        public AuthController(AppDbContext context,IJwtService jwtService,IPasswordHasher<User> passwordHasher,ILogger<AuthController> logger)
        {
            _context = context;
            _jwtService = jwtService;
            _passwordHasher = passwordHasher;
            _logger = logger;
        }

        [Authorize]
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

        //[Authorize]
        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            if (!ModelState.IsValid)
                return ValidationProblem(ModelState);

            try
            {
                var user = await _context.Users.FirstOrDefaultAsync(x =>x.Username == request.Username);

                if (user == null)
                {
                    return Unauthorized(new
                    {
                        message = "Invalid username or password."
                    });
                }

                var passwordResult =_passwordHasher.VerifyHashedPassword(user,user.PasswordHash,request.Password);

                if (passwordResult == PasswordVerificationResult.Failed)
                {
                    return Unauthorized(new
                    {
                        message = "Invalid username or password."
                    });
                }

                var token = _jwtService.GenerateToken(user,request.RememberMe);

                return Ok(new
                {
                    token,
                    rememberMe = request.RememberMe
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex,"Error occurred during login for user {Username}",request.Username);

                return StatusCode(StatusCodes.Status500InternalServerError,
                    new
                    {
                        message = "An error occurred during login."
                    });
            }
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

        [Authorize]
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