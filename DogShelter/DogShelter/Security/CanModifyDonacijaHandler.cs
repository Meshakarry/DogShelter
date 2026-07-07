using DogShelter.Model;
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;

namespace DogShelter.Security
{
    public class CanModifyDonacijaRequirement : IAuthorizationRequirement { }

    public class CanModifyDonacijaHandler : AuthorizationHandler<CanModifyDonacijaRequirement, Donacija>
    {
        protected override Task HandleRequirementAsync(
            AuthorizationHandlerContext context,
            CanModifyDonacijaRequirement requirement,
            Donacija resource)
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
