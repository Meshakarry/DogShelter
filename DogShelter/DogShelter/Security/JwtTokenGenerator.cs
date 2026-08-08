using DogShelter.Model;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace DogShelter.Security
{
    public interface IJwtTokenGenerator
    {
        (string Token, DateTime ExpiresUtc) GenerateToken(Korisnik user);
    }

    public class JwtTokenGenerator : IJwtTokenGenerator
    {
        private readonly IConfiguration _configuration;

        public JwtTokenGenerator(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        public (string Token, DateTime ExpiresUtc) GenerateToken(Korisnik user)
        {
            var jwtSettings = _configuration.GetSection("JWTSettings");
            var key = jwtSettings["Key"] ?? string.Empty;
            var issuer = jwtSettings["Issuer"] ?? string.Empty;
            var audience = jwtSettings["Audience"] ?? string.Empty;
            var durationMinutes = int.TryParse(jwtSettings["DurationInMinutes"], out var m) ? m : 60;

            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.NameIdentifier, user.KorisnikId.ToString()),
                new Claim(ClaimTypes.Name, user.KorisnickoIme),
                new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
            };

            if (user.KorisnikUloge != null)
            {
                foreach (var role in user.KorisnikUloge)
                {
                    if (role?.Uloga?.Naziv != null)
                    {
                        claims.Add(new Claim(ClaimTypes.Role, role.Uloga.Naziv));
                    }
                }
            }

            var securityKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(key));
            var credentials = new SigningCredentials(securityKey, SecurityAlgorithms.HmacSha256);

            var expires = DateTime.UtcNow.AddMinutes(durationMinutes);

            var tokenDescriptor = new JwtSecurityToken(
                issuer: issuer,
                audience: audience,
                claims: claims,
                expires: expires,
                signingCredentials: credentials
            );

            var token = new JwtSecurityTokenHandler().WriteToken(tokenDescriptor);
            return (token, expires);
        }
    }
}
