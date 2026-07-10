using DogShelter.Model.Requests;
using DogShelter.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;

namespace DogShelter.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [AllowAnonymous]
    [EnableRateLimiting("PasswordResetPolicy")]
    public class PasswordResetController : ControllerBase
    {
        private readonly IPasswordResetService _service;

        public PasswordResetController(IPasswordResetService service)
        {
            _service = service;
        }

        [HttpPost("request")]
        public async Task<IActionResult> RequestReset([FromBody] RequestPasswordResetRequest request)
        {
            await _service.RequestResetAsync(request);
            return Ok(new { message = "Ako email postoji u sistemu, poslan je kod za resetiranje lozinke." });
        }

        [HttpPost("reset")]
        public async Task<IActionResult> Reset([FromBody] ResetPasswordRequest request)
        {
            await _service.ResetPasswordAsync(request);
            return Ok(new { message = "Lozinka je uspješno promijenjena." });
        }
    }
}
