# Test01 - ASP.NET Core Authentication API

A RESTful authentication API built with **ASP.NET Core 8**, **Entity Framework Core**, **SQL Server**, and **JWT authentication**.

The API provides user registration, login, JWT access tokens, refresh tokens, logout, and password-reset functionality.

---

## 🚀 Features

- User registration
- Secure password hashing using ASP.NET Core Identity password hashing
- User login
- JWT access token authentication
- Refresh token authentication
- Remember Me functionality
- Protected API endpoints using `[Authorize]`
- User logout
- Forgot password functionality
- Password reset token generation
- Entity Framework Core database integration
- SQL Server support
- Swagger / OpenAPI API documentation
- Environment-based configuration
- User Secrets support for local development
- Deployed ASP.NET Core API

---

## 🛠️ Technologies

- **ASP.NET Core 8**
- **C#**
- **Entity Framework Core**
- **SQL Server**
- **JWT (JSON Web Tokens)**
- **ASP.NET Core Identity PasswordHasher**
- **Swagger / OpenAPI**
- **REST API**
- **Git & GitHub**

---

## 📁 Project Structure

```text
Test01/
│
├── Context/
│   └── AppDbContext.cs
│
├── Controllers/
│   └── AuthController.cs
│
├── JWT/
│   └── JwtService.cs
│
├── Models/
│   ├── User.cs
│   ├── LoginRequest.cs
│   ├── RegisterRequest.cs
│   ├── RefreshToken.cs
│   ├── RefreshTokenRequest.cs
│   ├── ForgotPasswordRequest.cs
│   └── ...
│
├── Services/
│   ├── RefreshTokenService.cs
│   └── PasswordResetTokenService.cs
│
├── Migrations/
│
├── Program.cs
├── appsettings.json
└── Test01.csproj
