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

    /// <summary>
    /// Validates MIME type + magic bytes, saves to a private folder outside wwwroot (not directly
    /// web-servable), returns a relative path of the form "{subfolder}/{fileName}".
    /// Throws ValidationException if the file is invalid.
    /// </summary>
    Task<string> SavePrivateImageAsync(IFormFile file, string subfolder);

    /// <summary>
    /// Deletes the file at the given relative path from the private folder. No-op if not found.
    /// </summary>
    void DeletePrivateImage(string? relativePath);

    /// <summary>
    /// Resolves a relative private-folder path to its absolute path on disk, or null if it doesn't exist.
    /// </summary>
    string? GetPrivateFilePath(string? relativePath);

    /// <summary>
    /// Returns the image MIME type for a file based on its extension.
    /// </summary>
    string GetContentType(string relativePath);
}
