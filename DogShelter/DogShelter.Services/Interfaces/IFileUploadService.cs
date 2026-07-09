using Microsoft.AspNetCore.Http;

namespace DogShelter.Services.Interfaces;

public interface IFileUploadService
{
    /// <summary>
    /// Validates MIME type + magic bytes, saves to disk, returns relative URL path.
    /// Throws ValidationException if the file is invalid.
    /// </summary>
    Task<string> SaveImageAsync(IFormFile file, string subfolder);

    /// <summary>
    /// Deletes the file at the given relative URL path from wwwroot. No-op if not found.
    /// </summary>
    void DeleteImage(string? relativePath);
}
