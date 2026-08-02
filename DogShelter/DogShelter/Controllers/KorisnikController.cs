using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using DogShelter.Model;
using DogShelter.Model.Requests;
using DogShelter.Services.Exceptions;
using DogShelter.Services.Interfaces;
using DogShelter.Security;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;

namespace DogShelter.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class KorisnikController : BaseCRUDController<Korisnik, KorisnikSearchRequest, KorisnikInsertRequest, KorisnikUpdateRequest>
    {
        private readonly IKorisnikService _service;
        private readonly IJwtTokenGenerator _tokenGenerator;
        private readonly ITokenRevocationService _tokenRevocationService;
        private readonly IAuthorizationService _authorizationService;
        public KorisnikController(
            IKorisnikService service,
            IJwtTokenGenerator tokenGenerator,
            ITokenRevocationService tokenRevocationService,
            IAuthorizationService authorizationService) : base(service)
        {
            _service = service;
            _tokenGenerator = tokenGenerator;
            _tokenRevocationService = tokenRevocationService;
            _authorizationService = authorizationService;
        }

        [HttpGet]
        [Authorize(Roles = RoleNames.Admin)]
        public override async Task<PagedResult<Korisnik>> Get([FromQuery] KorisnikSearchRequest search)
        {
            return await _service.Get(search);
        }

        [HttpGet("{ID:int}")]
        [Authorize]
        public override async Task<Korisnik> GetById(int ID)
        {
            var user = await _service.GetById(ID);
            if (user == null || user.KorisnikId == 0)
            {
                throw new NotFoundException("Korisnik nije pronađen.");
            }

            var authResult = await _authorizationService.AuthorizeAsync(User, user, "CanAccessKorisnik");
            if (!authResult.Succeeded)
            {
                throw new ForbiddenException("Nemate dozvolu za pristup ovoj stranici.");
            }

            return user;
        }

        [HttpPost("Authenticate")]
        [AllowAnonymous]
        public async Task<ActionResult<Korisnik>> Authenticate(AuthenticationRequest request)
        {
            var user = await _service.Authenticate(request);
            return user == null ? Unauthorized() : user;
        }

        [HttpPost("Register")]
        [AllowAnonymous]
        public async Task<Korisnik> Register(RegisterRequest request)
        {
            return await _service.Register(request);
        }

        public class TokenResponse
        {
            public string Token { get; set; } = string.Empty;
            public DateTime ExpiresUtc { get; set; }
            public Korisnik Korisnik { get; set; } = null!;
        }

        [HttpPut("profile")]
        [Authorize]
        public async Task<ActionResult<Korisnik>> UpdateMyProfile([FromBody] KorisnikProfileUpdateRequest request)
        {
            var idClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(idClaim) || !int.TryParse(idClaim, out var userId))
                throw new ForbiddenException("Nemate dozvolu za pristup ovoj stranici.");

            return await _service.UpdateMyProfile(userId, request);
        }

        [HttpPut("password")]
        [Authorize]
        public async Task<IActionResult> ChangeMyPassword([FromBody] KorisnikChangePasswordRequest request)
        {
            var idClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(idClaim) || !int.TryParse(idClaim, out var userId))
                throw new ForbiddenException("Nemate dozvolu za pristup ovoj stranici.");

            await _service.ChangeMyPassword(userId, request);
            return Ok(new { message = "Lozinka je uspješno promijenjena." });
        }

        [HttpPost("avatar")]
        [Authorize]
        [Consumes("multipart/form-data")]
        public async Task<ActionResult<Korisnik>> UpdateMyAvatar(IFormFile slika)
        {
            var idClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(idClaim) || !int.TryParse(idClaim, out var userId))
                throw new ForbiddenException("Nemate dozvolu za pristup ovoj stranici.");

            return await _service.UpdateMyAvatar(userId, slika);
        }

        [HttpGet("{id:int}/avatar")]
        [Authorize]
        public async Task<IActionResult> GetAvatar(int id)
        {
            var idClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(idClaim) || !int.TryParse(idClaim, out var callerId))
                throw new ForbiddenException("Nemate dozvolu za pristup ovoj stranici.");

            var (fullPath, contentType) = await _service.GetAvatarFileAsync(id, callerId, User.IsInRole(RoleNames.Admin));
            return PhysicalFile(fullPath, contentType);
        }

        [HttpPost("Token")]
        [AllowAnonymous]
        [EnableRateLimiting("LoginPolicy")]
        public async Task<ActionResult<TokenResponse>> Token([FromBody] AuthenticationRequest request)
        {
            var user = await _service.Authenticate(request);
            if (user == null)
            {
                return Unauthorized(new { message = "Neispravno korisničko ime ili lozinka." });
            }

            var token = _tokenGenerator.GenerateToken(user);
            var response = new TokenResponse
            {
                Token = token,
                ExpiresUtc = _tokenGenerator.GetExpiration(),
                Korisnik = user
            };
            return Ok(response);
        }

        [HttpPost("logout")]
        [Authorize]
        public async Task<IActionResult> Logout()
        {
            var idClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var jti = User.FindFirstValue(JwtRegisteredClaimNames.Jti);
            var expClaim = User.FindFirstValue(JwtRegisteredClaimNames.Exp);

            if (string.IsNullOrEmpty(idClaim) || !int.TryParse(idClaim, out var userId) ||
                string.IsNullOrEmpty(jti) || string.IsNullOrEmpty(expClaim) || !long.TryParse(expClaim, out var expUnix))
            {
                throw new ForbiddenException("Nemate dozvolu za pristup ovoj stranici.");
            }

            var expiresUtc = DateTimeOffset.FromUnixTimeSeconds(expUnix).UtcDateTime;
            await _tokenRevocationService.RevokeAsync(jti, userId, expiresUtc);

            return Ok(new { message = "Uspješno ste se odjavili." });
        }
    }
}
