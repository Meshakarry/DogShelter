using DogShelter.Model;
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;

namespace DogShelter.Security
{
    public class CanModifyAktivnostVolonteraRequirement : IAuthorizationRequirement { }

    public class CanModifyAktivnostVolonteraHandler : AuthorizationHandler<CanModifyAktivnostVolonteraRequirement, AktivnostVolontera>
    {
        protected override Task HandleRequirementAsync(
            AuthorizationHandlerContext context,
            CanModifyAktivnostVolonteraRequirement requirement,
            AktivnostVolontera resource)
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
