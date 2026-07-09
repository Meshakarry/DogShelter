using DogShelter.Services.Exceptions;
using DogShelter.Services.Interfaces;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;

namespace DogShelter.Services.Services;

public class FileUploadService : IFileUploadService
{
    private readonly IWebHostEnvironment _env;

    private static readonly string[] AllowedExtensions = [".jpg", ".jpeg", ".png", ".webp"];

    // Magic byte signatures: (offset, bytes)
    private static readonly (int Offset, byte[] Signature, string Type)[] Signatures =
    [
        (0, [0xFF, 0xD8, 0xFF], "JPEG"),
        (0, [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A], "PNG"),
        (0, [0x52, 0x49, 0x46, 0x46], "WEBP_RIFF"), // followed by WebP at offset 8
    ];

    public FileUploadService(IWebHostEnvironment env)
    {
        _env = env;
    }

    public async Task<string> SaveImageAsync(IFormFile file, string subfolder)
    {
        if (file == null || file.Length == 0)
            throw new ValidationException("Slika nije priložena ili je prazna.");

        var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
        if (!AllowedExtensions.Contains(ext))
            throw new ValidationException($"Dozvoljeni formati: {string.Join(", ", AllowedExtensions)}.");

        await ValidateMagicBytesAsync(file);

        var folder = Path.Combine(_env.WebRootPath, "images", subfolder);
        Directory.CreateDirectory(folder);

        var fileName = $"{Guid.NewGuid()}{ext}";
        var fullPath = Path.Combine(folder, fileName);

        await using var stream = new FileStream(fullPath, FileMode.Create);
        await file.CopyToAsync(stream);

        return $"/images/{subfolder}/{fileName}";
    }

    public void DeleteImage(string? relativePath)
    {
        if (string.IsNullOrWhiteSpace(relativePath)) return;

        // relativePath is like /images/psi/abc.jpg
        var fullPath = Path.Combine(_env.WebRootPath, relativePath.TrimStart('/').Replace('/', Path.DirectorySeparatorChar));
        if (File.Exists(fullPath))
            File.Delete(fullPath);
    }

    private static async Task ValidateMagicBytesAsync(IFormFile file)
    {
        var header = new byte[12];
        await using var stream = file.OpenReadStream();
        var read = await stream.ReadAsync(header.AsMemory(0, header.Length));

        if (read < 3)
            throw new ValidationException("Datoteka je previše mala da bi bila validna slika.");

        // JPEG: FF D8 FF
        if (header[0] == 0xFF && header[1] == 0xD8 && header[2] == 0xFF)
            return;

        // PNG: 89 50 4E 47 0D 0A 1A 0A
        if (read >= 8 &&
            header[0] == 0x89 && header[1] == 0x50 && header[2] == 0x4E && header[3] == 0x47 &&
            header[4] == 0x0D && header[5] == 0x0A && header[6] == 0x1A && header[7] == 0x0A)
            return;

        // WebP: RIFF????WEBP
        if (read >= 12 &&
            header[0] == 0x52 && header[1] == 0x49 && header[2] == 0x46 && header[3] == 0x46 &&
            header[8] == 0x57 && header[9] == 0x45 && header[10] == 0x42 && header[11] == 0x50)
            return;

        throw new ValidationException("Sadržaj datoteke ne odgovara dozvoljenoj vrsti slike (JPEG, PNG, WebP).");
    }
}
