using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Test01.Context;
using Test01.Models;

namespace Test01.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthController : ControllerBase
    {
        private readonly AppDbContext _context;

        public AuthController(AppDbContext context)
        {
            this._context = context;
        }

        [HttpPost]
        [Route("login")]
        public IActionResult Login([FromBody] LoginRequest request)
        {
            return Ok(new { message = "Login successful" });
        }

        [HttpPost]
        [Route("register")]
        public IActionResult Register([FromBody] RegisterRequest request)
        {
            return Ok(new { message = "Register successful" });
        }
    }
}
