using DogShelter.Model.Requests;

namespace DogShelter.Services.Interfaces;

public interface IPasswordResetService
{
    Task RequestResetAsync(RequestPasswordResetRequest request);
    Task ResetPasswordAsync(ResetPasswordRequest request);
}
