using DogShelter.Model;
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;

namespace DogShelter.Security
{
    public class CanAccessKorisnikRequirement : IAuthorizationRequirement { }

    public class CanAccessKorisnikHandler : AuthorizationHandler<CanAccessKorisnikRequirement, Korisnik>
    {
        protected override Task HandleRequirementAsync(
            AuthorizationHandlerContext context,
            CanAccessKorisnikRequirement requirement,
            Korisnik resource)
        {
            if (resource == null)
                return Task.CompletedTask;

            if (context.User.IsInRole("Admin"))
            {
                context.Succeed(requirement);
                return Task.CompletedTask;
            }

            var userIdClaim = context.User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (int.TryParse(userIdClaim, out var userId) && resource.KorisnikId == userId)
                context.Succeed(requirement);

            return Task.CompletedTask;
        }
    }
}
