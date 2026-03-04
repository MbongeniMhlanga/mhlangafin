# Run from repo root: PowerShell -ExecutionPolicy Bypass -File .\scripts\scaffold-backend.ps1

$files = @{
  "Backend\Backend.csproj" = @'
<?xml version="1.0" encoding="utf-8"?>
<Project Sdk="Microsoft.NET.Sdk.Web">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Microsoft.AspNetCore.OpenApi" Version="10.0.3" />
    <PackageReference Include="Microsoft.EntityFrameworkCore.SqlServer" />
    <PackageReference Include="Microsoft.EntityFrameworkCore.Design" />
    <PackageReference Include="Swashbuckle.AspNetCore" />
    <PackageReference Include="Microsoft.AspNetCore.Authentication.JwtBearer" />
  </ItemGroup>
</Project>
'@

  "Backend\appsettings.json" = @'
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=(localdb)\\MSSQLLocalDB;Database=MhlangaFin;Trusted_Connection=True;"
  },
  "Jwt": {
    "Key": "ChangeThisToASecureLongSecretForProduction",
    "Issuer": "MhlangaFin",
    "Audience": "MhlangaFinClients",
    "ExpiresMinutes": 60
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information"
    }
  }
}
'@

  "Backend\Program.cs" = @'
using System.Text;
using Backend.Data;
using Backend.Repositories;
using Backend.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;

var builder = WebApplication.CreateBuilder(args);

// Configuration
var configuration = builder.Configuration;

// Add DbContext - SQL Server
var conn = configuration.GetConnectionString("DefaultConnection")
           ?? throw new InvalidOperationException("Connection string \'DefaultConnection\' not found.");
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlServer(conn));

// Repositories
builder.Services.AddScoped<IUserRepository, UserRepository>();
builder.Services.AddScoped<IAccountRepository, AccountRepository>();
builder.Services.AddScoped<ITransactionRepository, TransactionRepository>();

// Services
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IAccountService, AccountService>();
builder.Services.AddScoped<ITransactionService, TransactionService>();

