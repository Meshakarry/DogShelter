using DogShelter.Model;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace DogShelter.Security
{
    public interface IJwtTokenGenerator
    {
        string GenerateToken(Korisnik user);
        DateTime GetExpiration();
    }

    public class JwtTokenGenerator : IJwtTokenGenerator
    {
        private readonly IConfiguration _configuration;
        private DateTime _lastExpirationUtc;

        public JwtTokenGenerator(IConfiguration configuration)
        {
            _configuration = configuration;
            _lastExpirationUtc = DateTime.UtcNow;
        }

        public string GenerateToken(Korisnik user)
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
            _lastExpirationUtc = expires;

            var tokenDescriptor = new JwtSecurityToken(
                issuer: issuer,
                audience: audience,
                claims: claims,
                expires: expires,
                signingCredentials: credentials
            );

            return new JwtSecurityTokenHandler().WriteToken(tokenDescriptor);
        }

        public DateTime GetExpiration()
        {
            return _lastExpirationUtc;
        }
    }
}
