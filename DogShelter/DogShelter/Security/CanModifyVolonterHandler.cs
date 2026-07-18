using DogShelter.Model;
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;

namespace DogShelter.Security
{
    public class CanModifyVolonterRequirement : IAuthorizationRequirement { }

    public class CanModifyVolonterHandler : AuthorizationHandler<CanModifyVolonterRequirement, Volonter>
    {
        protected override Task HandleRequirementAsync(
            AuthorizationHandlerContext context,
            CanModifyVolonterRequirement requirement,
            Volonter resource)
        {
            if (resource == null)
                return Task.CompletedTask;

            if (context.User.IsInRole(RoleNames.Admin))
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