// JWT Authentication
var jwtKey = configuration["Jwt:Key"] ?? throw new InvalidOperationException("Jwt:Key missing");
var keyBytes = Encoding.UTF8.GetBytes(jwtKey);
builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.RequireHttpsMetadata = false;
    options.SaveToken = true;
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = configuration["Jwt:Issuer"],
        ValidAudience = configuration["Jwt:Audience"],
        IssuerSigningKey = new SymmetricSecurityKey(keyBytes)
    };
});

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    // Add JWT support in Swagger
    c.AddSecurityDefinition("Bearer", new Microsoft.OpenApi.Models.OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = Microsoft.OpenApi.Models.SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        In = Microsoft.OpenApi.Models.ParameterLocation.Header,
        Description = "JWT Authorization header using the Bearer scheme."
    });
    c.AddSecurityRequirement(new Microsoft.OpenApi.Models.OpenApiSecurityRequirement
    {
        {
            new Microsoft.OpenApi.Models.OpenApiSecurityScheme
            {
                Reference = new Microsoft.OpenApi.Models.OpenApiReference
                {
                    Type = Microsoft.OpenApi.Models.ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

var app = builder.Build();

// Ensure DB created in dev (use migrations for production)
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    db.Database.EnsureCreated();
}

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();
'@

  "Backend\Data\AppDbContext.cs" = @'
using Microsoft.EntityFrameworkCore;
using Backend.Models.Entities;

namespace Backend.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options)
        : base(options) { }

    public DbSet<User> Users => Set<User>();
    public DbSet<Account> Accounts => Set<Account>();
    public DbSet<Transaction> Transactions => Set<Transaction>();
    public DbSet<AuditLog> AuditLogs => Set<AuditLog>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<User>()
            .HasMany(u => u.Accounts)
            .WithOne(a => a.User!)
            .HasForeignKey(a => a.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<Account>()
            .HasMany(a => a.SentTransactions)
            .WithOne(t => t.FromAccount!)
            .HasForeignKey(t => t.FromAccountId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<Account>()
            .HasMany(a => a.ReceivedTransactions)
            .WithOne(t => t.ToAccount!)
            .HasForeignKey(t => t.ToAccountId)
            .OnDelete(DeleteBehavior.Restrict);

        base.OnModelCreating(modelBuilder);
    }
}
'@

  "Backend\Models\Entities\User.cs" = @'
using System.ComponentModel.DataAnnotations;

namespace Backend.Models.Entities;

public class User
{
    [Key]
    public int Id { get; set; }
    [Required]
    public string FullName { get; set; } = null!;
    [Required]
    public string Email { get; set; } = null!;
    [Required]
    public string PasswordHash { get; set; } = null!; // replace with secure hashing in prod
    [Required]
    public string Role { get; set; } = "User";

    public ICollection<Account>? Accounts { get; set; }
    public ICollection<AuditLog>? AuditLogs { get; set; }
}
'@

  "Backend\Models\Entities\Account.cs" = @'
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Backend.Models.Entities;

public class Account
{
    [Key]
    public int Id { get; set; }
    [Required]
    public string AccountNumber { get; set; } = null!;
    [Column(TypeName = "decimal(18,2)")]
    public decimal Balance { get; set; }
    public int UserId { get; set; }
    public string Status { get; set; } = "Active";

    public User? User { get; set; }

    public ICollection<Transaction>? SentTransactions { get; set; }
    public ICollection<Transaction>? ReceivedTransactions { get; set; }
}
'@

  "Backend\Models\Entities\Transaction.cs" = @'
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Backend.Models.Entities;

public class Transaction
{
    [Key]
    public int Id { get; set; }

    public int FromAccountId { get; set; }
    public int ToAccountId { get; set; }

    [Column(TypeName = "decimal(18,2)")]
    public decimal Amount { get; set; }

    public string Type { get; set; } = "Transfer";
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;

    public Account? FromAccount { get; set; }
    public Account? ToAccount { get; set; }
}
'@

  "Backend\Models\Entities\AuditLog.cs" = @'
using System.ComponentModel.DataAnnotations;

namespace Backend.Models.Entities;

public class AuditLog
{
    [Key]
    public int Id { get; set; }
    public int? UserId { get; set; }
    public string Action { get; set; } = null!;
    public string? Details { get; set; }
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
}
'@

  "Backend\DTOs\Auth\LoginRequest.cs" = @'
namespace Backend.DTOs.Auth;

public class LoginRequest
{
    public string Email { get; set; } = null!;
    public string Password { get; set; } = null!;
}
'@

  "Backend\DTOs\Auth\LoginResponse.cs" = @'
namespace Backend.DTOs.Auth;

public class LoginResponse
{
    public string Token { get; set; } = null!;
    public DateTime ExpiresAt { get; set; }
}
'@

  "Backend\DTOs\Accounts\AccountCreateDto.cs" = @'
namespace Backend.DTOs.Accounts;

public class AccountCreateDto
{
    public int UserId { get; set; }
    public string AccountNumber { get; set; } = null!;
    public decimal InitialBalance { get; set; }
}
'@

  "Backend\DTOs\Accounts\AccountDto.cs" = @'
namespace Backend.DTOs.Accounts;

public class AccountDto
{
    public int Id { get; set; }
    public string AccountNumber { get; set; } = null!;
    public decimal Balance { get; set; }
    public string Status { get; set; } = null!;
}
'@

  "Backend\DTOs\Transactions\TransferRequest.cs" = @'
namespace Backend.DTOs.Transactions;

public class TransferRequest
{
    public int FromAccountId { get; set; }
    public int ToAccountId { get; set; }
    public decimal Amount { get; set; }
}
'@

  "Backend\DTOs\Transactions\TransferResponse.cs" = @'
namespace Backend.DTOs.Transactions;

public class TransferResponse
{
    public int TransactionId { get; set; }
    public string Status { get; set; } = null!;
    public string Message { get; set; } = null!;
}
'@

  "Backend\Repositories\IUserRepository.cs" = @'
using Backend.Models.Entities;

namespace Backend.Repositories;

public interface IUserRepository
{
    Task<User?> GetByEmailAsync(string email);
    Task<User?> GetByIdAsync(int id);
    Task AddAsync(User user);
    Task SaveChangesAsync();
}
'@

  "Backend\Repositories\UserRepository.cs" = @'
using Backend.Data;
using Backend.Models.Entities;
using Microsoft.EntityFrameworkCore;

namespace Backend.Repositories;

public class UserRepository : IUserRepository
{
    private readonly AppDbContext _db;
    public UserRepository(AppDbContext db) => _db = db;

    public async Task<User?> GetByEmailAsync(string email) =>
        await _db.Users.FirstOrDefaultAsync(u => u.Email == email);

    public async Task<User?> GetByIdAsync(int id) =>
        await _db.Users.FindAsync(id);

    public async Task AddAsync(User user)
    {
        await _db.Users.AddAsync(user);
    }

    public async Task SaveChangesAsync() => await _db.SaveChangesAsync();
}
'@

  "Backend\Repositories\IAccountRepository.cs" = @'
using Backend.Models.Entities;

namespace Backend.Repositories;

public interface IAccountRepository
{
    Task<Account?> GetByIdAsync(int id);
    Task AddAsync(Account account);
    Task SaveChangesAsync();
}
'@

  "Backend\Repositories\AccountRepository.cs" = @'
using Backend.Data;
using Backend.Models.Entities;
using Microsoft.EntityFrameworkCore;

namespace Backend.Repositories;

public class AccountRepository : IAccountRepository
{
    private readonly AppDbContext _db;
    public AccountRepository(AppDbContext db) => _db = db;

    public async Task<Account?> GetByIdAsync(int id) =>
        await _db.Accounts.Include(a => a.User).FirstOrDefaultAsync(a => a.Id == id);

    public async Task AddAsync(Account account) => await _db.Accounts.AddAsync(account);

    public async Task SaveChangesAsync() => await _db.SaveChangesAsync();
}
'@

  "Backend\Repositories\ITransactionRepository.cs" = @'
using Backend.Models.Entities;

namespace Backend.Repositories;

public interface ITransactionRepository
{
    Task AddAsync(Transaction tx);
    Task SaveChangesAsync();
}
'@

  "Backend\Repositories\TransactionRepository.cs" = @'
using Backend.Data;
using Backend.Models.Entities;

namespace Backend.Repositories;

public class TransactionRepository : ITransactionRepository
{
    private readonly AppDbContext _db;
    public TransactionRepository(AppDbContext db) => _db = db;

    public async Task AddAsync(Transaction tx) => await _db.Transactions.AddAsync(tx);

    public async Task SaveChangesAsync() => await _db.SaveChangesAsync();
}
'@

  "Backend\Services\IAuthService.cs" = @'
using Backend.DTOs.Auth;

namespace Backend.Services;

public interface IAuthService
{
    Task<LoginResponse?> AuthenticateAsync(LoginRequest request);
}
'@

  "Backend\Services\AuthService.cs" = @'
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Backend.DTOs.Auth;
using Backend.Repositories;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;

namespace Backend.Services;

public class AuthService : IAuthService
{
    private readonly IUserRepository _users;
    private readonly IConfiguration _config;

    public AuthService(IUserRepository users, IConfiguration config)
    {
        _users = users;
        _config = config;
    }

    public async Task<LoginResponse?> AuthenticateAsync(LoginRequest request)
    {
        var user = await _users.GetByEmailAsync(request.Email);
        if (user is null) return null;

        // NOTE: replace with a proper password hash check in production
        if (user.PasswordHash != request.Password) return null;

        var key = Encoding.UTF8.GetBytes(_config["Jwt:Key"] ?? throw new InvalidOperationException("Jwt:Key missing"));
        var tokenHandler = new JwtSecurityTokenHandler();
        var tokenDescriptor = new SecurityTokenDescriptor
        {
            Subject = new ClaimsIdentity(new[]
            {
                new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
                new Claim(ClaimTypes.Email, user.Email),
                new Claim(ClaimTypes.Role, user.Role)
            }),
            Expires = DateTime.UtcNow.AddMinutes(double.Parse(_config["Jwt:ExpiresMinutes"] ?? "60")),
            SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(key), SecurityAlgorithms.HmacSha256Signature),
            Issuer = _config["Jwt:Issuer"],
            Audience = _config["Jwt:Audience"]
        };

        var token = tokenHandler.CreateToken(tokenDescriptor);
        return new LoginResponse
        {
            Token = tokenHandler.WriteToken(token),
            ExpiresAt = tokenDescriptor.Expires!.Value
        };
    }
}
'@

  "Backend\Services\IAccountService.cs" = @'
using Backend.DTOs.Accounts;

namespace Backend.Services;

public interface IAccountService
{
    Task<AccountDto?> GetByIdAsync(int id);
    Task<AccountDto> CreateAsync(AccountCreateDto dto);
}
'@

  "Backend\Services\AccountService.cs" = @'
using Backend.DTOs.Accounts;
using Backend.Models.Entities;
using Backend.Repositories;

namespace Backend.Services;

public class AccountService : IAccountService
{
    private readonly IAccountRepository _accounts;
    private readonly IUserRepository _users;

    public AccountService(IAccountRepository accounts, IUserRepository users)
    {
        _accounts = accounts;
        _users = users;
    }

    public async Task<AccountDto?> GetByIdAsync(int id)
    {
        var acc = await _accounts.GetByIdAsync(id);
        if (acc is null) return null;
        return new AccountDto
        {
            Id = acc.Id,
            AccountNumber = acc.AccountNumber,
            Balance = acc.Balance,
            Status = acc.Status
        };
    }

    public async Task<AccountDto> CreateAsync(AccountCreateDto dto)
    {
        var user = await _users.GetByIdAsync(dto.UserId) ?? throw new InvalidOperationException("User not found");
        var account = new Account
        {
            AccountNumber = dto.AccountNumber,
            Balance = dto.InitialBalance,
            UserId = user.Id,
            Status = "Active"
        };
        await _accounts.AddAsync(account);
        await _accounts.SaveChangesAsync();

        return new AccountDto
        {
            Id = account.Id,
            AccountNumber = account.AccountNumber,
            Balance = account.Balance,
            Status = account.Status
        };
    }
}
'@

  "Backend\Services\ITransactionService.cs" = @'
using Backend.DTOs.Transactions;

namespace Backend.Services;

public interface ITransactionService
{
    Task<TransferResponse> TransferAsync(TransferRequest request);
}
'@

  "Backend\Services\TransactionService.cs" = @'
using Backend.DTOs.Transactions;
using Backend.Models.Entities;
using Backend.Repositories;
using Backend.Data;
using Microsoft.EntityFrameworkCore;

namespace Backend.Services;

public class TransactionService : ITransactionService
{
    private readonly IAccountRepository _accounts;
    private readonly ITransactionRepository _txRepo;
    private readonly AppDbContext _db;

    public TransactionService(IAccountRepository accounts, ITransactionRepository txRepo, AppDbContext db)
    {
        _accounts = accounts;
        _txRepo = txRepo;
        _db = db;
    }

    public async Task<TransferResponse> TransferAsync(TransferRequest request)
    {
        if (request.Amount <= 0)
            return new TransferResponse { Status = "Failed", Message = "Invalid amount" };

        // Use a DB transaction to ensure atomicity
        await using var tx = await _db.Database.BeginTransactionAsync();
        try
        {
            var from = await _db.Accounts.FirstOrDefaultAsync(a => a.Id == request.FromAccountId);
            var to = await _db.Accounts.FirstOrDefaultAsync(a => a.Id == request.ToAccountId);

            if (from is null || to is null)
                return new TransferResponse { Status = "Failed", Message = "Account not found" };

            if (from.Balance < request.Amount)
                return new TransferResponse { Status = "Failed", Message = "Insufficient funds" };

            from.Balance -= request.Amount;
            to.Balance += request.Amount;

            var txEntity = new Transaction
            {
                FromAccountId = from.Id,
                ToAccountId = to.Id,
                Amount = request.Amount,
                Type = "Transfer",
                Timestamp = DateTime.UtcNow
            };

            await _txRepo.AddAsync(txEntity);
            await _db.SaveChangesAsync();

            await tx.CommitAsync();

            return new TransferResponse
            {
                TransactionId = txEntity.Id,
                Status = "Success",
                Message = "Transfer completed successfully"
            };
        }
        catch
        {
            await tx.RollbackAsync();
            throw;
        }
    }
}
'@

  "Backend\Controllers\AuthController.cs" = @'
using Microsoft.AspNetCore.Mvc;
using Backend.Services;
using Backend.DTOs.Auth;

namespace Backend.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _auth;
    public AuthController(IAuthService auth) => _auth = auth;

    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginRequest request)
    {
        var result = await _auth.AuthenticateAsync(request);
        if (result is null) return Unauthorized();
        return Ok(result);
    }
}
'@

  "Backend\Controllers\AccountsController.cs" = @'
using Microsoft.AspNetCore.Mvc;
using Backend.Services;
using Backend.DTOs.Accounts;
using Microsoft.AspNetCore.Authorization;

namespace Backend.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AccountsController : ControllerBase
{
    private readonly IAccountService _accounts;
    public AccountsController(IAccountService accounts) => _accounts = accounts;

    [HttpGet("{id}")]
    [Authorize]
    public async Task<IActionResult> Get(int id)
    {
        var acc = await _accounts.GetByIdAsync(id);
        if (acc is null) return NotFound();
        return Ok(acc);
    }

    [HttpPost]
    [Authorize(Roles = "Admin,User")]
    public async Task<IActionResult> Create([FromBody] AccountCreateDto dto)
    {
        var created = await _accounts.CreateAsync(dto);
        return CreatedAtAction(nameof(Get), new { id = created.Id }, created);
    }
}
'@

  "Backend\Controllers\TransactionsController.cs" = @'
using Microsoft.AspNetCore.Mvc;
using Backend.Services;
using Backend.DTOs.Transactions;
using Microsoft.AspNetCore.Authorization;

namespace Backend.Controllers;

[ApiController]
[Route("api/[controller]")]
public class TransactionsController : ControllerBase
{
    private readonly ITransactionService _tx;
    public TransactionsController(ITransactionService tx) => _tx = tx;

    [HttpPost("transfer")]
    [Authorize]
    public async Task<IActionResult> Transfer([FromBody] TransferRequest request)
    {
        var result = await _tx.TransferAsync(request);
        if (result.Status == "Success") return Ok(result);
        return BadRequest(result);
    }
}
'@

  ".gitignore" = @'
# Ignore Visual Studio state and build artifacts
.vs/
bin/
obj/
# user secrets, local settings
appsettings.*.json
'@
}

# create files
foreach ($path in $files.Keys) {
  $dir = Split-Path $path -Parent
  if (-not (Test-Path $dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
  }
  $content = $files[$path]
  $content | Out-File -FilePath $path -Encoding utf8
  Write-Host "Created $path"
}

# stage and commit
git add .gitignore
git add Backend
git commit -m "feat(backend): scaffold DbContext, entities, repositories, services, controllers; add JWT auth and Swagger"
git push origin main
Write-Host "Scaffold complete. Run 'cd Backend; dotnet restore; dotnet build; dotnet run' to test."